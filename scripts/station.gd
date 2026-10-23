# Estación de fabricación: sus armeros fabrican armas solo cuando hay pedidos pendientes.
extends Node2D

const SIZE := Vector2(196, 200)
const BENCH_Y := 14.0   # desplazamiento del banco hacia abajo
const SIGN_Y := -22.0   # desplazamiento del letrero hacia arriba

var idx := 0
var stock := 0      # armas listas en la estación
var reserved := 0   # armas listas que un dependiente ya viene a recoger
var slots: Array = []  # progreso de cada armero (0..1), -1 = libre
var selected := false
var _flash := 0.0
var _pop := 0.0
var _ring := -1.0
var _t := 0.0
var _phases: Array = []   # fase del martillo de cada armero
var _sparks: Array = []   # [pos, vel, vida]
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_t = randf() * 10.0


func rect() -> Rect2:
	return Rect2(position + Vector2(-SIZE.x / 2.0, -110), SIZE)


func pickup_point() -> Vector2:
	return position + Vector2(0, 104)


func free_stock() -> int:
	return stock - reserved


func crafting_count() -> int:
	var n := 0
	for s in slots:
		if s >= 0.0:
			n += 1
	return n


func tick(delta: float, demand: int) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 3.0)
	_pop = maxf(0.0, _pop - delta * 3.5)
	if _ring >= 0.0:
		_ring += delta * 2.0
		if _ring > 1.0:
			_ring = -1.0
	scale = Vector2.ONE * (1.0 + 0.12 * sin(_pop * PI))
	_update_sparks(delta)
	queue_redraw()
	if not GameState.is_unlocked(idx):
		return
	while slots.size() < GameState.armeros(idx):
		slots.append(-1.0)
		_phases.append(randf() * TAU)
	var t := GameState.craft_time(idx)
	for i in slots.size():
		if slots[i] < 0.0 and free_stock() + crafting_count() < demand:
			slots[i] = 0.0
		if slots[i] >= 0.0:
			var before := sin(_phases[i])
			_phases[i] += delta * 9.0
			if before > 0.0 and sin(_phases[i]) <= 0.0:
				_spawn_sparks(_armero_x(i) + 22, 6, 5)
			slots[i] += delta / t
			if slots[i] >= 1.0:
				slots[i] = -1.0
				stock += 1
				_spawn_sparks(_armero_x(i) + 10, 4, 10)


# Toque del jugador: adelanta el trabajo de todos los armeros activos.
func boost(amount: float) -> void:
	_flash = 1.0
	for i in slots.size():
		if slots[i] >= 0.0:
			slots[i] = minf(slots[i] + amount, 0.999)
			_spawn_sparks(_armero_x(i) + 22, 6, 4)


# Subida de nivel o desbloqueo: rebote y anillo dorado.
func celebrate() -> void:
	_pop = 1.0
	_ring = 0.0
	_spawn_sparks(0, -10, 18)


func _armero_x(i: int) -> float:
	var n := maxi(slots.size(), 1)
	return (i - (n - 1) / 2.0) * minf(46.0, 150.0 / n) - 10.0


func _spawn_sparks(x: float, y: float, n: int) -> void:
	for k in n:
		var v := Vector2(randf_range(-140, 140), randf_range(-260, -90))
		_sparks.append([Vector2(x, y), v, randf_range(0.25, 0.5)])


func _update_sparks(delta: float) -> void:
	for s in _sparks:
		s[1].y += 700.0 * delta
		s[0] += s[1] * delta
		s[2] -= delta
	_sparks = _sparks.filter(func(s): return s[2] > 0.0)


