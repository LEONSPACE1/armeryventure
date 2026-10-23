# Dependiente: recoge armas en las estaciones y las lleva al cliente.
extends Node2D

enum State { FREE, TO_STATION, TO_CUSTOMER }

var state := State.FREE
var target := Vector2.ZERO
var home := Vector2.ZERO
var station = null
var customer = null
var carrying_id := ""
var carrying := false
var look_seed := 0
var _t := 0.0
var _walk := 0.0
var _moving := false
var _facing := 1.0


func _ready() -> void:
	_t = randf() * 10.0


func arrived() -> bool:
	return position.distance_to(target) < 1.0


func _process(delta: float) -> void:
	_t += delta
	if state == State.FREE:
		target = home
	var before := position
	position = position.move_toward(target, GameState.worker_speed() * delta)
	var moved := position - before
	_moving = moved.length() > 0.1
	if _moving:
		_walk += moved.length() * 0.1
		if absf(moved.x) > 0.2:
			_facing = signf(moved.x)
	queue_redraw()


func _draw() -> void:
	Art.person(self, Transform2D.IDENTITY, {
		"t": _t, "walk": _walk, "moving": _moving, "facing": _facing,
		"outfit": Color(0.22, 0.5, 0.62), "skin": Art.SKINS[look_seed % 4],
		"hair": Art.HAIRS[(look_seed + 2) % 5], "style": look_seed % 2, "apron": true,
		"carry": carrying_id if carrying else "", "mood": 1 if carrying else 0, "seed": float(look_seed),
	})
