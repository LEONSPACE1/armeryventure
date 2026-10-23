# Mostrador de piedra y madera donde esperan los clientes.
extends Node2D

const HALF := 250.0


func _draw() -> void:
	var I := Transform2D.IDENTITY
	Art.ellipse(self, I, Vector2(0, 34), HALF + 20, 14, Color(0, 0, 0, 0.3))
	# Cara superior (tabla) y cara frontal (piedras)
	Art.rrect(self, I, Rect2(-HALF, -26, HALF * 2, 26), 8, Color(0.72, 0.52, 0.3))
	Art.line(self, I, Vector2(-HALF + 10, -20), Vector2(HALF - 10, -20), Color(0.85, 0.66, 0.42), 3)
	Art.rrect(self, I, Rect2(-HALF, -4, HALF * 2, 34), 6, Color(0.42, 0.38, 0.35))
	var x := -HALF + 6.0
	var row := 0
	while x < HALF - 20:
		var w := 44.0 + fmod(x * 7.3, 18.0)
		Art.rrect(self, I, Rect2(x, 0 + row % 2 * 13, minf(w, HALF - 6 - x), 12), 5, Color(0.52, 0.48, 0.45))
		x += w + 4.0
		row += 1
	# Detalles: cuenco de monedas y una piel
	Art.ellipse(self, I, Vector2(HALF - 40, -24), 20, 7, Color(0.38, 0.24, 0.12))
	for k in 4:
		Art.circle(self, I, Vector2(HALF - 50 + k * 7, -28 - (k % 2) * 3), 5, Color(1, 0.8, 0.25))
	Art.poly(self, I, PackedVector2Array([Vector2(-HALF + 20, -26), Vector2(-HALF + 70, -30), Vector2(-HALF + 84, -16), Vector2(-HALF + 40, -8), Vector2(-HALF + 10, -14)]), Color(0.8, 0.68, 0.5))
