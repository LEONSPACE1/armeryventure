# Escena principal: arma la armería, mueve clientes y dependientes y maneja la interfaz.
extends Node2D

const StationScript := preload("res://scripts/station.gd")
const CustomerScript := preload("res://scripts/customer.gd")
const WorkerScript := preload("res://scripts/worker.gd")
const CounterScript := preload("res://scripts/counter.gd")
const IconScript := preload("res://scripts/icon_view.gd")

const STATION_POS := [
	Vector2(128, 344), Vector2(360, 344), Vector2(592, 344),
	Vector2(244, 562), Vector2(476, 562),
]
const FLOOR_TOP := 228.0
const WALL_BOTTOM := 300.0
const WORKER_Y := 688.0
const COUNTER_Y := 748.0
const SPOT_Y := 846.0
const BOTTOM_PANEL_H := 300.0
const TORCHES := [Vector2(244, 266), Vector2(476, 266)]
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
var floor_bottom := 980.0  # depende del alto de la pantalla
var door := Vector2(360, 1010)
var _spawn_timer := 0.0
var _t := 0.0
var _world: Node2D
var _pebbles: Array = []
var _shown_coins := 0.0
var _flying := 0
var _coin_tex: ImageTexture

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
	_coin_tex = Art.coin_texture(48)
	_shown_coins = GameState.coins
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 70:
		_pebbles.append([Vector2(rng.randf_range(0, 720), rng.randf_range(WALL_BOTTOM, 1500)), rng.randf_range(2, 6), rng.randf()])
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)
	var counter := CounterScript.new()
	counter.position = Vector2(360, COUNTER_Y)
	_world.add_child(counter)
	for i in GameState.station_count():
		var s := StationScript.new()
		s.idx = i
		s.position = STATION_POS[i]
		_world.add_child(s)
		stations.append(s)
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


# --- Escenario ----------------------------------------------------------------

func _draw() -> void:
	var I := Transform2D.IDENTITY
	# Suelo de tierra con degradado: más oscuro al fondo para dar profundidad
	var fb := floor_bottom + 40
	draw_polygon(PackedVector2Array([Vector2(0, WALL_BOTTOM - 20), Vector2(720, WALL_BOTTOM - 20), Vector2(720, fb), Vector2(0, fb)]),
		PackedColorArray([Color(0.33, 0.24, 0.17), Color(0.33, 0.24, 0.17), Color(0.6, 0.46, 0.32), Color(0.6, 0.46, 0.32)]))
	for p in _pebbles:
		if p[0].y < fb:
			var depth: float = clampf((p[0].y - WALL_BOTTOM) / 700.0, 0.2, 1.0)
			Art.ellipse(self, I, p[0], p[1] * depth * 1.6, p[1] * depth, Color(0.25, 0.18, 0.12, 0.35 + p[2] * 0.3))
	# Alfombra de piel frente al mostrador
	Art.ellipse(self, I, Vector2(360, SPOT_Y + 4), 300, 44, Color(0.5, 0.36, 0.22, 0.55))
	Art.ellipse(self, I, Vector2(360, SPOT_Y + 4), 280, 36, Color(0.62, 0.47, 0.3, 0.5))
	# Pared de roca de la cueva con borde irregular
	var wall := PackedVector2Array([Vector2(0, FLOOR_TOP), Vector2(720, FLOOR_TOP)])
	for k in range(18, -1, -1):
		wall.append(Vector2(k * 40.0, WALL_BOTTOM - 8 + sin(k * 1.7) * 8.0 + (k % 3) * 4.0))
	draw_colored_polygon(wall, Color(0.24, 0.19, 0.16))
	for k in 9:
		var x := 30.0 + k * 82.0
		Art.ellipse(self, I, Vector2(x, FLOOR_TOP + 24 + (k % 2) * 16), 26, 12, Color(0.3, 0.24, 0.2))
		Art.poly(self, I, PackedVector2Array([Vector2(x - 8, FLOOR_TOP), Vector2(x + 8, FLOOR_TOP), Vector2(x, FLOOR_TOP + 22 + (k % 3) * 6)]), Color(0.19, 0.15, 0.13))
	# Pinturas rupestres
	_draw_painting(Vector2(40, 280))
	_draw_painting(Vector2(680, 282))
	# Antorchas y su luz cálida (titila)
	for tp in TORCHES:
		var f := 0.85 + 0.15 * sin(_t * 9.0 + tp.x) + 0.08 * sin(_t * 23.0)
		for r in [150.0, 100.0, 60.0]:
			Art.ellipse(self, I, tp + Vector2(0, 40), r * f, r * 0.7 * f, Color(1, 0.6, 0.2, 0.07))
		Art.line(self, I, tp + Vector2(0, 30), tp + Vector2(0, 2), Color(0.35, 0.22, 0.12), 6)
		Art.ellipse(self, I, tp + Vector2(0, -6), 9 * f, 14 * f, Color(1, 0.45, 0.1))
		Art.ellipse(self, I, tp + Vector2(0, -3), 5 * f, 8 * f, Color(1, 0.9, 0.4))
	# Entrada de la cueva (por donde entran los clientes)
	Art.ellipse(self, I, Vector2(door.x, floor_bottom + 10), 92, 46, Color(0.18, 0.13, 0.1))
	Art.ellipse(self, I, Vector2(door.x, floor_bottom + 16), 74, 36, Color(0.98, 0.88, 0.62))
	Art.ellipse(self, I, Vector2(door.x, floor_bottom + 24), 60, 24, Color(0.62, 0.78, 0.45))
	# Viñeta lateral
	for side in [0.0, 1.0]:
		var x0: float = side * 720.0
		var x1: float = x0 + (70.0 if side == 0.0 else -70.0)
		draw_polygon(PackedVector2Array([Vector2(x0, FLOOR_TOP), Vector2(x1, FLOOR_TOP), Vector2(x1, fb), Vector2(x0, fb)]),
			PackedColorArray([Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.35)]))