func _draw() -> void:
	var I := Transform2D.IDENTITY
	var data := GameState.station(idx)
	var unlocked := GameState.is_unlocked(idx)
	var accent := Color(data["color"])
	var wood := Color(0.6, 0.4, 0.22)
	var wood_top := Color(0.74, 0.53, 0.3)
	var wood_front := Color(0.48, 0.3, 0.16)

	# Contorno pulsante de la estación seleccionada
	if selected:
		var glow := 0.55 + 0.45 * sin(_t * 5.0)
		Art.rrect(self, I, Rect2(-104, -112, 208, 206), 18, Color(1, 0.82, 0.3, 0.18 * glow))
		Art.rrect_outline(self, I, Rect2(-104, -112, 208, 206), 18, Color(1, 0.82, 0.3, 0.6 + 0.4 * glow), 3)

	# Sombra del banco
	Art.ellipse(self, I, Vector2(0, 72 + BENCH_Y), 104, 12, Color(0, 0, 0, 0.3))

	if not unlocked:
		_draw_locked(data)
		return

	# Armeros detrás del banco
	for i in slots.size():
		var busy: bool = slots[i] >= 0.0
		var x := _armero_x(i)
		Art.person(self, Transform2D(0, Vector2(0.95, 0.95), 0, Vector2(x, 10 + BENCH_Y)), {
			"t": _t, "facing": 1.0, "outfit": Color(0.55, 0.32, 0.18), "skin": Art.SKINS[(idx + i) % 4],
			"hair": Art.HAIRS[(idx * 2 + i) % 5], "style": 2, "beard": (idx + i) % 2 == 0,
			"hammer": _phases[i] if busy else -1.0, "seed": float(i) + idx, "mood": 0,
		})

	# Banco de trabajo con volumen: cara superior, cara frontal y patas
	draw_set_transform(Vector2(0, BENCH_Y))
	Art.rrect(self, I, Rect2(-92, 2, 184, 30), 6, wood_top)
	for gx in [-60, -10, 40]:
		Art.line(self, I, Vector2(gx, 9), Vector2(gx + 26, 9), wood_top.darkened(0.12), 2)
	Art.rrect(self, I, Rect2(-92, 28, 184, 38), 4, wood_front)
	for px in [-46, 0, 46]:
		Art.line(self, I, Vector2(px, 30), Vector2(px, 64), wood_front.darkened(0.2), 2)
	Art.line(self, I, Vector2(-92, 29), Vector2(92, 29), wood_top.lightened(0.15), 2)
	draw_rect(Rect2(-88, 64, 10, 8), wood_front.darkened(0.35))
	draw_rect(Rect2(78, 64, 10, 8), wood_front.darkened(0.35))

	# Arma que se está fabricando sobre el banco (aparece según el progreso)
	for i in slots.size():
		if slots[i] >= 0.0:
			var x := _armero_x(i) + 24
			var k: float = slots[i]
			Art.ellipse(self, I, Vector2(x, 20), 16, 4, Color(0, 0, 0, 0.18))
			Art.weapon(self, data["id"], Transform2D(-0.6, Vector2(0.5, 0.5) * (0.6 + 0.4 * k), 0, Vector2(x, 14)))

	# Barras de progreso en la cara frontal
	var n := slots.size()
	var bar_h := minf(8.0, 28.0 / maxf(n, 1))
	for i in n:
		var y := 33.0 + i * (bar_h + 2)
		Art.rrect(self, I, Rect2(-84, y, 112, bar_h), bar_h / 2, Color(0, 0, 0, 0.35))
		if slots[i] >= 0.0:
			Art.rrect(self, I, Rect2(-84, y, maxf(bar_h, 112 * slots[i]), bar_h), bar_h / 2, Color(1, 0.8, 0.25))

	# Armas listas: ícono + cantidad
	if stock > 0:
		Art.rrect(self, I, Rect2(36, 33, 52, 28), 8, Color(0, 0, 0, 0.3))
		Art.weapon(self, data["id"], Transform2D(0, Vector2(0.42, 0.42), 0, Vector2(50, 47)))
		draw_string_outline(_font, Vector2(62, 55), "x%d" % stock, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Art.INK)
		draw_string(_font, Vector2(62, 55), "x%d" % stock, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

	draw_set_transform(Vector2(0, SIGN_Y))
	_draw_sign(data["nombre"], accent)
	# Insignia de nivel
	Art.circle(self, I, Vector2(84, -66), 17, Color(0.4, 0.25, 0.08))
	Art.circle(self, I, Vector2(84, -67), 15, Color(1, 0.8, 0.25))
	var lv := str(GameState.levels[idx])
	draw_string(_font, Vector2(64, -60), lv, HORIZONTAL_ALIGNMENT_CENTER, 40, 17 if lv.length() < 3 else 14, Color(0.35, 0.2, 0.05))

	draw_set_transform(Vector2(0, BENCH_Y))
	_draw_effects(I)
	draw_set_transform(Vector2.ZERO)


func _draw_sign(title: String, accent: Color) -> void:
	var I := Transform2D.IDENTITY
	Art.rrect(self, I, Rect2(-92, -80, 160, 30), 8, Color(0.3, 0.19, 0.1))
	Art.rrect(self, I, Rect2(-92, -82, 160, 28), 8, accent.darkened(0.15))
	Art.rrect(self, I, Rect2(-88, -80, 152, 10), 6, Color(1, 1, 1, 0.12))
	draw_string_outline(_font, Vector2(-92, -61), title, HORIZONTAL_ALIGNMENT_CENTER, 160, 17, 5, Color(0.2, 0.12, 0.05))
	draw_string(_font, Vector2(-92, -61), title, HORIZONTAL_ALIGNMENT_CENTER, 160, 17, Color(1, 0.97, 0.9))


func _draw_locked(data: Dictionary) -> void:
	var I := Transform2D.IDENTITY
	var can := GameState.can_unlock(idx)
	draw_set_transform(Vector2(0, BENCH_Y))
	Art.rrect(self, I, Rect2(-92, 2, 184, 30), 6, Color(0.32, 0.27, 0.23, 0.9))
	Art.rrect(self, I, Rect2(-92, 28, 184, 38), 4, Color(0.24, 0.2, 0.17, 0.9))
	# Candado
	var lock_y := -14.0 + (sin(_t * 3.0) * 2.0 if can else 0.0)
	Art.rrect_outline(self, I, Rect2(-12, lock_y - 22, 24, 24), 10, Color(0.75, 0.75, 0.78), 5)
	Art.rrect(self, I, Rect2(-18, lock_y - 8, 36, 28), 6, Color(0.85, 0.65, 0.2))
	Art.circle(self, I, Vector2(0, lock_y + 4), 4, Color(0.35, 0.22, 0.05))
	if can:
		draw_set_transform(Vector2(0, SIGN_Y))
		_draw_sign(data["nombre"], Color(0.45, 0.4, 0.35))
		draw_set_transform(Vector2(0, BENCH_Y))
		var cost := GameState.unlock_cost(idx)
		var ok := GameState.coins >= cost
		var pulse := 1.0 + (0.06 * sin(_t * 6.0) if ok else 0.0)
		var tag := Rect2(-70 * pulse, 34, 140 * pulse, 28)
		Art.rrect(self, I, tag, 12, Color(0.3, 0.65, 0.25) if ok else Color(0.4, 0.3, 0.25))
		var txt := Fmt.num(cost)
		draw_string_outline(_font, Vector2(-70, 55), txt, HORIZONTAL_ALIGNMENT_CENTER, 140, 20, 4, Art.INK)
		draw_string(_font, Vector2(-70, 55), txt, HORIZONTAL_ALIGNMENT_CENTER, 140, 20, Color.WHITE)
	else:
		draw_set_transform(Vector2(0, SIGN_Y))
		_draw_sign("???", Color(0.35, 0.32, 0.3))
		draw_set_transform(Vector2(0, BENCH_Y))
	_draw_effects(I)
	draw_set_transform(Vector2.ZERO)


func _draw_effects(I: Transform2D) -> void:
	if _flash > 0.0:
		Art.rrect(self, I, Rect2(-92, 2, 184, 64), 6, Color(1, 0.95, 0.7, _flash * 0.35))
	if _ring >= 0.0:
		var r := 30.0 + _ring * 120.0
		Art.polyline(self, I, Art.ellipse_pts(Vector2(0, 10), r, r * 0.6, 32) + PackedVector2Array([Vector2(r, 10)]), Color(1, 0.85, 0.3, 1.0 - _ring), 5)
	for s in _sparks:
		var p: Vector2 = s[0]
		var v: Vector2 = s[1]
		draw_line(p, p - v * 0.03, Color(1, 0.85, 0.35, clampf(s[2] * 3.0, 0.0, 1.0)), 3)
