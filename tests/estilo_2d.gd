# Mini-armería en 2D usada por tests/estilos.gd. mode: vector, contorno, pixel o neon.
extends Node2D

var mode := "vector"


func _draw() -> void:
	match mode:
		"contorno":
			# Contorno grueso: la escena en tinta desplazada en 12 direcciones y encima la escena
			_background()
			Art.override = Color(0.1, 0.06, 0.04)
			for k in 12:
				var a := TAU * k / 12.0
				draw_set_transform(Vector2(cos(a), sin(a)) * 5.0)
				_actors(true)
			Art.override = Color(0, 0, 0, 0)
			draw_set_transform(Vector2.ZERO)
			_actors(true)
		"neon":
			draw_rect(Rect2(0, 0, 720, 720), Color(0.03, 0.03, 0.09))
			for gx in range(0, 721, 48):
				draw_line(Vector2(gx, 380), Vector2(360 + (gx - 360) * 2.5, 720), Color(0.6, 0.2, 0.9, 0.35), 2)
			for gy in [400, 440, 500, 580, 690]:
				draw_line(Vector2(0, gy), Vector2(720, gy), Color(0.6, 0.2, 0.9, 0.35), 2)
			var glows := [[10.0, Color(0.1, 0.9, 1.0, 0.05)], [6.0, Color(0.1, 0.9, 1.0, 0.1)], [3.0, Color(0.4, 1.0, 1.0, 0.35)]]
			for g in glows:
				Art.override = g[1]
				for k in 8:
					var a := TAU * k / 8.0
					draw_set_transform(Vector2(cos(a), sin(a)) * g[0])
					_actors(false)
			draw_set_transform(Vector2.ZERO)
			Art.override = Color(0.02, 0.05, 0.12)
			_actors(false)
			Art.override = Color(0, 0, 0, 0)
		_:
			_background()
			_actors(false)


func _background() -> void:
	var I := Transform2D.IDENTITY
	draw_polygon(PackedVector2Array([Vector2(0, 150), Vector2(720, 150), Vector2(720, 720), Vector2(0, 720)]),
		PackedColorArray([Color(0.33, 0.24, 0.17), Color(0.33, 0.24, 0.17), Color(0.6, 0.46, 0.32), Color(0.6, 0.46, 0.32)]))
	draw_rect(Rect2(0, 0, 720, 170), Color(0.24, 0.19, 0.16))
	for k in 9:
		var x := 30.0 + k * 82.0
		Art.ellipse(self, I, Vector2(x, 150 + (k % 2) * 14), 30, 14, Color(0.3, 0.24, 0.2))
	var tp := Vector2(600, 120)
	for r in [160.0, 100.0, 60.0]:
		Art.ellipse(self, I, tp + Vector2(0, 50), r, r * 0.7, Color(1, 0.6, 0.2, 0.08))
	Art.line(self, I, tp + Vector2(0, 34), tp, Color(0.35, 0.22, 0.12), 7)
	Art.ellipse(self, I, tp + Vector2(0, -8), 11, 17, Color(1, 0.45, 0.1))
	Art.ellipse(self, I, tp + Vector2(0, -4), 6, 10, Color(1, 0.9, 0.4))


func _actors(bright: bool) -> void:
	var I := Transform2D.IDENTITY
	var sat := 1.25 if bright else 1.0
	# Banco con armero martillando
	Art.person(self, Transform2D(0, Vector2(1.3, 1.3), 0, Vector2(270, 300)), {
		"t": 1.0, "outfit": _s(Color(0.55, 0.32, 0.18), sat), "skin": Art.SKINS[1], "hair": Art.HAIRS[0],
		"style": 2, "beard": true, "hammer": PI / 2,
	})
	Art.rrect(self, I, Rect2(150, 290, 300, 40), 8, _s(Color(0.74, 0.53, 0.3), sat))
	Art.rrect(self, I, Rect2(150, 324, 300, 56), 6, _s(Color(0.48, 0.3, 0.16), sat))
	Art.weapon(self, "lanza", Transform2D(-0.6, Vector2(0.9, 0.9), 0, Vector2(360, 304)))
	Art.weapon(self, "hacha", Transform2D(0.2, Vector2(0.8, 0.8), 0, Vector2(420, 300)))
	# Dependiente cargando un arco
	Art.person(self, Transform2D(0, Vector2(1.3, 1.3), 0, Vector2(560, 470)), {
		"t": 2.0, "walk": 1.2, "moving": true, "facing": -1.0, "outfit": _s(Color(0.22, 0.5, 0.62), sat),
		"skin": Art.SKINS[0], "hair": Art.HAIRS[2], "apron": true, "carry": "arco", "mood": 1,
	})
	# Mostrador
	Art.rrect(self, I, Rect2(80, 500, 420, 32), 8, _s(Color(0.72, 0.52, 0.3), sat))
	Art.rrect(self, I, Rect2(80, 528, 420, 40), 6, _s(Color(0.45, 0.41, 0.38), sat))
	# Clientes con su pedido
	var looks := [[Vector2(180, 690), Art.FURS[0], Art.SKINS[2], 1, "honda"], [Vector2(400, 690), Art.FURS[3], Art.SKINS[0], 3, "lanza"]]
	for l in looks:
		Art.person(self, Transform2D(0, Vector2(1.3, 1.3), 0, l[0]), {
			"t": 3.0, "outfit": _s(l[1], sat), "skin": l[2], "hair": Art.HAIRS[1], "style": l[3], "mood": 1,
		})
		var b := Rect2(l[0] + Vector2(-46, -200), Vector2(92, 56))
		Art.rrect(self, I, b, 16, Color(1, 0.98, 0.93))
		Art.weapon(self, l[4], Transform2D(0, Vector2(0.8, 0.8), 0, b.get_center()))


func _s(c: Color, k: float) -> Color:
	return Color.from_hsv(c.h, clampf(c.s * k, 0.0, 1.0), clampf(c.v * (0.9 + 0.1 * k), 0.0, 1.0))
