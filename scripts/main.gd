# Escena principal: arma la armería en 3D, mueve clientes y dependientes y maneja la interfaz.
# El mundo es 3D (cámara isométrica ortográfica); letreros, burbujas e interfaz se dibujan en 2D encima.
extends Node2D

const StationScript := preload("res://scripts/station.gd")
const CustomerScript := preload("res://scripts/customer.gd")
const WorkerScript := preload("res://scripts/worker.gd")
const CounterScript := preload("res://scripts/counter.gd")
const IconScript := preload("res://scripts/icon_view.gd")

# Posiciones en el suelo (X a lo ancho, Z hacia la cámara)
const STATION_POS := [
	Vector3(-3.1, 0, -5.3), Vector3(0, 0, -5.3), Vector3(3.1, 0, -5.3),
	Vector3(-1.55, 0, -1.9), Vector3(1.55, 0, -1.9),
]
const BACK_WALL_Z := -7.3
const WORKER_Z := 0.55
const COUNTER_Z := 2.0
const SPOT_Z := 3.15
const VIEW_WIDTH := 9.8
const CAMERA_PITCH := -50.0
const BOTTOM_PANEL_H := 300.0
const WALL_SCREEN_Y := 385.0   # dónde queda la base de la pared del fondo en pantalla
const MAX_FLYING_COINS := 14

const CREAM := Color(1, 0.95, 0.85)
const GOLD := Color(1, 0.82, 0.3)
const LEATHER := Color(0.2, 0.13, 0.08, 0.97)

var stations: Array = []
var customers: Array = []
var workers: Array = []
var spots: Array = []
var selected := 0
var buy_mode := 1  # 1, 10 o 0 (= máximo)
var floor_bottom := 980.0  # borde superior del panel inferior (depende del alto de la pantalla)
var door := Vector3(0, 0, 9)
var _spawn_timer := 0.0
var _t := 0.0
var _world: Node3D
var _camera: Camera3D
var _torch_lights: Array = []
var _shown_coins := 0.0
var _flying := 0
var _coin_tex: ImageTexture
var _font: Font

# Interfaz
var _ui: Control
var _coin_icon: TextureRect
var _coins_label: Label
var _rate_label: Label
var _missions_box: VBoxContainer
var _stars_label: Label
var _icon: Control
var _name_label: Label
var _sub_label: Label
var _milestone_bar: ProgressBar
var _info_label: Label
var _buy_button: Button
var _mode_button: Button
var _upgrades_button: Button
var _portal_button: Button
var _bottom_panel: PanelContainer
var _dim: ColorRect
var _upgrades_panel: PanelContainer
var _upgrades_list: VBoxContainer
var _popup: PanelContainer
var _popup_label: Label


func _ready() -> void:
	randomize()
	_font = ThemeDB.fallback_font
	_coin_tex = Art.coin_texture(48)
	_shown_coins = GameState.coins
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_sync_workers()
	_sync_spots()
	GameState.upgrades_changed.connect(_on_upgrades_changed, CONNECT_DEFERRED)
	GameState.missions_changed.connect(_refresh_missions, CONNECT_DEFERRED)
	GameState.station_changed.connect(_on_station_changed)
	_select(0)
	_refresh_missions()
	if GameState.offline_reward > 0.0:
		_show_popup("Mientras no estabas, tu armería ganó %s monedas." % Fmt.num(GameState.offline_reward))
		GameState.claim_offline()


# --- Mundo 3D -----------------------------------------------------------------

