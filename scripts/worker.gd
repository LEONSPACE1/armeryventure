# Dependiente: recoge armas en las estaciones y las lleva al cliente.
extends Node2D

enum State { FREE, TO_STATION, TO_CUSTOMER }

var state := State.FREE
var target := Vector2.ZERO
var home := Vector2.ZERO
var station = null
var customer = null
var carrying_color := Color.WHITE
var carrying := false


func arrived() -> bool:
	return position.distance_to(target) < 1.0


func _process(delta: float) -> void:
	if state == State.FREE:
		target = home
	position = position.move_toward(target, GameState.worker_speed() * delta)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 8), 15, Color(0.2, 0.45, 0.75))
	draw_circle(Vector2(0, -13), 10, Color(0.96, 0.8, 0.65))
	if carrying:
		draw_rect(Rect2(10, -6, 14, 14), carrying_color)
