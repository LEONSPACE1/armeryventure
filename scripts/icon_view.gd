# Control que dibuja un ícono: la foto 3D de un arma o un símbolo de Art,
# escalado a su tamaño.
extends Control

const SYMBOLS := ["estrella", "dependiente", "clientes", "velocidad", "fila", "todo",
		"flecha", "portal", "trofeo", "engranaje", "cerrar"]

var kind := "":
	set(v):
		kind = v
		queue_redraw()
var animated := false
var _t := 0.0


func _ready() -> void:
	WeaponIcons.icon_ready.connect(func(id):
		if id == kind:
			queue_redraw())


func _process(delta: float) -> void:
	if animated:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if kind == "":
		return
	if kind not in SYMBOLS:
		var tex := WeaponIcons.texture(kind)
		if tex:
			var side := minf(size.x, size.y)
			draw_texture_rect(tex, Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side)), false)
			return
	var k := minf(size.x, size.y) / 56.0
	Art.icon(self, kind, Transform2D(0, Vector2(k, k), 0, size / 2.0), _t)