func _draw_painting(at: Vector2) -> void:
	var I := Transform2D.IDENTITY
	var ochre := Color(0.78, 0.42, 0.2, 0.75)
	Art.ellipse(self, I, at, 13, 7, ochre)
	Art.circle(self, I, at + Vector2(13, -5), 5, ochre)
	for lx in [-8, -3, 4, 9]:
		Art.line(self, I, at + Vector2(lx, 4), at + Vector2(lx, 13), ochre, 2)
	Art.line(self, I, at + Vector2(-26, -4), at + Vector2(-26, 10), ochre, 2)
	Art.circle(self, I, at + Vector2(-26, -8), 3, ochre)
	Art.line(self, I, at + Vector2(-26, 0), at + Vector2(-16, -10), ochre, 2)


# --- Bucle de juego -----------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
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
	c.position = door + Vector2(randf_range(-30, 30), 30)
	c.target = _spot_position(free_spot)
	_world.add_child(c)
	customers.append(c)
	spots[free_spot] = c


func _spot_position(i: int) -> Vector2:
	var n := spots.size()
	var step := 460.0 / maxf(n - 1, 1)
	return Vector2(130 + i * step, SPOT_Y)


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
					w.target = Vector2(w.customer.position.x, COUNTER_Y - 50)
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
	_fly_coin(c.position + Vector2(0, -60))
	_float_text("+" + Fmt.num(v), c.position + Vector2(-10, -150), GOLD)
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
		c.target = door + Vector2(randf_range(-30, 30), 60)


func _sync_workers() -> void:
	while workers.size() < GameState.dependientes():
		var w := WorkerScript.new()
		var i := workers.size()
		w.look_seed = i
		w.home = Vector2(170 + (i % 4) * 126, WORKER_Y - (i / 4) * 24)
		w.position = w.home if i < 1 else Vector2(-40, WORKER_Y)
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
		if s.rect().has_point(p):
			_select(s.idx)
			if GameState.is_unlocked(s.idx):
				s.boost(float(GameState.econ["impulso_toque"]))
			return


func _select(i: int) -> void:
	selected = i
	for s in stations:
		s.selected = s.idx == i
	_refresh_panel()


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
	door = Vector2(360, floor_bottom + 30)
	_bottom_panel.position.y = floor_bottom
	_upgrades_panel.size.y = minf(1060.0, h - 140.0)
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
			_float_text("¡Desbloqueada!", stations[i].position + Vector2(-80, -120), Color(0.6, 1, 0.5))
		return
	var milestone := GameState.next_milestone(i)
	if GameState.buy_levels(i, _levels_to_buy()):
		var lv: int = GameState.levels[i]
		if milestone != -1 and lv >= milestone:
			_float_text("¡Hito! x2", stations[i].position + Vector2(-50, -120), GOLD)
		else:
			_float_text("Nv. %d" % lv, stations[i].position + Vector2(-30, -110), CREAM)


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
