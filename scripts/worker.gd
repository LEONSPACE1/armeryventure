# Dependiente: recoge armas en las estaciones y las lleva al cliente.
extends Node3D

const PersonScript := preload("res://scripts/person3d.gd")

enum State { FREE, TO_STATION, TO_CUSTOMER }

# Franja de la segunda fila de bancos y pasillos libres para cruzarla
const BENCH_BAND := Vector2(-2.7, -1.1)
const AISLES := [-3.6, 0.0, 3.6]

var state := State.FREE
var target := Vector3.ZERO
var waypoints: Array = []
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
	return waypoints.is_empty() and position.distance_to(target) < 0.01


# Punto al que camina ahora (un pasillo intermedio o el destino)
func goal() -> Vector3:
	return waypoints[0] if not waypoints.is_empty() else target


# Camina hasta to sin atravesar los bancos de la segunda fila.
func go(to: Vector3) -> void:
	target = to
	waypoints.clear()
	var a := position
	var lo := BENCH_BAND.x
	var hi := BENCH_BAND.y
	var crosses := (a.z < lo and to.z > hi) or (a.z > hi and to.z < lo)
	if not crosses:
		return
	var mid := (a.x + to.x) / 2.0
	var aisle: float = AISLES[0]
	for x in AISLES:
		if absf(x - mid) < absf(aisle - mid):
			aisle = x
	if a.z > hi:
		waypoints = [Vector3(aisle, 0, hi + 0.1), Vector3(aisle, 0, lo - 0.1)]
	else:
		waypoints = [Vector3(aisle, 0, lo - 0.1), Vector3(aisle, 0, hi + 0.1)]


func _process(delta: float) -> void:
	if state == State.FREE and target != home:
		go(home)
	var before := position
	position = position.move_toward(goal(), GameState.worker_speed() * delta)
	if not waypoints.is_empty() and position.distance_to(waypoints[0]) < 0.05:
		waypoints.pop_front()
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
