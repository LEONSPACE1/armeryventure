# Dependiente: recoge armas en las estaciones y las lleva al cliente.
extends Node3D

const PersonScript := preload("res://scripts/person3d.gd")

enum State { FREE, TO_STATION, TO_CUSTOMER }

var state := State.FREE
var target := Vector3.ZERO
var home := Vector3.ZERO
var station = null
var customer = null
var carrying_id := ""
var carrying := false
var look_seed := 0
var _person: Node3D
var _walk := 0.0


func _ready() -> void:
	_person = PersonScript.new()
	_person.outfit = Color(0.22, 0.5, 0.62)
	_person.skin = Art.SKINS[look_seed % 4]
	_person.hair = Art.HAIRS[(look_seed + 2) % 5]
	_person.style = look_seed % 2
	_person.apron = true
	add_child(_person)


func arrived() -> bool:
	return position.distance_to(target) < 0.01


func _process(delta: float) -> void:
	if state == State.FREE:
		target = home
	var before := position
	position = position.move_toward(target, GameState.worker_speed() * delta)
	var moved := position - before
	var moving := moved.length() > 0.0005
	_person.walking = moving
	if moving:
		_walk += moved.length() * 6.0
		_person.walk_phase = _walk
		_person.face(moved, delta)
	elif state == State.FREE:
		_person.face(Vector3(0, 0, 1), delta)
	_person.carry_id = carrying_id if carrying else ""