func _build_world() -> void:
	_world = Node3D.new()
	add_child(_world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.09, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.68, 0.6)
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	_world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -28, 0)
	sun.light_energy = 0.5
	sun.light_color = Color(1, 0.95, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	_world.add_child(sun)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.size = VIEW_WIDTH
	_camera.rotation_degrees = Vector3(CAMERA_PITCH, 0, 0)
	_camera.far = 100.0
	_world.add_child(_camera)
	_camera.position = Vector3(0, 0, -1) + _camera.basis.z * 30.0
	_build_cave()
	Art3D.bake(_world)
	var counter := CounterScript.new()
	counter.position = Vector3(0, 0, COUNTER_Z)
	_world.add_child(counter)
	for i in GameState.station_count():
		var s := StationScript.new()
		s.idx = i
		s.position = STATION_POS[i]
		_world.add_child(s)
		stations.append(s)


func _build_cave() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# Suelo de tierra con piedras, camino claro hacia la entrada y algo de pasto
	Art3D.box(_world, Vector3(40, 0.2, 50), Vector3(0, -0.1, 6), Color(0.42, 0.31, 0.22))
	Art3D.box(_world, Vector3(3.2, 0.02, 14), Vector3(0, 0.0, 10), Color(0.52, 0.42, 0.3))
	Art3D.box(_world, Vector3(9, 0.02, 1.8), Vector3(0, 0.006, SPOT_Z + 0.1), Color(0.5, 0.36, 0.24))
	for k in 70:
		var p := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(-7, 16))
		var st := Art3D.cyl(_world, 0.0, rng.randf_range(0.06, 0.18), 0.05, p, Color(0.4, 0.3, 0.21).lerp(Color(0.55, 0.5, 0.45), rng.randf()), 6)
		st.scale.z = rng.randf_range(0.6, 1.0)
	for k in 26:
		var p := Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(9, 18))
		if absf(p.x) < 1.8:
			continue
		Art3D.cyl(_world, 0.0, 0.12, rng.randf_range(0.25, 0.45), p + Vector3(0, 0.15, 0), Color(0.4, 0.6, 0.28), 5)
	# Pared del fondo y rocas
	Art3D.box(_world, Vector3(14, 4.2, 1.2), Vector3(0, 2.1, BACK_WALL_Z - 0.6), Color(0.33, 0.27, 0.23))
	for k in 16:
		var x := -7.0 + k * 0.95
		Art3D.sphere(_world, rng.randf_range(0.45, 0.8), Vector3(x, rng.randf_range(0.0, 0.4), BACK_WALL_Z + 0.05), Color(0.38, 0.31, 0.26).darkened(rng.randf() * 0.2))
		Art3D.sphere(_world, rng.randf_range(0.5, 0.9), Vector3(x, 4.1, BACK_WALL_Z - 0.2), Color(0.28, 0.23, 0.2))
		var st := Art3D.cyl(_world, 0.12, 0.0, rng.randf_range(0.5, 1.0), Vector3(x + 0.4, 3.6, BACK_WALL_Z + 0.15), Color(0.3, 0.25, 0.21), 5)
		st.rotation.x = 0.1
	for side in [-1.0, 1.0]:
		for k in 5:
			Art3D.sphere(_world, rng.randf_range(0.5, 0.8), Vector3(side * rng.randf_range(4.9, 5.4), 0.2, BACK_WALL_Z + 0.8 + k * 1.3), Color(0.36, 0.3, 0.25))
	# Pinturas rupestres en la pared
	for px in [-3.4, 3.4]:
		var ochre := Color(0.78, 0.42, 0.2)
		var z := BACK_WALL_Z + 0.02
		Art3D.box(_world, Vector3(0.7, 0.3, 0.02), Vector3(px, 2.6, z), ochre)
		Art3D.box(_world, Vector3(0.22, 0.2, 0.02), Vector3(px + 0.42, 2.78, z), ochre)
		for lx in [-0.25, -0.1, 0.12, 0.27]:
			Art3D.box(_world, Vector3(0.05, 0.28, 0.02), Vector3(px + lx, 2.35, z), ochre)
	# Antorchas con luz que titila
	for tx in [-1.55, 1.55]:
		var base := Vector3(tx, 2.0, BACK_WALL_Z + 0.25)
		Art3D.cyl(_world, 0.06, 0.08, 0.7, base, Color(0.35, 0.22, 0.12), 6)
		Art3D.sphere(_world, 0.17, base + Vector3(0, 0.48, 0), Color(1, 0.5, 0.12), 1.6)
		Art3D.sphere(_world, 0.09, base + Vector3(0, 0.58, 0.05), Color(1, 0.85, 0.45), 2.0)
		var light := OmniLight3D.new()
		light.position = base + Vector3(0, 0.6, 0.6)
		light.light_color = Color(1, 0.6, 0.25)
		light.light_energy = 1.0
		light.omni_range = 5.5
		_world.add_child(light)
		_torch_lights.append(light)


# Punto del suelo que se ve en una posición de la pantalla.
func _ground_at(screen: Vector2) -> Vector3:
	var o := _camera.project_ray_origin(screen)
	var n := _camera.project_ray_normal(screen)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(o, n)
	return hit if hit != null else Vector3.ZERO


func _screen(p: Vector3) -> Vector2:
	return _camera.unproject_position(p)


# --- Dibujo 2D sobre el 3D: letreros, barras, burbujas ------------------------

