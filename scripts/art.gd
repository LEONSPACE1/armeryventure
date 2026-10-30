# Dibujo procedural (sin imágenes): figuras básicas, personajes y armas.
# Todo se dibuja con una transformación manual (xf) para poder voltear, escalar
# y rotar sin pelear con draw_set_transform.
class_name Art

const SKINS := [Color(0.96, 0.8, 0.65), Color(0.85, 0.65, 0.48), Color(0.68, 0.48, 0.33), Color(0.52, 0.36, 0.24)]
const HAIRS := [Color(0.2, 0.13, 0.08), Color(0.42, 0.26, 0.12), Color(0.12, 0.1, 0.1), Color(0.72, 0.5, 0.25), Color(0.55, 0.53, 0.5)]
const FURS := [Color(0.62, 0.42, 0.24), Color(0.5, 0.36, 0.26), Color(0.72, 0.6, 0.42), Color(0.45, 0.5, 0.32), Color(0.6, 0.3, 0.22), Color(0.4, 0.42, 0.5)]
const INK := Color(0.16, 0.1, 0.06)

# Si tiene alfa > 0, reemplaza todos los colores (para contornos y brillos).
static var override := Color(0, 0, 0, 0)


static func _c(col: Color) -> Color:
	return override if override.a > 0.0 else col


# --- Primitivas ---------------------------------------------------------------

