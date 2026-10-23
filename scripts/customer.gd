# Cliente: entra, espera en el mostrador con su pedido, paga y se va.
extends Node2D

var station_idx := 0
var remaining := 1   # armas que aún no ha recibido
var incoming := 0    # armas que un dependiente ya le está trayendo
var spot := -1
var target := Vector2.ZERO
var leaving := false
var color := Color.WHITE
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	color = Color.from_hsv(randf(), 0.45, 0.85)


func needs() -> int:
	return remaining - incoming


func waiting() -> bool:
	return not leaving and position.distance_to(target) < 1.0


func _process(delta: float) -> void:
	position = position.move_toward(target, float(GameState.econ["velocidad_cliente"]) * delta)
	if leaving and position.distance_to(target) < 1.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 8), 16, color.darkened(0.25))
	draw_circle(Vector2(0, -14), 11, Color(0.96, 0.8, 0.65))
	if leaving or not waiting():
		return
	# Burbuja con el pedido
	var bubble := Rect2(-34, -70, 68, 34)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1)
	box.set_corner_radius_all(10)
	draw_style_box(box, bubble)
	draw_rect(Rect2(-26, -62, 18, 18), Color(GameState.station(station_idx)["color"]))
	draw_string(_font, Vector2(-4, -46), "x%d" % remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.15, 0.1, 0.05))
