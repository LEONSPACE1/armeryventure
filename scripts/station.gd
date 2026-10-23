# Estación de fabricación: sus armeros fabrican armas solo cuando hay pedidos pendientes.
extends Node2D

const SIZE := Vector2(196, 136)

var idx := 0
var stock := 0      # armas listas en la estación
var reserved := 0   # armas listas que un dependiente ya viene a recoger
var slots: Array = []  # progreso de cada armero (0..1), -1 = libre
var selected := false
var _flash := 0.0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func rect() -> Rect2:
	return Rect2(position - SIZE / 2.0, SIZE)


func pickup_point() -> Vector2:
	return position + Vector2(0, SIZE.y / 2.0 + 22)


func free_stock() -> int:
	return stock - reserved


func crafting_count() -> int:
	var n := 0
	for s in slots:
		if s >= 0.0:
			n += 1
	return n


func tick(delta: float, demand: int) -> void:
	_flash = maxf(0.0, _flash - delta * 3.0)
	queue_redraw()
	if not GameState.is_unlocked(idx):
		return
	while slots.size() < GameState.armeros(idx):
		slots.append(-1.0)
	var t := GameState.craft_time(idx)
	for i in slots.size():
		if slots[i] < 0.0 and free_stock() + crafting_count() < demand:
			slots[i] = 0.0
		if slots[i] >= 0.0:
			slots[i] += delta / t
			if slots[i] >= 1.0:
				slots[i] = -1.0
				stock += 1


# Toque del jugador: adelanta el trabajo de todos los armeros activos.
func boost(amount: float) -> void:
	_flash = 1.0
	for i in slots.size():
		if slots[i] >= 0.0:
			slots[i] = minf(slots[i] + amount, 0.999)


func _draw() -> void:
	var r := Rect2(-SIZE / 2.0, SIZE)
	var data := GameState.station(idx)
	var unlocked := GameState.is_unlocked(idx)
	var base := Color(data["color"]) if unlocked else Color(0.35, 0.33, 0.31)
	var box := StyleBoxFlat.new()
	box.bg_color = base.lerp(Color.WHITE, _flash * 0.35)
	box.set_corner_radius_all(14)
	box.border_color = Color(1, 0.85, 0.3) if selected else base.darkened(0.35)
	box.set_border_width_all(5 if selected else 3)
	draw_style_box(box, r)
	var white := Color(1, 1, 1)
	if not unlocked:
		var title: String = data["nombre"] if GameState.can_unlock(idx) else "???"
		draw_string(_font, Vector2(r.position.x, -16), title, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 22, white)
		if GameState.can_unlock(idx):
			var cost := "Desbloquear: " + Fmt.num(GameState.unlock_cost(idx))
			var col := Color(0.6, 1, 0.6) if GameState.coins >= GameState.unlock_cost(idx) else Color(1, 0.75, 0.7)
			draw_string(_font, Vector2(r.position.x, 20), cost, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 20, col)
		else:
			draw_string(_font, Vector2(r.position.x, 20), "Bloqueada", HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 20, white)
		return
	draw_string(_font, Vector2(r.position.x, r.position.y + 28), data["nombre"], HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 21, white)
	draw_string(_font, Vector2(r.position.x, r.position.y + 54), "Nv. %d" % GameState.levels[idx], HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 20, Color(1, 0.93, 0.6))
	# Barras de progreso de cada armero
	var bar_w := SIZE.x - 32
	for i in slots.size():
		var y := r.position.y + 68 + i * 14
		draw_rect(Rect2(r.position.x + 16, y, bar_w, 9), Color(0, 0, 0, 0.35))
		if slots[i] >= 0.0:
			draw_rect(Rect2(r.position.x + 16, y, bar_w * slots[i], 9), Color(1, 0.85, 0.3))
	# Armeros (figuras) junto a la estación
	for i in slots.size():
		var p := Vector2(r.position.x + 22 + i * 26, r.end.y - 14)
		_draw_person(p, Color(0.85, 0.45, 0.2), slots[i] >= 0.0)
	# Armas listas
	for i in mini(stock, 6):
		draw_rect(Rect2(r.end.x - 22 - i * 16, r.end.y - 22, 12, 12), Color(1, 1, 1, 0.9))


func _draw_person(p: Vector2, c: Color, busy: bool) -> void:
	draw_circle(p, 9, c.darkened(0.2))
	draw_circle(p + Vector2(0, -12), 6, Color(0.96, 0.8, 0.65))
	if busy:
		draw_line(p + Vector2(6, -4), p + Vector2(14, -14), Color(0.3, 0.3, 0.3), 3)