func _draw() -> void:
	var I := Transform2D.IDENTITY
	for s in stations:
		var i: int = s.idx
		var data := GameState.station(i)
		var unlocked := GameState.is_unlocked(i)
		var known := unlocked or GameState.can_unlock(i)
		var sign_at := _screen(s.position + Vector3(0, 2.75, -0.85)) if unlocked else _screen(s.position + Vector3(0, 2.3, 0))
		_draw_sign(sign_at, data["nombre"] if known else "???", Color(data["color"]) if unlocked else Color(0.45, 0.4, 0.35), GameState.levels[i] if unlocked else -1)
		var front := _screen(s.position + Vector3(0, 0.25, 0.55))
		if unlocked:
			var n: int = s.slots.size()
			var bar_h := minf(8.0, 26.0 / maxf(n, 1))
			for k in n:
				var r := Rect2(front + Vector2(-80, -14 + k * (bar_h + 2)), Vector2(110, bar_h))
				Art.rrect(self, I, r, bar_h / 2, Color(0, 0, 0, 0.45))
				if s.slots[k] >= 0.0:
					Art.rrect(self, I, Rect2(r.position, Vector2(maxf(bar_h, 110 * s.slots[k]), bar_h)), bar_h / 2, Color(1, 0.8, 0.25))
			if s.stock > 0:
				var b := Rect2(front + Vector2(38, -16), Vector2(48, 26))
				Art.rrect(self, I, b, 10, Color(0, 0, 0, 0.45))
				draw_string(_font, b.position + Vector2(0, 19), "x%d" % s.stock, HORIZONTAL_ALIGNMENT_CENTER, 48, 18, Color.WHITE)
		elif GameState.can_unlock(i):
			var cost := GameState.unlock_cost(i)
			var ok := GameState.coins >= cost
			var pulse := 1.0 + (0.06 * sin(_t * 6.0) if ok else 0.0)
			var tag := Rect2(front + Vector2(-70 * pulse, -14), Vector2(140 * pulse, 30))
			Art.rrect(self, I, Rect2(tag.position + Vector2(0, 3), tag.size), 12, Color(0, 0, 0, 0.35))
			Art.rrect(self, I, tag, 12, Color(0.3, 0.65, 0.25) if ok else Color(0.4, 0.3, 0.25))
			draw_string_outline(_font, front + Vector2(-70, 8), Fmt.num(cost), HORIZONTAL_ALIGNMENT_CENTER, 140, 20, 4, Art.INK)
			draw_string(_font, front + Vector2(-70, 8), Fmt.num(cost), HORIZONTAL_ALIGNMENT_CENTER, 140, 20, Color.WHITE)
	for c in customers:
		var head := _screen(c.position + Vector3(0, 2.45, 0))
		if c.waiting():
			var bob := sin(_t * 2.5 + c.spot) * 2.0
			var bubble := Rect2(head + Vector2(-38, -48 + bob), Vector2(76, 44))
			Art.rrect(self, I, Rect2(bubble.position + Vector2(0, 3), bubble.size), 14, Color(0, 0, 0, 0.2))
			Art.rrect(self, I, bubble, 14, Color(1, 0.98, 0.93))
			Art.poly(self, I, PackedVector2Array([head + Vector2(-6, -5 + bob), head + Vector2(6, -5 + bob), head + Vector2(0, 4 + bob)]), Color(1, 0.98, 0.93))
			Art.weapon(self, GameState.station(c.station_idx)["id"], Transform2D(0, Vector2(0.6, 0.6), 0, head + Vector2(-14, -26 + bob)))
			draw_string(_font, head + Vector2(6, -18 + bob), "x%d" % c.remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.3, 0.18, 0.08))
		if c.heart > 0.0:
			Art.heart(self, I, head + Vector2(20, -20 - (1.0 - c.heart) * 40.0), 9, Color(0.95, 0.3, 0.35, minf(1.0, c.heart * 2.0)))


func _draw_sign(at: Vector2, title: String, accent: Color, level: int) -> void:
	var I := Transform2D.IDENTITY
	var r := Rect2(at + Vector2(-80, -15), Vector2(160, 28))
	Art.rrect(self, I, Rect2(r.position + Vector2(0, 3), r.size), 8, Color(0.25, 0.15, 0.08, 0.8))
	Art.rrect(self, I, r, 8, accent.darkened(0.15))
	Art.rrect(self, I, Rect2(r.position + Vector2(4, 2), Vector2(152, 10)), 6, Color(1, 1, 1, 0.12))
	draw_string_outline(_font, r.position + Vector2(0, 20), title, HORIZONTAL_ALIGNMENT_CENTER, 160, 17, 5, Color(0.2, 0.12, 0.05))
	draw_string(_font, r.position + Vector2(0, 20), title, HORIZONTAL_ALIGNMENT_CENTER, 160, 17, Color(1, 0.97, 0.9))
	if level > 0:
		var c := r.end + Vector2(12, -14)
		Art.circle(self, I, c + Vector2(0, 2), 16, Color(0.4, 0.25, 0.08))
		Art.circle(self, I, c, 15, Color(1, 0.8, 0.25))
		var lv := str(level)
		draw_string(_font, c + Vector2(-20, 6), lv, HORIZONTAL_ALIGNMENT_CENTER, 40, 17 if lv.length() < 3 else 14, Color(0.35, 0.2, 0.05))