static func line(ci: CanvasItem, xf: Transform2D, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(xf * a, xf * b, _c(col), w * absf(xf.get_scale().y), true)


static func polyline(ci: CanvasItem, xf: Transform2D, pts: PackedVector2Array, col: Color, w: float) -> void:
	ci.draw_polyline(xf * pts, _c(col), w * absf(xf.get_scale().y), true)


static func poly(ci: CanvasItem, xf: Transform2D, pts: PackedVector2Array, col: Color) -> void:
	ci.draw_colored_polygon(xf * pts, _c(col))


static func ellipse_pts(c: Vector2, rx: float, ry: float, n := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func ellipse(ci: CanvasItem, xf: Transform2D, c: Vector2, rx: float, ry: float, col: Color) -> void:
	poly(ci, xf, ellipse_pts(c, rx, ry), col)


static func circle(ci: CanvasItem, xf: Transform2D, c: Vector2, r: float, col: Color) -> void:
	ellipse(ci, xf, c, r, r, col)


static func rrect_pts(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	rad = minf(rad, minf(r.size.x, r.size.y) / 2.0)
	var corners := [
		[r.position + Vector2(r.size.x - rad, rad), -PI / 2],
		[r.end - Vector2(rad, rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI / 2],
		[r.position + Vector2(rad, rad), PI],
	]
	for c in corners:
		for k in 5:
			var a: float = c[1] + (PI / 2) * k / 4.0
			pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func rrect(ci: CanvasItem, xf: Transform2D, r: Rect2, rad: float, col: Color) -> void:
	poly(ci, xf, rrect_pts(r, rad), col)


static func rrect_outline(ci: CanvasItem, xf: Transform2D, r: Rect2, rad: float, col: Color, w: float) -> void:
	var pts := rrect_pts(r, rad)
	pts.append(pts[0])
	polyline(ci, xf, pts, col, w)


static func heart(ci: CanvasItem, xf: Transform2D, c: Vector2, s: float, col: Color) -> void:
	circle(ci, xf, c + Vector2(-s * 0.5, 0), s * 0.55, col)
	circle(ci, xf, c + Vector2(s * 0.5, 0), s * 0.55, col)
	poly(ci, xf, PackedVector2Array([c + Vector2(-s * 1.02, s * 0.15), c + Vector2(s * 1.02, s * 0.15), c + Vector2(0, s * 1.3)]), col)


# --- Armas (caben en una caja de unos 44 x 44 centrada en el origen) ----------

static func weapon(ci: CanvasItem, id: String, xf: Transform2D) -> void:
	var wood := Color(0.55, 0.35, 0.18)
	var wood_dark := Color(0.38, 0.23, 0.11)
	var stone := Color(0.62, 0.63, 0.66)
	var stone_dark := Color(0.4, 0.41, 0.45)
	match id:
		"lanza":
			line(ci, xf, Vector2(-17, 17), Vector2(12, -12), wood_dark, 5)
			line(ci, xf, Vector2(-17, 17), Vector2(12, -12), wood, 3)
			poly(ci, xf, PackedVector2Array([Vector2(8, -15), Vector2(22, -22), Vector2(15, -8)]), stone)
			poly(ci, xf, PackedVector2Array([Vector2(12, -12), Vector2(22, -22), Vector2(15, -8)]), stone_dark)
			line(ci, xf, Vector2(7, -10), Vector2(11, -6), Color(0.3, 0.2, 0.1), 3)
		"hacha":
			line(ci, xf, Vector2(-12, 18), Vector2(6, -8), wood_dark, 7)
			line(ci, xf, Vector2(-12, 18), Vector2(6, -8), wood, 4)
			poly(ci, xf, PackedVector2Array([Vector2(-2, -18), Vector2(10, -22), Vector2(20, -12), Vector2(16, 0), Vector2(6, -2)]), stone)
			poly(ci, xf, PackedVector2Array([Vector2(10, -11), Vector2(20, -12), Vector2(16, 0), Vector2(6, -2)]), stone_dark)
			line(ci, xf, Vector2(4, -14), Vector2(10, -16), stone_dark, 2)
			line(ci, xf, Vector2(2, -6), Vector2(8, -10), Color(0.3, 0.2, 0.1), 3)
		"honda":
			polyline(ci, xf, PackedVector2Array([Vector2(-18, -18), Vector2(-10, -4), Vector2(-4, 8)]), Color(0.8, 0.68, 0.45), 3)
			polyline(ci, xf, PackedVector2Array([Vector2(18, -18), Vector2(10, -4), Vector2(4, 8)]), Color(0.8, 0.68, 0.45), 3)
			ellipse(ci, xf, Vector2(0, 11), 10, 7, Color(0.5, 0.32, 0.18))
			circle(ci, xf, Vector2(0, 8), 5, stone)
			circle(ci, xf, Vector2(-1.5, 6.5), 2, Color(0.8, 0.8, 0.82))
			circle(ci, xf, Vector2(-18, -18), 3, Color(0.8, 0.68, 0.45))
		"atlatl":
			line(ci, xf, Vector2(-20, 16), Vector2(6, -6), wood_dark, 6)
			line(ci, xf, Vector2(-20, 16), Vector2(6, -6), wood, 4)
			line(ci, xf, Vector2(6, -6), Vector2(4, -12), wood_dark, 4)
			line(ci, xf, Vector2(-16, 6), Vector2(18, -20), Color(0.82, 0.68, 0.45), 3)
			poly(ci, xf, PackedVector2Array([Vector2(15, -22), Vector2(24, -26), Vector2(20, -17)]), stone)
			poly(ci, xf, PackedVector2Array([Vector2(-16, 6), Vector2(-20, 4), Vector2(-14, 1)]), Color(0.9, 0.3, 0.25))
			poly(ci, xf, PackedVector2Array([Vector2(-16, 6), Vector2(-14, 10), Vector2(-11, 3)]), Color(0.95, 0.85, 0.7))
		"arco":
			var bow := PackedVector2Array()
			for i in 13:
				var k := i / 12.0
				bow.append(Vector2(-6 - sin(k * PI) * 12, -22 + 44 * k))
			polyline(ci, xf, bow, wood_dark, 6)
			polyline(ci, xf, bow, wood, 4)
			line(ci, xf, Vector2(-6, -22), Vector2(-6, 22), Color(0.95, 0.92, 0.85), 1.5)
			line(ci, xf, Vector2(-14, 0), Vector2(18, 0), Color(0.75, 0.6, 0.38), 3)
			poly(ci, xf, PackedVector2Array([Vector2(16, -5), Vector2(25, 0), Vector2(16, 5)]), stone)
			poly(ci, xf, PackedVector2Array([Vector2(-14, 0), Vector2(-20, -6), Vector2(-10, 0)]), Color(0.9, 0.3, 0.25))
			poly(ci, xf, PackedVector2Array([Vector2(-14, 0), Vector2(-20, 6), Vector2(-10, 0)]), Color(0.9, 0.3, 0.25))
		_:
			circle(ci, xf, Vector2.ZERO, 14, stone)


# --- Personajes ---------------------------------------------------------------
# Pies en el origen; mide unos 80 px de alto. Campos de o:
# t, walk (fase de caminar), moving, facing (1/-1), outfit, skin, hair, style,
# mood (0 normal, 1 feliz), carry (id de arma o ""), hammer (-1 o fase), apron

static func person(ci: CanvasItem, base: Transform2D, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var walk: float = o.get("walk", 0.0)
	var moving: bool = o.get("moving", false)
	var facing: float = o.get("facing", 1.0)
	var outfit: Color = o.get("outfit", FURS[0])
	var skin: Color = o.get("skin", SKINS[0])
	var hair: Color = o.get("hair", HAIRS[0])
	var style: int = o.get("style", 0)
	var mood: int = o.get("mood", 0)
	var carry: String = o.get("carry", "")
	var hammer: float = o.get("hammer", -1.0)
	var seed: float = o.get("seed", 0.0)

	# Sombra en el suelo (no se voltea ni rebota)
	ellipse(ci, base, Vector2(0, 0), 20, 7, Color(0, 0, 0, 0.28))

	var bob := -absf(sin(walk)) * 4.0 if moving else sin(t * 2.2 + seed) * 1.2
	var xf := base * Transform2D(0, Vector2(facing, 1), 0, Vector2(0, bob))
	var swing := sin(walk) * 7.0 if moving else 0.0
	var dark := outfit.darkened(0.3)

	# Piernas
	line(ci, xf, Vector2(-6, -24), Vector2(-6 + swing, -3), skin.darkened(0.15), 7)
	line(ci, xf, Vector2(6, -24), Vector2(6 - swing, -3), skin.darkened(0.15), 7)
	ellipse(ci, xf, Vector2(-6 + swing, -2), 6, 3.5, Color(0.3, 0.2, 0.12))
	ellipse(ci, xf, Vector2(6 - swing, -2), 6, 3.5, Color(0.3, 0.2, 0.12))

	# Brazo trasero
	var arm_back_end := Vector2(-15 - swing * 0.6, -26)
	if carry != "":
		arm_back_end = Vector2(-8, -84)
	line(ci, xf, Vector2(-11, -46), arm_back_end, skin.darkened(0.1), 6)

	# Torso con sombreado lateral y borde de piel
	var torso := PackedVector2Array([Vector2(-15, -50), Vector2(15, -50), Vector2(17, -22), Vector2(-17, -22)])
	poly(ci, xf, torso, outfit)
	poly(ci, xf, PackedVector2Array([Vector2(4, -50), Vector2(15, -50), Vector2(17, -22), Vector2(6, -22)]), dark)
	var hem := PackedVector2Array()
	for i in 7:
		hem.append(Vector2(-17 + i * 34.0 / 6.0, -22 + (4.0 if i % 2 == 1 else 0.0)))
	polyline(ci, xf, hem, dark.darkened(0.2), 3)
	if o.get("apron", false):
		rrect(ci, xf, Rect2(-10, -40, 20, 22), 4, Color(0.92, 0.87, 0.75))
		line(ci, xf, Vector2(-14, -40), Vector2(14, -40), Color(0.75, 0.68, 0.55), 2)
	else:
		line(ci, xf, Vector2(-16, -30), Vector2(16, -30), Color(0.3, 0.2, 0.1), 3)

	# Cabeza
	var head := Vector2(0, -64)
	circle(ci, xf, head, 14, skin)
	ellipse(ci, xf, head + Vector2(5, 2), 8, 10, skin.darkened(0.08))
	# Pelo según estilo
	match style % 4:
		0:
			poly(ci, xf, PackedVector2Array([head + Vector2(-15, 0), head + Vector2(-12, -12), head + Vector2(0, -17), head + Vector2(12, -12), head + Vector2(15, -2), head + Vector2(6, -8), head + Vector2(-4, -6)]), hair)
		1:
			circle(ci, xf, head + Vector2(-2, -10), 11, hair)
			poly(ci, xf, PackedVector2Array([head + Vector2(-15, -4), head + Vector2(-16, 14), head + Vector2(-9, 6)]), hair)
		2:
			poly(ci, xf, PackedVector2Array([head + Vector2(-15, -2), head + Vector2(-8, -16), head + Vector2(8, -16), head + Vector2(15, -2), head + Vector2(8, -9), head + Vector2(-8, -9)]), hair)
			line(ci, xf, head + Vector2(-14, -6), head + Vector2(14, -6), Color(0.85, 0.25, 0.2), 4)
		3:
			poly(ci, xf, PackedVector2Array([head + Vector2(-14, -4), head + Vector2(0, -16), head + Vector2(14, -4), head + Vector2(0, -10)]), hair)
			line(ci, xf, head + Vector2(-10, -12), head + Vector2(-20, -30), Color(0.95, 0.9, 0.8), 3)
			line(ci, xf, head + Vector2(-20, -30), head + Vector2(-16, -22), Color(0.9, 0.35, 0.25), 3)
	# Barba para los armeros
	if o.get("beard", false):
		poly(ci, xf, PackedVector2Array([head + Vector2(-11, 3), head + Vector2(11, 3), head + Vector2(6, 15), head + Vector2(0, 18), head + Vector2(-6, 15)]), hair)
	# Ojos con parpadeo
	var blink := fmod(t + seed * 3.0, 3.6) < 0.12
	for ex in [-4.0, 6.0]:
		var e := head + Vector2(ex + 2, -1)
		if blink:
			line(ci, xf, e - Vector2(2.5, 0), e + Vector2(2.5, 0), INK, 2)
		else:
			ellipse(ci, xf, e, 2.2, 3, INK)
			circle(ci, xf, e + Vector2(0.6, -1), 0.8, Color.WHITE)
	# Boca
	if mood == 1:
		poly(ci, xf, PackedVector2Array([head + Vector2(-3, 6), head + Vector2(9, 6), head + Vector2(3, 11)]), Color(0.55, 0.15, 0.12))
	elif not o.get("beard", false):
		line(ci, xf, head + Vector2(0, 7), head + Vector2(6, 7), INK, 2)
	# Mejillas
	circle(ci, xf, head + Vector2(10, 4), 2.5, Color(0.95, 0.5, 0.45, 0.45))

	# Brazo delantero y lo que lleva
	if carry != "":
		line(ci, xf, Vector2(11, -46), Vector2(8, -84), skin, 6)
		weapon(ci, carry, xf * Transform2D(0, Vector2(0.9, 0.9), 0, Vector2(0, -96)))
	elif hammer >= 0.0:
		# hammer = fase del golpe; arriba cuando sin > 0, golpe al bajar
		var raise := maxf(0.0, sin(hammer))
		var dir := Vector2(0, 1).rotated(lerpf(-0.35, -2.6, raise))
		var shoulder := Vector2(11, -46)
		var hand := shoulder + dir * 18.0
		line(ci, xf, shoulder, hand, skin, 6)
		var tip := hand + dir * 14.0
		line(ci, xf, hand, tip, Color(0.45, 0.28, 0.14), 4)
		ellipse(ci, xf, tip, 7, 5, Color(0.55, 0.56, 0.6))
	else:
		line(ci, xf, Vector2(11, -46), Vector2(15 + swing * 0.6, -26), skin, 6)


# --- Texturas generadas -------------------------------------------------------

static func coin_texture(size := 48) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) / 2.0
	var r := size / 2.0 - 1.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d <= r:
				col = Color(0.75, 0.48, 0.1)
				if d <= r - 3.0:
					var shade := clampf(0.5 + (c.y - y) / size, 0.0, 1.0)
					col = Color(0.98, 0.78, 0.22).lerp(Color(1, 0.92, 0.55), shade * 0.6)
				if absf(d - r * 0.62) < 1.2:
					col = Color(0.85, 0.58, 0.12)
				col.a = clampf(r - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func star(ci: CanvasItem, xf: Transform2D, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + PI * i / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	poly(ci, xf, pts, col)


# Íconos de la interfaz: armas por id o símbolos genéricos.
static func icon(ci: CanvasItem, kind: String, xf: Transform2D, t := 0.0) -> void:
	match kind:
		"estrella":
			star(ci, xf, Vector2(0, 2), 24, Color(0.55, 0.35, 0.05))
			star(ci, xf, Vector2(0, 0), 22, Color(1, 0.82, 0.25))
			star(ci, xf, Vector2(-3, -3), 9, Color(1, 0.95, 0.7, 0.7))
		"dependiente":
			person(ci, xf * Transform2D(0, Vector2(0.5, 0.5), 0, Vector2(0, 22)), {"t": t, "outfit": Color(0.22, 0.5, 0.62), "apron": true, "style": 0})
		"clientes":
			person(ci, xf * Transform2D(0, Vector2(0.42, 0.42), 0, Vector2(-9, 22)), {"t": t, "outfit": FURS[1], "style": 1, "skin": SKINS[1]})
			person(ci, xf * Transform2D(0, Vector2(0.48, 0.48), 0, Vector2(9, 24)), {"t": t, "outfit": FURS[0], "style": 3, "mood": 1})
		"velocidad":
			for k in 3:
				line(ci, xf, Vector2(-20, -10 + k * 10), Vector2(-4, -10 + k * 10), Color(1, 1, 1, 0.5), 4)
			poly(ci, xf, PackedVector2Array([Vector2(0, -16), Vector2(22, 0), Vector2(0, 16)]), Color(0.45, 0.85, 1.0))
		"fila":
			rrect(ci, xf, Rect2(-22, -4, 44, 10), 3, Color(0.74, 0.53, 0.3))
			rrect(ci, xf, Rect2(-22, 5, 44, 12), 3, Color(0.48, 0.3, 0.16))
			for k in 3:
				circle(ci, xf, Vector2(-14 + k * 14, -14), 6, SKINS[k])
		"flecha":
			var arrow := PackedVector2Array([Vector2(0, -24), Vector2(20, -2), Vector2(8, -2), Vector2(8, 22), Vector2(-8, 22), Vector2(-8, -2), Vector2(-20, -2)])
			poly(ci, xf * Transform2D(0, Vector2(0, 3)), arrow, Color(0, 0, 0, 0.25))
			poly(ci, xf, arrow, Color.WHITE)
		"portal":
			circle(ci, xf, Vector2.ZERO, 24, Color(0.35, 0.2, 0.6))
			for k in 3:
				var r := 20.0 - k * 6.0
				var a0 := t * (2.0 + k) + k
				var pts := PackedVector2Array()
				for j in 13:
					var ang := a0 + j * 0.4
					pts.append(Vector2(cos(ang), sin(ang)) * r)
				polyline(ci, xf, pts, Color(0.7, 0.55, 1.0).lerp(Color.WHITE, k * 0.3), 3.0)
			circle(ci, xf, Vector2.ZERO, 4, Color.WHITE)
		"trofeo":
			poly(ci, xf, PackedVector2Array([Vector2(-16, -20), Vector2(16, -20), Vector2(12, -2), Vector2(0, 6), Vector2(-12, -2)]), Color(1, 0.8, 0.22))
			line(ci, xf, Vector2(-16, -14), Vector2(-22, -6), Color(1, 0.8, 0.22), 4)
			line(ci, xf, Vector2(16, -14), Vector2(22, -6), Color(1, 0.8, 0.22), 4)
			rrect(ci, xf, Rect2(-3, 5, 6, 9), 1, Color(0.85, 0.62, 0.15))
			rrect(ci, xf, Rect2(-12, 14, 24, 7), 3, Color(0.6, 0.4, 0.15))
			star(ci, xf, Vector2(0, -10), 6, Color(1, 0.97, 0.75))
		"engranaje":
			for k in 8:
				var ang := k * TAU / 8.0
				var d := Vector2(cos(ang), sin(ang))
				line(ci, xf, d * 12.0, d * 21.0, Color(0.92, 0.88, 0.8), 8)
			circle(ci, xf, Vector2.ZERO, 15, Color(0.92, 0.88, 0.8))
			circle(ci, xf, Vector2.ZERO, 6, Color(0.3, 0.22, 0.15))
		"cerrar":
			line(ci, xf, Vector2(-12, -12), Vector2(12, 12), Color.WHITE, 6)
			line(ci, xf, Vector2(12, -12), Vector2(-12, 12), Color.WHITE, 6)
		"todo":
			poly(ci, xf, PackedVector2Array([Vector2(0, -22), Vector2(16, -2), Vector2(6, -2), Vector2(6, 20), Vector2(-6, 20), Vector2(-6, -2), Vector2(-16, -2)]), Color(0.45, 0.85, 0.35))
		"gema":
			var gem := PackedVector2Array([Vector2(-20, -8), Vector2(-10, -20), Vector2(10, -20), Vector2(20, -8), Vector2(0, 22)])
			poly(ci, xf * Transform2D(0, Vector2(0, 3)), gem, Color(0, 0, 0, 0.25))
			poly(ci, xf, gem, Color(0.25, 0.75, 0.95))
			poly(ci, xf, PackedVector2Array([Vector2(-20, -8), Vector2(20, -8), Vector2(0, 22)]), Color(0.15, 0.55, 0.85))
			poly(ci, xf, PackedVector2Array([Vector2(-10, -20), Vector2(0, -8), Vector2(-20, -8)]), Color(0.7, 0.95, 1.0))
		"ficha":
			circle(ci, xf, Vector2(0, 2), 22, Color(0.3, 0.15, 0.45))
			circle(ci, xf, Vector2.ZERO, 22, Color(0.6, 0.38, 0.85))
			circle(ci, xf, Vector2.ZERO, 15, Color(0.48, 0.26, 0.72))
			for k in 3:
				var r := 11.0 - k * 4.0
				var pts := PackedVector2Array()
				for j in 10:
					var ang := k + j * 0.55
					pts.append(Vector2(cos(ang), sin(ang)) * r)
				polyline(ci, xf, pts, Color(0.9, 0.8, 1.0), 2.0)
		"cofre_madera", "cofre_plata", "cofre_oro", "cofre":
			var body: Color = {"cofre_plata": Color(0.62, 0.66, 0.72), "cofre_oro": Color(0.95, 0.72, 0.2)}.get(kind, Color(0.6, 0.38, 0.18))
			var trim: Color = {"cofre_plata": Color(0.35, 0.38, 0.45), "cofre_oro": Color(0.7, 0.42, 0.08)}.get(kind, Color(0.38, 0.38, 0.4))
			rrect(ci, xf, Rect2(-24, -4, 48, 26), 4, body.darkened(0.2))
			rrect(ci, xf, Rect2(-24, -22, 48, 20), 10, body)
			rrect(ci, xf, Rect2(-24, -6, 48, 5), 1, trim)
			for x in [-16.0, 13.0]:
				rrect(ci, xf, Rect2(x, -22, 4, 44), 1, trim)
			rrect(ci, xf, Rect2(-5, -9, 10, 12), 2, Color(1, 0.88, 0.4))
		"maestro":
			person(ci, xf * Transform2D(0, Vector2(0.5, 0.5), 0, Vector2(0, 24)), {"t": t, "outfit": Color(0.55, 0.25, 0.2), "apron": true, "style": 0, "mood": 1})
			poly(ci, xf, PackedVector2Array([Vector2(-12, -18), Vector2(-12, -28), Vector2(-6, -22), Vector2(0, -30), Vector2(6, -22), Vector2(12, -28), Vector2(12, -18)]), Color(1, 0.8, 0.25))
		"delantal":
			poly(ci, xf, PackedVector2Array([Vector2(-10, -22), Vector2(10, -22), Vector2(10, -10), Vector2(18, -6), Vector2(16, 22), Vector2(-16, 22), Vector2(-18, -6), Vector2(-10, -10)]), Color(0.6, 0.42, 0.25))
			rrect(ci, xf, Rect2(-8, 2, 16, 10), 2, Color(0.45, 0.3, 0.18))
		"martillo":
			line(ci, xf, Vector2(-14, 20), Vector2(6, -4), Color(0.5, 0.32, 0.16), 6)
			var head := Transform2D(-0.7, Vector2(8, -8))
			rrect(ci, xf * head, Rect2(-16, -7, 32, 14), 3, Color(0.7, 0.72, 0.76))
		"guantes":
			for sx in [-1.0, 1.0]:
				var g := Transform2D(0, Vector2(sx * 11, 2))
				rrect(ci, xf * g, Rect2(-9, -8, 18, 24), 6, Color(0.55, 0.36, 0.2))
				for k in 3:
					rrect(ci, xf * g, Rect2(-8 + k * 6, -20, 5, 14), 2, Color(0.55, 0.36, 0.2))
		"gafas":
			for sx in [-1.0, 1.0]:
				circle(ci, xf, Vector2(sx * 12, 0), 11, Color(0.35, 0.3, 0.25))
				circle(ci, xf, Vector2(sx * 12, 0), 8, Color(0.55, 0.85, 0.95))
			line(ci, xf, Vector2(-4, -2), Vector2(4, -2), Color(0.35, 0.3, 0.25), 4)
		_:
			weapon(ci, kind, xf)
