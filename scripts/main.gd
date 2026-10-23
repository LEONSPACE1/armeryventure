# Escena principal: arma la armería, mueve clientes y dependientes y maneja la interfaz.
extends Node2D

const StationScript := preload("res://scripts/station.gd")
const CustomerScript := preload("res://scripts/customer.gd")
const WorkerScript := preload("res://scripts/worker.gd")

const STATION_POS := [
	Vector2(128, 330), Vector2(360, 330), Vector2(592, 330),
	Vector2(244, 520), Vector2(476, 520),
]
const FLOOR_TOP := 236.0
const WORKER_Y := 650.0
const COUNTER_Y := 712.0
const SPOT_Y := 800.0
const BOTTOM_PANEL_H := 286.0

var stations: Array = []
var customers: Array = []
var workers: Array = []
var spots: Array = []
var selected := 0
var buy_mode := 1  # 1, 10 o 0 (= máximo)
var _spawn_timer := 0.0
var floor_bottom := 994.0  # depende del alto de la pantalla
var door := Vector2(360, 1030)

# Interfaz
var _coins_label: Label
var _rate_label: Label
var _missions_box: VBoxContainer
var _stars_label: Label
var _name_label: Label
var _info_label: Label
var _buy_button: Button
var _mode_button: Button
var _portal_button: Button
var _upgrades_panel: PanelContainer
var _upgrades_list: VBoxContainer
var _popup: PanelContainer
var _popup_label: Label
var _bottom_panel: PanelContainer


func _ready() -> void:
	randomize()
	for i in GameState.station_count():
		var s := StationScript.new()
		s.idx = i
		s.position = STATION_POS[i]
		add_child(s)
		stations.append(s)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_sync_workers()
	_sync_spots()
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	GameState.missions_changed.connect(_refresh_missions)
	GameState.station_changed.connect(func(_i): _refresh_panel())
	_select(0)
	_refresh_missions()
	if GameState.offline_reward > 0.0:
		_show_popup("Mientras no estabas, tu armería ganó %s monedas." % Fmt.num(GameState.offline_reward))
		GameState.claim_offline()


func _draw() -> void:
	# Suelo, pared, mostrador y puerta (arte provisional)
	draw_rect(Rect2(0, FLOOR_TOP, 720, floor_bottom - FLOOR_TOP), Color(0.55, 0.42, 0.3))
	for y in range(int(FLOOR_TOP), int(floor_bottom), 64):
		draw_line(Vector2(0, y), Vector2(720, y), Color(0.5, 0.38, 0.27), 2)
	draw_rect(Rect2(0, FLOOR_TOP, 720, 22), Color(0.36, 0.27, 0.2))
	draw_rect(Rect2(110, COUNTER_Y - 14, 500, 30), Color(0.4, 0.26, 0.15))
	draw_rect(Rect2(110, COUNTER_Y - 14, 500, 8), Color(0.55, 0.37, 0.22))
	draw_rect(Rect2(door.x - 60, floor_bottom - 14, 120, 14), Color(0.25, 0.18, 0.12))


# --- Bucle de juego -----------------------------------------------------------

func _process(delta: float) -> void:
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
	_refresh_live()


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
	c.position = door
	c.target = _spot_position(free_spot)
	add_child(c)
	customers.append(c)
	spots[free_spot] = c


func _spot_position(i: int) -> Vector2:
	var n := spots.size()
	var step := 440.0 / maxf(n - 1, 1)
	return Vector2(140 + i * step, SPOT_Y)


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
					w.target = Vector2(w.customer.position.x, COUNTER_Y - 44)
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
		w.carrying_color = Color(GameState.station(s.idx)["color"])
		w.state = WorkerScript.State.TO_STATION
		w.target = s.pickup_point()
		return


func _deliver(w) -> void:
	var c = w.customer
	var v := GameState.value(c.station_idx)
	GameState.add_coins(v)
	_float_text("+" + Fmt.num(v), c.position + Vector2(0, -80))
	c.incoming -= 1
	c.remaining -= 1
	w.carrying = false
	w.customer = null
	w.station = null
	w.state = WorkerScript.State.FREE
	if c.remaining <= 0:
		spots[c.spot] = null
		customers.erase(c)
		c.leaving = true
		c.target = door


func _sync_workers() -> void:
	while workers.size() < GameState.dependientes():
		var w := WorkerScript.new()
		var i := workers.size()
		w.home = Vector2(200 + (i % 4) * 106, WORKER_Y - (i / 4) * 30)
		w.position = w.home
		add_child(w)
		workers.append(w)