# --- Bucle de juego -----------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	for k in _torch_lights.size():
		_torch_lights[k].light_energy = 0.7 + 0.15 * sin(_t * 9.0 + k * 2.0) + 0.1 * sin(_t * 23.0 + k)
	queue_redraw()
	_spawn_customers(delta)
	var demand := []
	demand.resize(stations.size())
	demand.fill(0)
	for c in customers:
		if c.waiting():
			demand[c.station_idx] += c.needs()
	for s in stations:
		s.tick(delta, demand[s.idx])
	_update_workers()
	_refresh_live(delta)


func _spawn_customers(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer < GameState.customer_interval():
		return
	var free_spot := spots.find(null)
	if free_spot == -1:
		return
	_spawn_timer = 0.0
	var unlocked := []
	for i in stations.size():
		if GameState.is_unlocked(i):
			unlocked.append(i)
	var c := CustomerScript.new()
	c.station_idx = unlocked.pick_random()
	c.remaining = 1 + (1 if randf() < 0.45 else 0) + (1 if randf() < 0.15 else 0)
	c.spot = free_spot
	c.position = door + Vector3(randf_range(-0.6, 0.6), 0, 0)
	c.target = _spot_position(free_spot)
	_world.add_child(c)
	customers.append(c)
	spots[free_spot] = c


func _spot_position(i: int) -> Vector3:
	var n := spots.size()
	var step := 6.4 / maxf(n - 1, 1)
	return Vector3(-3.2 + i * step, 0, SPOT_Z)


func _update_workers() -> void:
	for w in workers:
		match w.state:
			WorkerScript.State.FREE:
				_assign_task(w)
			WorkerScript.State.TO_STATION:
				if w.arrived():
					w.station.stock -= 1
					w.station.reserved -= 1
					w.carrying = true
					w.state = WorkerScript.State.TO_CUSTOMER
					w.target = Vector3(w.customer.position.x, 0, COUNTER_Z - 0.85)
			WorkerScript.State.TO_CUSTOMER:
				if w.arrived():
					_deliver(w)


func _assign_task(w) -> void:
	for c in customers:
		if not c.waiting() or c.needs() <= 0:
			continue
		var s = stations[c.station_idx]
		if s.free_stock() <= 0:
			continue
		s.reserved += 1
		c.incoming += 1
		w.station = s
		w.customer = c
		w.carrying_id = GameState.station(s.idx)["id"]
		w.state = WorkerScript.State.TO_STATION
		w.target = s.pickup_point()
		return


func _deliver(w) -> void:
	var c = w.customer
	var v := GameState.value(c.station_idx)
	GameState.add_coins(v)
	var head := _screen(c.position + Vector3(0, 2.2, 0))
	_fly_coin(head)
	_float_text("+" + Fmt.num(v), head + Vector2(-10, -90), GOLD)
	c.incoming -= 1
	c.remaining -= 1
	c.served()
	w.carrying = false
	w.customer = null
	w.station = null
	w.state = WorkerScript.State.FREE
	if c.remaining <= 0:
		spots[c.spot] = null
		customers.erase(c)
		c.leaving = true
		c.target = door + Vector3(randf_range(-0.6, 0.6), 0, 1.0)


func _sync_workers() -> void:
	while workers.size() < GameState.dependientes():
		var w := WorkerScript.new()
		var i := workers.size()
		w.look_seed = i
		w.home = Vector3(-2.7 + (i % 4) * 1.8, 0, WORKER_Z - (i / 4) * 0.5)
		w.position = w.home if i < 1 else Vector3(-6.0, 0, WORKER_Z)
		_world.add_child(w)
		workers.append(w)


func _sync_spots() -> void:
	while spots.size() < GameState.queue_size():
		spots.append(null)
	for c in customers:
		c.target = _spot_position(c.spot)


func _on_upgrades_changed() -> void:
	_sync_workers()
	_sync_spots()
	_refresh_upgrades()
	_refresh_panel()


func _on_station_changed(i: int) -> void:
	stations[i].celebrate()
	_refresh_panel()


# --- Toques -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p := get_global_mouse_position()
	for s in stations:
		var c := _screen(s.position + Vector3(0, 1.0, 0))
		if Rect2(c - Vector2(100, 110), Vector2(200, 180)).has_point(p):
			_select(s.idx)
			if GameState.is_unlocked(s.idx):
				s.boost(float(GameState.econ["impulso_toque"]))
			return


func _select(i: int) -> void:
	selected = i
	for s in stations:
		s.selected = s.idx == i
	_refresh_panel()


func _station_screen(i: int) -> Vector2:
	return _screen(stations[i].position + Vector3(0, 2.4, 0))


# --- Efectos ------------------------------------------------------------------

func _float_text(text: String, at: Vector2, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0))
	l.add_theme_constant_override("outline_size", 8)
	l.position = at
	l.z_index = 20
	l.scale = Vector2(0.5, 0.5)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", at.y - 50, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.tween_callback(l.queue_free)


