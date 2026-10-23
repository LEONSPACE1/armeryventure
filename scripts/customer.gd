# Cliente: entra, espera en el mostrador con su pedido, paga y se va feliz.
extends Node2D

var station_idx := 0
var remaining := 1   # armas que aún no ha recibido
var incoming := 0    # armas que un dependiente ya le está trayendo
var spot := -1
var target := Vector2.ZERO
var leaving := false
var _look: Dictionary = {}
var _t := 0.0
var _walk := 0.0
var _moving := false
var _facing := 1.0
var _hop := 0.0
var _heart := 0.0
var _wait := 0.0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_t = randf() * 10.0
	_look = {
		"outfit": Art.FURS.pick_random(), "skin": Art.SKINS.pick_random(),
		"hair": Art.HAIRS.pick_random(), "style": randi() % 4, "seed": randf() * 5.0,
	}


func needs() -> int:
	return remaining - incoming


func waiting() -> bool:
	return not leaving and position.distance_to(target) < 1.0


# Recibió un arma: salta y muestra un corazón.
func served() -> void:
	_hop = 1.0
	_heart = 1.0


func _process(delta: float) -> void:
	_t += delta
	var before := position
	position = position.move_toward(target, float(GameState.econ["velocidad_cliente"]) * delta)
	var moved := position - before
	_moving = moved.length() > 0.1
	if _moving:
		_walk += moved.length() * 0.09
		if absf(moved.x) > 0.2:
			_facing = signf(moved.x)
	elif not leaving:
		_wait += delta
	_hop = maxf(0.0, _hop - delta * 2.5)
	_heart = maxf(0.0, _heart - delta * 0.9)
	if leaving and not _moving:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var lift := sin(_hop * PI) * 26.0
	var o := _look.duplicate()
	o["t"] = _t
	o["walk"] = _walk
	o["moving"] = _moving
	o["facing"] = _facing
	o["mood"] = 1 if (_hop > 0.0 or leaving) else 0
	o["carry"] = GameState.station(station_idx)["id"] if leaving else ""
	Art.person(self, Transform2D(0, Vector2.ONE, 0, Vector2(0, -lift)), o)
	if _heart > 0.0:
		var hy := -110.0 - (1.0 - _heart) * 40.0
		Art.heart(self, Transform2D.IDENTITY, Vector2(18, hy), 9, Color(0.95, 0.3, 0.35, minf(1.0, _heart * 2.0)))
	if leaving or not waiting():
		return
	# Burbuja con el pedido, con un leve vaivén
	var I := Transform2D(0, Vector2.ONE, 0, Vector2(0, sin(_t * 2.5) * 2.0 - lift))
	var bubble := Rect2(-38, -136, 76, 46)
	Art.rrect(self, I, Rect2(bubble.position + Vector2(0, 3), bubble.size), 14, Color(0, 0, 0, 0.2))
	Art.rrect(self, I, bubble, 14, Color(1, 0.98, 0.93))
	Art.poly(self, I, PackedVector2Array([Vector2(-6, -91), Vector2(6, -91), Vector2(0, -82)]), Color(1, 0.98, 0.93))
	Art.weapon(self, GameState.station(station_idx)["id"], I * Transform2D(0, Vector2(0.62, 0.62), 0, Vector2(-14, -113)))
	var pos: Vector2 = I * Vector2(6, -105)
	draw_string(_font, pos, "x%d" % remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.3, 0.18, 0.08))
