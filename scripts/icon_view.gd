# Control que dibuja un ícono de Art (arma o símbolo) escalado a su tamaño.
extends Control

var kind := "":
	set(v):
		kind = v
		queue_redraw()
var animated := false
var _t := 0.0


func _process(delta: float) -> void:
	if animated:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if kind == "":
		return
	var k := minf(size.x, size.y) / 56.0
	Art.icon(self, kind, Transform2D(0, Vector2(k, k), 0, size / 2.0), _t)