# Moneda que vuela en arco desde el cliente hasta el contador.
func _fly_coin(from: Vector2) -> void:
	if _flying >= MAX_FLYING_COINS:
		return
	_flying += 1
	var s := Sprite2D.new()
	s.texture = _coin_tex
	s.position = from
	s.scale = Vector2(0.7, 0.7)
	_ui.add_child(s)
	var to := _coin_icon.global_position + _coin_icon.size / 2.0
	var ctrl := from + Vector2(randf_range(-80, 80), -220)
	var tw := create_tween()
	tw.tween_method(func(k: float):
		s.position = from.lerp(ctrl, k).lerp(ctrl.lerp(to, k), k)
		s.rotation = k * 6.0
		s.scale = Vector2.ONE * lerpf(0.75, 0.55, k), 0.0, 1.0, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		s.queue_free()
		_flying -= 1
		_pulse(_coin_icon, 1.25))


func _pulse(c: Control, amount := 1.12) -> void:
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * amount, 0.06)
	tw.tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Interfaz: estilos --------------------------------------------------------

func _box(bg: Color, border: Color, radius := 14, bottom := 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.border_width_bottom = bottom
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _button_styles(theme: Theme, type: String, base: Color) -> void:
	var normal := _box(base, base.darkened(0.45), 14, 7)
	normal.shadow_size = 3
	normal.set_content_margin_all(8)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = base.lightened(0.08)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.border_width_bottom = 2
	pressed.content_margin_top = 13
	pressed.bg_color = base.darkened(0.1)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.36, 0.31, 0.27)
	disabled.border_color = Color(0.22, 0.18, 0.15)
	for pair in [["normal", normal], ["hover", hover], ["pressed", pressed], ["disabled", disabled], ["focus", StyleBoxEmpty.new()]]:
		theme.set_stylebox(pair[0], type, pair[1])
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(c, type, Color.WHITE)
	theme.set_color("font_disabled_color", type, Color(0.7, 0.64, 0.58))
	theme.set_color("font_outline_color", type, Color(0, 0, 0, 0.45))
	theme.set_constant("outline_size", type, 5)
	if type != "Button":
		theme.set_type_variation(type, "Button")


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 24
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_outline_color", "Label", Color(0.1, 0.05, 0.02, 0.8))
	_button_styles(theme, "Button", Color(0.86, 0.5, 0.16))
	_button_styles(theme, "BuyButton", Color(0.34, 0.68, 0.24))
	_button_styles(theme, "ClaimButton", Color(0.95, 0.68, 0.12))
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0, 0, 0, 0.45)
	bar_bg.set_corner_radius_all(8)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.45, 0.8, 0.3)
	bar_fill.set_corner_radius_all(8)
	bar_fill.border_width_top = 3
	bar_fill.border_color = Color(0.65, 0.95, 0.5)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)
	return theme