func _sync_spots() -> void:
	while spots.size() < GameState.queue_size():
		spots.append(null)
	# Reubica a los clientes que esperan si la fila creció
	for c in customers:
		c.target = _spot_position(c.spot)


func _on_upgrades_changed() -> void:
	_sync_workers()
	_sync_spots()
	_refresh_upgrades()
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


func _float_text(text: String, at: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	l.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.position = at - Vector2(40, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", at.y - 60, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


# --- Interfaz -----------------------------------------------------------------

func _panel(pos: Vector2, size: Vector2, parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.size = size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.1, 0.08, 0.95)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


func _label(text: String, size: int, parent: Control) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _button(text: String, parent: Control, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.size = Vector2(720, 1280)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 24
	_style_buttons(theme)
	root.theme = theme
	layer.add_child(root)

	# Barra superior
	var top := _panel(Vector2(8, 8), Vector2(704, 80), root)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	_coins_label = _label("0", 38, top_row)
	_coins_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_coins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := VBoxContainer.new()
	top_row.add_child(right)
	var era_label := _label(GameState.era["nombre"], 22, right)
	era_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rate_label = _label("", 18, right)
	_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Misiones
	var missions := _panel(Vector2(8, 94), Vector2(704, 136), root)
	var mv := VBoxContainer.new()
	missions.add_child(mv)
	_stars_label = _label("", 20, mv)
	_stars_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_missions_box = VBoxContainer.new()
	_missions_box.add_theme_constant_override("separation", 2)
	mv.add_child(_missions_box)

	# Panel inferior de la estación seleccionada
	var bottom := _panel(Vector2(8, 994), Vector2(704, BOTTOM_PANEL_H - 8), root)
	_bottom_panel = bottom
	var bv := VBoxContainer.new()
	bottom.add_child(bv)
	_name_label = _label("", 26, bv)
	_info_label = _label("", 19, bv)
	_info_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
	var buy_row := HBoxContainer.new()
	bv.add_child(buy_row)
	_mode_button = _button("x1", buy_row, _toggle_mode)
	_mode_button.custom_minimum_size.x = 110
	_buy_button = _button("", buy_row, _on_buy)
	_buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nav := HBoxContainer.new()
	bv.add_child(nav)
	var up_btn := _button("Mejoras", nav, func(): _upgrades_panel.visible = not _upgrades_panel.visible)
	up_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_btn.custom_minimum_size.y = 52
	_portal_button = _button("Viajar a la siguiente época", nav, _on_portal)
	_portal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portal_button.custom_minimum_size.y = 52

	# Ventana de mejoras
	_upgrades_panel = _panel(Vector2(20, 120), Vector2(680, 1040), root)
	_upgrades_panel.visible = false
	var uv := VBoxContainer.new()
	_upgrades_panel.add_child(uv)
	_label("Mejoras", 30, uv)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	uv.add_child(scroll)
	_upgrades_list = VBoxContainer.new()
	_upgrades_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrades_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_upgrades_list)
	_button("Cerrar", uv, func(): _upgrades_panel.visible = false)
	var reset := _button("Reiniciar partida (pruebas)", uv, GameState.reset_game)
	reset.custom_minimum_size.y = 44
	reset.add_theme_font_size_override("font_size", 18)
	_refresh_upgrades()

	# Ventana emergente
	_popup = _panel(Vector2(60, 480), Vector2(600, 260), root)
	_popup.visible = false
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 16)
	_popup.add_child(pv)
	_popup_label = _label("", 24, pv)
	_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_label.custom_minimum_size.x = 570
	_button("¡Genial!", pv, func(): _popup.visible = false)


# La pantalla usa el ancho completo; en teléfonos altos el suelo crece hacia abajo.
func _layout() -> void:
	var h := get_viewport().get_visible_rect().size.y
	floor_bottom = maxf(h - BOTTOM_PANEL_H, 900.0)
	door = Vector2(360, floor_bottom + 40)
	_bottom_panel.position.y = floor_bottom
	queue_redraw()


func _style_buttons(theme: Theme) -> void:
	var states := {
		"normal": Color(0.85, 0.5, 0.15), "hover": Color(0.92, 0.58, 0.2),
		"pressed": Color(0.7, 0.4, 0.1), "disabled": Color(0.3, 0.27, 0.25),
	}
	for st in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[st]
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(8)
		theme.set_stylebox(st, "Button", sb)
	theme.set_color("font_color", "Button", Color(1, 1, 1))
	theme.set_color("font_disabled_color", "Button", Color(0.65, 0.6, 0.55))
	theme.set_color("font_hover_color", "Button", Color(1, 1, 1))
	theme.set_color("font_pressed_color", "Button", Color(1, 1, 1))


func _show_popup(text: String) -> void:
	_popup_label.text = text
	_popup.visible = true


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
		GameState.unlock(i)
	else:
		GameState.buy_levels(i, _levels_to_buy())


func _on_portal() -> void:
	_show_popup("¡Completaste la Prehistoria! La %s llegará en la próxima versión del prototipo." % GameState.era["siguiente"])


func _refresh_panel() -> void:
	var i := selected
	var data := GameState.station(i)
	if not GameState.is_unlocked(i):
		_name_label.text = data["nombre"] if GameState.can_unlock(i) else "Estación bloqueada"
		_info_label.text = "Desbloquea primero la estación anterior." if not GameState.can_unlock(i) \
				else "Nueva estación con 1 armero."
		_mode_button.visible = false
		return
	_mode_button.visible = true
	var lv: int = GameState.levels[i]
	_name_label.text = "%s  ·  Nivel %d" % [data["nombre"], lv]
	var next := GameState.next_milestone(i)
	var next_text := "Nivel máximo alcanzado" if next == -1 else "Nivel %d: x2 valor" % next
	if GameState.is_armero_milestone(next):
		next_text += " y +1 armero"
	_info_label.text = "%s por arma  ·  %.1f s  ·  %d armero(s)\nPróximo hito: %s" % [
		Fmt.num(GameState.value(i)), GameState.craft_time(i), GameState.armeros(i), next_text]


# Se llama cada cuadro: solo textos y botones baratos.
func _refresh_live() -> void:
	_coins_label.text = Fmt.num(GameState.coins)
	_rate_label.text = "%s / s" % Fmt.num(GameState.earn_rate)
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
			_buy_button.text = "Mejorar +%d  ·  %s" % [k, Fmt.num(cost)]
			_buy_button.disabled = GameState.coins < cost
	for row in _upgrades_list.get_children():
		if not row.has_meta("button"):
			continue
		var b: Button = row.get_meta("button")
		b.disabled = GameState.coins < float(row.get_meta("cost"))
	for row in _missions_box.get_children():
		if not row.has_meta("mission"):
			continue
		var m: Dictionary = row.get_meta("mission")
		var p := GameState.mission_progress(m)
		var done: bool = p[0] >= p[1]
		(row.get_meta("progress") as Label).text = "%s/%s" % [Fmt.num(p[0]), Fmt.num(p[1])]
		(row.get_meta("button") as Button).visible = done
	_portal_button.visible = GameState.stars() >= GameState.total_missions()


func _refresh_upgrades() -> void:
	for c in _upgrades_list.get_children():
		_upgrades_list.remove_child(c)
		c.queue_free()
	var list := GameState.available_upgrades()
	if list.is_empty():
		_label("¡Compraste todas las mejoras de esta época!", 22, _upgrades_list)
		return
	for u in list:
		var row := HBoxContainer.new()
		var l := _label(u["nombre"], 21, row)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var id: String = u["id"]
		var b := _button(Fmt.num(float(u["costo"])), row, func(): GameState.buy_upgrade(id))
		b.custom_minimum_size = Vector2(150, 60)
		row.set_meta("button", b)
		row.set_meta("cost", float(u["costo"]))
		_upgrades_list.add_child(row)


func _refresh_missions() -> void:
	for c in _missions_box.get_children():
		_missions_box.remove_child(c)
		c.queue_free()
	_stars_label.text = "Misiones  ·  Estrellas %d/%d" % [GameState.stars(), GameState.total_missions()]
	var active := GameState.active_missions()
	if active.is_empty():
		_label("¡Todas las misiones completadas! Viaja a la siguiente época.", 19, _missions_box)
		return
	for m in active:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 32
		var l := _label(m["texto"], 19, row)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var p := _label("", 19, row)
		p.add_theme_color_override("font_color", Color(0.75, 0.9, 0.7))
		var id: String = m["id"]
		var b := Button.new()
		b.text = "Reclamar"
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 17)
		b.visible = false
		b.pressed.connect(func(): GameState.claim_mission(id))
		row.add_child(b)
		row.set_meta("mission", m)
		row.set_meta("progress", p)
		row.set_meta("button", b)
		_missions_box.add_child(row)
