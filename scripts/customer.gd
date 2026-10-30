# Cliente: entra, espera en el mostrador con su pedido, paga y se va feliz.
extends Node3D

const PersonScript := preload("res://scripts/person3d.gd")

var station_idx := 0
var remaining := 1   # armas que aún no ha recibido
var incoming := 0    # armas que un dependiente ya le está trayendo
var spot := -1
var target := Vector3.ZERO
var leaving := false
var heart := 0.0     # tiempo del corazón que se dibuja encima
var _person: Node3D
var _walk := 0.0
var _t := 0.0


func _ready() -> void:
	_t = randf() * 10.0
	_person = PersonScript.new()
	_person.outfit = Art.FURS.pick_random()
	_person.skin = Art.SKINS.pick_random()
	_person.hair = Art.HAIRS.pick_random()
	_person.style = randi() % 4
	add_child(_person)


func goal() -> Vector3:
	return target


func needs() -> int:
	return remaining - incoming


func waiting() -> bool:
	return not leaving and position.distance_to(target) < 0.01


# Recibió un arma: salta y muestra un corazón.
func served() -> void:
	_person.happy = 1.0
	heart = 1.0


func _process(delta: float) -> void:
	_t += delta
	heart = maxf(0.0, heart - delta * 0.9)
	var before := position
	position = position.move_toward(target, float(GameState.econ["velocidad_cliente"]) * delta)
	var moved := position - before
	var moving := moved.length() > 0.0005
	_person.walking = moving
	if moving:
		_walk += moved.length() * 6.0
		_person.walk_phase = _walk
		_person.face(moved, delta)
	elif not leaving:
		_person.face(Vector3(0, 0, -1), delta)
	_person.carry_id = GameState.station(station_idx)["id"] if leaving else ""
	if leaving and not moving:
		queue_free()