func _panel(pos: Vector2, size: Vector2, parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.size = size
	p.add_theme_stylebox_override("panel", _box(LEATHER, Color(0.62, 0.43, 0.2)))
	parent.add_child(p)
	return p


func _label(text: String, size: int, parent: Control, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
	parent.add_child(l)
	return l


func _button(text: String, parent: Control, cb: Callable, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.focus_mode = Control.FOCUS_NONE
	if variation != "":
		b.theme_type_variation = variation
	b.pressed.connect(cb)
	b.button_down.connect(func(): _press_anim(b, 0.94))
	b.button_up.connect(func(): _press_anim(b, 1.0))
	parent.add_child(b)
	return b


func _press_anim(b: Control, s: float) -> void:
	b.pivot_offset = b.size / 2.0
	b.create_tween().tween_property(b, "scale", Vector2.ONE * s, 0.08)


func _icon_view(kind: String, size: float, parent: Control) -> Control:
	var v := IconScript.new()
	v.kind = kind
	v.custom_minimum_size = Vector2(size, size)
	parent.add_child(v)
	return v


func _bar(parent: Control, h := 12.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	b.max_value = 1.0
	b.step = 0.0
	parent.add_child(b)
	return b


# --- Interfaz: construcción ---------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.size = Vector2(720, 1280)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = _make_theme()
	layer.add_child(_ui)

	# Barra superior: monedas, época y ritmo
	var top := _panel(Vector2(8, 8), Vector2(704, 76), _ui)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top.add_child(top_row)
	_coin_icon = TextureRect.new()
	_coin_icon.texture = _coin_tex
	_coin_icon.custom_minimum_size = Vector2(46, 46)
	_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(_coin_icon)
	_coins_label = _label("0", 40, top_row, 8)
	_coins_label.add_theme_color_override("font_color", GOLD)
	_coins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", -4)
	top_row.add_child(right)
	var era_label := _label(GameState.era["nombre"], 24, right, 6)
	era_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rate_label = _label("", 19, right, 5)
	_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rate_label.add_theme_color_override("font_color", Color(0.65, 0.95, 0.55))

	# Misiones
	var missions := _panel(Vector2(8, 90), Vector2(704, 132), _ui)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	missions.add_child(mv)
	var head := HBoxContainer.new()
	mv.add_child(head)
	_icon_view("estrella", 24, head)
	_stars_label = _label("", 19, head, 5)
	_stars_label.add_theme_color_override("font_color", GOLD)
	_missions_box = VBoxContainer.new()
	_missions_box.add_theme_constant_override("separation", 3)
	mv.add_child(_missions_box)

	# Panel inferior de la estación seleccionada
	_bottom_panel = _panel(Vector2(8, 980), Vector2(704, BOTTOM_PANEL_H - 8), _ui)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 8)
	_bottom_panel.add_child(bv)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	bv.add_child(info_row)
	var frame := PanelContainer.new()
	var fsb := _box(Color(0.42, 0.3, 0.18), Color(0.75, 0.55, 0.25), 14, 4)
	fsb.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", fsb)
	info_row.add_child(frame)
	_icon = _icon_view("lanza", 84, frame)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(texts)
	_name_label = _label("", 27, texts, 6)
	_sub_label = _label("", 18, texts, 4)
	_sub_label.add_theme_color_override("font_color", GOLD)
	_milestone_bar = _bar(texts, 12)
	_info_label = _label("", 18, texts, 4)
	_info_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.72))
	var buy_row := HBoxContainer.new()
	buy_row.add_theme_constant_override("separation", 10)
	bv.add_child(buy_row)
	_mode_button = _button("x1", buy_row, _toggle_mode)
	_mode_button.custom_minimum_size.x = 104
	_buy_button = _button("", buy_row, _on_buy, "BuyButton")
	_buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_button.icon = _coin_tex
	_buy_button.add_theme_font_size_override("font_size", 26)
	_buy_button.add_theme_constant_override("icon_max_width", 34)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	bv.add_child(nav)
	_upgrades_button = _button("Mejoras", nav, _open_upgrades)
	_upgrades_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrades_button.custom_minimum_size.y = 56
	_portal_button = _button("Viajar a la siguiente época", nav, _on_portal, "ClaimButton")
	_portal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portal_button.custom_minimum_size.y = 56

	# Fondo oscuro para ventanas
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.size = Vector2(720, 3000)
	_dim.visible = false
	_dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_close_windows())
	_ui.add_child(_dim)

	# Ventana de mejoras
	_upgrades_panel = _panel(Vector2(16, 110), Vector2(688, 1060), _ui)
	_upgrades_panel.visible = false
	var uv := VBoxContainer.new()
	uv.add_theme_constant_override("separation", 10)
	_upgrades_panel.add_child(uv)
	var title := _label("Mejoras", 34, uv, 8)
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	uv.add_child(scroll)
	_upgrades_list = VBoxContainer.new()
	_upgrades_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrades_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_upgrades_list)
	_button("Cerrar", uv, _close_windows)
	var reset := _button("Reiniciar partida (pruebas)", uv, GameState.reset_game)
	reset.custom_minimum_size.y = 44
	reset.add_theme_font_size_override("font_size", 17)
	reset.modulate = Color(1, 1, 1, 0.6)
	_refresh_upgrades()

	# Ventana emergente
	_popup = _panel(Vector2(60, 460), Vector2(600, 300), _ui)
	_popup.visible = false
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 18)
	_popup.add_child(pv)
	var star := _icon_view("estrella", 64, pv)
	star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_popup_label = _label("", 25, pv, 5)
	_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_label.custom_minimum_size.x = 570
	_button("¡Genial!", pv, _close_windows, "BuyButton")


# La pantalla usa el ancho completo; en teléfonos altos el suelo crece hacia abajo.
func _layout() -> void:
	var h := get_viewport().get_visible_rect().size.y
	floor_bottom = maxf(h - BOTTOM_PANEL_H, 960.0)
	_bottom_panel.position.y = floor_bottom
	_upgrades_panel.size.y = minf(1060.0, h - 140.0)
	# Desplaza la cámara para que la pared del fondo quede justo bajo las misiones
	var ppu := get_viewport().get_visible_rect().size.x / VIEW_WIDTH
	for k in 2:
		var y := _screen(Vector3(0, 0, BACK_WALL_Z)).y
		_camera.v_offset -= (y - WALL_SCREEN_Y) / ppu
	door = _ground_at(Vector2(360, floor_bottom + 160))
	door.z = maxf(door.z, SPOT_Z + 4.0)
	queue_redraw()


func _open_window(w: Control) -> void:
	_dim.visible = true
	_dim.modulate.a = 0.0
	_dim.create_tween().tween_property(_dim, "modulate:a", 1.0, 0.15)
	w.visible = true
	w.pivot_offset = w.size / 2.0
	w.scale = Vector2(0.85, 0.85)
	w.modulate.a = 0.0
	var tw := w.create_tween().set_parallel()
	tw.tween_property(w, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(w, "modulate:a", 1.0, 0.15)


func _close_windows() -> void:
	_dim.visible = false
	_upgrades_panel.visible = false
	_popup.visible = false


func _open_upgrades() -> void:
	_open_window(_upgrades_panel)


func _show_popup(text: String) -> void:
	_popup_label.text = text
	_open_window(_popup)


func _toggle_mode() -> void:
	buy_mode = {1: 10, 10: 0, 0: 1}[buy_mode]
	_mode_button.text = "MAX" if buy_mode == 0 else "x%d" % buy_mode
	_refresh_panel()


func _levels_to_buy() -> int:
	var i := selected
	var room: int = GameState.max_level() - GameState.levels[i]
	if buy_mode == 0:
		return maxi(1, GameState.max_affordable(i)) if room > 0 else 0
	return mini(buy_mode, room)


func _on_buy() -> void:
	var i := selected
	if not GameState.is_unlocked(i):
		if GameState.unlock(i):
			_float_text("¡Desbloqueada!", _station_screen(i) + Vector2(-80, -60), Color(0.6, 1, 0.5))
		return
	var milestone := GameState.next_milestone(i)
	if GameState.buy_levels(i, _levels_to_buy()):
		var lv: int = GameState.levels[i]
		if milestone != -1 and lv >= milestone:
			_float_text("¡Hito! x2", _station_screen(i) + Vector2(-50, -60), GOLD)
		else:
			_float_text("Nv. %d" % lv, _station_screen(i) + Vector2(-30, -50), CREAM)


func _on_portal() -> void:
	_show_popup("¡Completaste la Prehistoria! La %s llegará en la próxima versión del prototipo." % GameState.era["siguiente"])


func _refresh_panel() -> void:
	var i := selected
	var data := GameState.station(i)
	var known := GameState.can_unlock(i) or GameState.is_unlocked(i)
	_icon.kind = data["id"] if known else ""
	if not GameState.is_unlocked(i):
		_name_label.text = data["nombre"] if known else "Estación bloqueada"
		_sub_label.text = "Nueva estación con 1 armero" if known else "Desbloquea primero la anterior"
		_info_label.text = ("Vende cada arma a %s" % Fmt.num(float(data["valor_base"]) * GameState.value_multiplier(i))) if known else ""
		_milestone_bar.visible = false
		_mode_button.visible = false
		return
	_mode_button.visible = true
	_milestone_bar.visible = true
	var lv: int = GameState.levels[i]
	_name_label.text = data["nombre"]
	var next := GameState.next_milestone(i)
	if next == -1:
		_sub_label.text = "Nivel %d  ·  máximo" % lv
		_milestone_bar.value = 1.0
	else:
		var prev := 1
		for h in GameState.econ["hitos_valor"]:
			if int(h) <= lv:
				prev = int(h)
		var bonus := "x2 valor" + (" y +1 armero" if GameState.is_armero_milestone(next) else "")
		_sub_label.text = "Nivel %d  ·  al %d: %s" % [lv, next, bonus]
		_milestone_bar.value = float(lv - prev) / float(next - prev)
	_info_label.text = "%s por arma  ·  %.1f s  ·  %d armero(s)" % [
		Fmt.num(GameState.value(i)), GameState.craft_time(i), GameState.armeros(i)]


# Se llama cada cuadro: solo textos y botones baratos.
func _refresh_live(delta: float) -> void:
	if GameState.coins < _shown_coins:
		_shown_coins = GameState.coins
	else:
		_shown_coins = lerpf(_shown_coins, GameState.coins, minf(1.0, delta * 6.0))
		if GameState.coins - _shown_coins < 0.5:
			_shown_coins = GameState.coins
	_coins_label.text = Fmt.num(_shown_coins)
	_rate_label.text = "+%s / s" % Fmt.num(GameState.earn_rate)
	var i := selected
	if not GameState.is_unlocked(i):
		var cost := GameState.unlock_cost(i)
		_buy_button.text = "Desbloquear  %s" % Fmt.num(cost)
		_buy_button.disabled = not GameState.can_unlock(i) or GameState.coins < cost
	else:
		var k := _levels_to_buy()
		if k == 0:
			_buy_button.text = "Nivel máximo"
			_buy_button.disabled = true
		else:
			var cost := GameState.level_cost(i, k)
			_buy_button.text = "Mejorar +%d   %s" % [k, Fmt.num(cost)]
			_buy_button.disabled = GameState.coins < cost
	var affordable := 0
	for row in _upgrades_list.get_children():
		if not row.has_meta("button"):
			continue
		var b: Button = row.get_meta("button")
		b.disabled = GameState.coins < float(row.get_meta("cost"))
		if not b.disabled:
			affordable += 1
	_upgrades_button.text = "Mejoras" if affordable == 0 else "Mejoras  (%d)" % affordable
	_upgrades_button.theme_type_variation = "BuyButton" if affordable > 0 else ""
	for row in _missions_box.get_children():
		if not row.has_meta("mission"):
			continue
		var m: Dictionary = row.get_meta("mission")
		var p := GameState.mission_progress(m)
		var done: bool = p[0] >= p[1]
		(row.get_meta("progress") as ProgressBar).value = float(p[0]) / float(p[1])
		(row.get_meta("count") as Label).text = "%s/%s" % [Fmt.num(p[0]), Fmt.num(p[1])]
		var b: Button = row.get_meta("button")
		b.visible = done
		if done:
			b.pivot_offset = b.size / 2.0
			b.scale = Vector2.ONE * (1.0 + 0.06 * sin(_t * 8.0))
	_portal_button.visible = GameState.stars() >= GameState.total_missions()


func _upgrade_icon(u: Dictionary) -> String:
	match u["tipo"]:
		"ganancia":
			return u["estacion"]
		"ganancia_todas":
			return "todo"
		_:
			return u["tipo"]


func _refresh_upgrades() -> void:
	for c in _upgrades_list.get_children():
		_upgrades_list.remove_child(c)
		c.queue_free()
	var list := GameState.available_upgrades()
	if list.is_empty():
		var l := _label("¡Compraste todas las mejoras de esta época!", 22, _upgrades_list)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return
	for u in list:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _box(Color(0.32, 0.22, 0.13), Color(0.55, 0.38, 0.2), 12, 4))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var iv := _icon_view(_upgrade_icon(u), 64, row)
		iv.animated = true
		var l := _label(u["nombre"], 21, row, 4)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 300
		var id: String = u["id"]
		var b := _button(Fmt.num(float(u["costo"])), row, func(): _buy_upgrade(id), "BuyButton")
		b.icon = _coin_tex
		b.add_theme_constant_override("icon_max_width", 28)
		b.custom_minimum_size = Vector2(170, 64)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card.set_meta("button", b)
		card.set_meta("cost", float(u["costo"]))
		_upgrades_list.add_child(card)


func _buy_upgrade(id: String) -> void:
	if GameState.buy_upgrade(id):
		_float_text("¡Mejora comprada!", Vector2(220, 600), Color(0.6, 1, 0.5))


func _refresh_missions() -> void:
	for c in _missions_box.get_children():
		_missions_box.remove_child(c)
		c.queue_free()
	_stars_label.text = "Misiones  ·  %d/%d estrellas" % [GameState.stars(), GameState.total_missions()]
	var active := GameState.active_missions()
	if active.is_empty():
		_label("¡Todas las misiones completadas! Viaja a la siguiente época.", 18, _missions_box, 4)
		return
	for m in active:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 30
		row.add_theme_constant_override("separation", 8)
		var l := _label(m["texto"], 17, row, 4)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		var bar_box := Control.new()
		bar_box.custom_minimum_size = Vector2(120, 22)
		bar_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar_box)
		var bar := _bar(bar_box, 22)
		bar.size = Vector2(120, 22)
		var count := _label("", 15, bar_box, 4)
		count.size = Vector2(120, 22)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var id: String = m["id"]
		var b := _button("¡Listo!", row, func(): _claim(id), "ClaimButton")
		b.custom_minimum_size = Vector2(96, 30)
		b.add_theme_font_size_override("font_size", 16)
		b.visible = false
		row.set_meta("mission", m)
		row.set_meta("progress", bar)
		row.set_meta("count", count)
		row.set_meta("button", b)
		_missions_box.add_child(row)


func _claim(id: String) -> void:
	GameState.claim_mission(id)
	_float_text("+1 estrella", Vector2(470, 200), GOLD)
