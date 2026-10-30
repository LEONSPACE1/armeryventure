# Personaje low-poly articulado (piernas, brazos, cabeza) con animaciones por código.
# Mide unos 1.9 de alto, con los pies en y = 0 y mirando hacia +Z.
extends Node3D

var outfit := Color(0.62, 0.42, 0.24)
var skin := Color(0.96, 0.8, 0.65)
var hair := Color(0.2, 0.13, 0.08)
var style := 0
var apron := false
var beard := false
var with_hammer := false

# Estado que fija el dueño cada cuadro
var walking := false
var walk_phase := 0.0
var carry_id := ""
# Postura de trabajo del armero (la fija la estación cada cuadro)
enum Pose { NONE, ASSEMBLE, HAMMER, LIFT }
var pose := Pose.NONE
var pose_phase := 0.0
var happy := 0.0           # 0..1, salto de alegría

var _t := 0.0
var _seed := 0.0
var _body: Node3D
var _torso: Node3D
var _legs: Array = []
var _arms: Array = []
var _eyes: Node3D
var _carry: Node3D
var _carry_shown := ""
var _hammer: Node3D


func _ready() -> void:
	_seed = randf() * 10.0
	_t = _seed
	_body = Node3D.new()
	add_child(_body)
	var shoe := Color(0.3, 0.2, 0.12)
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.13 * side, 0.55, 0)
		_body.add_child(hip)
		Art3D.cyl(hip, 0.085, 0.075, 0.5, Vector3(0, -0.25, 0), skin.darkened(0.12), 6)
		Art3D.box(hip, Vector3(0.16, 0.08, 0.24), Vector3(0, -0.52, 0.04), shoe)
		_legs.append(hip)
	_torso = Node3D.new()
	_torso.position = Vector3(0, 0.55, 0)
	_body.add_child(_torso)
	Art3D.cyl(_torso, 0.25, 0.33, 0.62, Vector3(0, 0.31, 0), outfit)
	Art3D.cyl(_torso, 0.34, 0.38, 0.12, Vector3(0, 0.03, 0), outfit.darkened(0.25))
	Art3D.cyl(_torso, 0.29, 0.31, 0.06, Vector3(0, 0.22, 0), Color(0.3, 0.2, 0.1))
	if apron:
		Art3D.box(_torso, Vector3(0.36, 0.42, 0.04), Vector3(0, 0.2, 0.31), Color(0.93, 0.88, 0.76))
	for side in [-1.0, 1.0]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(0.33 * side, 0.55, 0)
		_torso.add_child(shoulder)
		Art3D.cyl(shoulder, 0.075, 0.065, 0.46, Vector3(0, -0.21, 0), skin, 6)
		Art3D.sphere(shoulder, 0.08, Vector3(0, -0.45, 0), skin)
		if with_hammer and side > 0:
			_hammer = Node3D.new()
			shoulder.add_child(_hammer)
			Art3D.cyl(_hammer, 0.03, 0.03, 0.4, Vector3(0, -0.5, 0.18), Color(0.45, 0.28, 0.14), 5).rotation.x = PI / 2
			Art3D.box(_hammer, Vector3(0.14, 0.14, 0.24), Vector3(0, -0.5, 0.4), Color(0.55, 0.56, 0.6))
			Art3D.bake(_hammer)
		_arms.append(shoulder)
	# Cabeza
	var head := Node3D.new()
	head.position = Vector3(0, 1.0, 0)
	_torso.add_child(head)
	Art3D.sphere(head, 0.37, Vector3.ZERO, skin)
	Art3D.sphere(head, 0.07, Vector3(0, -0.03, 0.36), skin.darkened(0.08))
	# Los dos ojos van juntos en un nodo para parpadear con una sola escala
	_eyes = Node3D.new()
	_eyes.position = Vector3(0, 0.05, 0.32)
	head.add_child(_eyes)
	for side in [-1.0, 1.0]:
		var eye := Art3D.sphere(_eyes, 0.065, Vector3(0.13 * side, 0, 0), Color(0.1, 0.07, 0.05))
		Art3D.sphere(eye, 0.025, Vector3(0.02, 0.025, 0.045), Color(1, 1, 1))
	Art3D.sphere(head, 0.06, Vector3(0.24, -0.1, 0.26), Color(0.95, 0.55, 0.5))
	Art3D.sphere(head, 0.06, Vector3(-0.24, -0.1, 0.26), Color(0.95, 0.55, 0.5))
	# Pelo: casquete más alto que la cabeza para cubrir la coronilla,
	# corrido hacia atrás para dejar libre la cara, y un flequillo.
	var cap := Art3D.sphere(head, 0.39, Vector3(0, 0.14, -0.08), hair)
	cap.scale = Vector3(1.05, 0.75, 1.0)
	var fringe := Art3D.sphere(head, 0.2, Vector3(0, 0.27, 0.17), hair)
	fringe.scale = Vector3(1.5, 0.55, 0.9)
	match style:
		1:
			Art3D.sphere(head, 0.15, Vector3(0, -0.05, -0.38), hair)
		2:
			Art3D.cyl(head, 0.42, 0.42, 0.08, Vector3(0, 0.15, -0.04), Color(0.85, 0.25, 0.2), 10)
		3:
			var f := Art3D.box(head, Vector3(0.05, 0.4, 0.02), Vector3(0.12, 0.38, -0.2), Color(0.95, 0.92, 0.85))
			f.rotation.z = -0.4
			Art3D.box(f, Vector3(0.06, 0.12, 0.025), Vector3(0, 0.16, 0), Color(0.9, 0.35, 0.25))
		4:
			# Casco cónico de bronce con cubrenuca
			var metal := Color(0.88, 0.7, 0.34)
			var helm := Art3D.sphere(head, 0.42, Vector3(0, 0.2, -0.1), metal)
			helm.scale = Vector3(1.0, 0.8, 1.0)
			Art3D.cyl(head, 0.0, 0.12, 0.22, Vector3(0, 0.6, -0.1), metal.lightened(0.2), 6)
			Art3D.cyl(head, 0.43, 0.43, 0.06, Vector3(0, 0.18, -0.1), metal.darkened(0.35), 12)
			for side in [-1.0, 1.0]:
				Art3D.box(head, Vector3(0.06, 0.22, 0.16), Vector3(0.38 * side, 0.0, 0.0), metal.darkened(0.15))
		5:
			# Pañuelo de tela atado a la cabeza
			var wrap := Art3D.sphere(head, 0.41, Vector3(0, 0.15, -0.08), Color(0.8, 0.74, 0.62))
			wrap.scale = Vector3(1.04, 0.72, 1.0)
			Art3D.cyl(head, 0.425, 0.425, 0.07, Vector3(0, 0.16, -0.04), Color(0.7, 0.25, 0.2), 10)
			Art3D.sphere(head, 0.09, Vector3(0, 0.12, -0.45), Color(0.8, 0.74, 0.62))
		6:
			# Casco griego de bronce con cimera de crin
			var gk := Color(0.86, 0.66, 0.3)
			var gh := Art3D.sphere(head, 0.42, Vector3(0, 0.18, -0.08), gk)
			gh.scale = Vector3(1.0, 0.85, 1.0)
			for side in [-1.0, 1.0]:
				Art3D.box(head, Vector3(0.07, 0.26, 0.2), Vector3(0.36 * side, -0.02, 0.06), gk.darkened(0.12))
			Art3D.box(head, Vector3(0.08, 0.16, 0.62), Vector3(0, 0.6, -0.1), Color(0.8, 0.2, 0.16))
		7:
			# Casco romano de hierro con penacho
			var rm := Color(0.7, 0.72, 0.76)
			var rh := Art3D.sphere(head, 0.41, Vector3(0, 0.17, -0.08), rm)
			rh.scale = Vector3(1.0, 0.82, 1.0)
			Art3D.box(head, Vector3(0.6, 0.06, 0.1), Vector3(0, 0.36, 0.26), rm.darkened(0.2))
			Art3D.box(head, Vector3(0.75, 0.09, 0.2), Vector3(0, -0.02, -0.36), rm.darkened(0.15))
			Art3D.box(head, Vector3(0.1, 0.2, 0.5), Vector3(0, 0.58, -0.08), Color(0.8, 0.2, 0.16))
		8:
			# Yelmo medieval con protector nasal
			var mm := Color(0.62, 0.64, 0.68)
			var mh := Art3D.sphere(head, 0.42, Vector3(0, 0.18, -0.06), mm)
			mh.scale = Vector3(1.0, 0.9, 1.0)
			Art3D.cyl(head, 0.0, 0.1, 0.14, Vector3(0, 0.6, -0.06), mm.lightened(0.15), 6)
			Art3D.box(head, Vector3(0.06, 0.24, 0.05), Vector3(0, 0.12, 0.38), mm.darkened(0.15))
			Art3D.cyl(head, 0.43, 0.43, 0.05, Vector3(0, 0.12, -0.06), mm.darkened(0.3), 12)
		9:
			# Capucha de tela
			var hood := Color(0.3, 0.45, 0.25)
			var hd := Art3D.sphere(head, 0.43, Vector3(0, 0.12, -0.1), hood)
			hd.scale = Vector3(1.05, 0.9, 1.0)
			Art3D.cyl(head, 0.0, 0.14, 0.3, Vector3(0, 0.15, -0.55), hood.darkened(0.15), 6).rotation.x = -1.2
			Art3D.torus(head, 0.33, 0.42, Vector3(0, -0.08, 0.06), hood.darkened(0.1)).rotation.x = 0.35
		10:
			# Tricornio
			var tri := Color(0.16, 0.14, 0.14)
			Art3D.cyl(head, 0.3, 0.33, 0.22, Vector3(0, 0.42, -0.04), tri, 10)
			Art3D.cyl(head, 0.56, 0.56, 0.06, Vector3(0, 0.33, -0.04), tri, 3).rotation.y = PI
			Art3D.torus(head, 0.5, 0.56, Vector3(0, 0.33, -0.04), Color(0.85, 0.7, 0.3)).scale = Vector3(1, 0.4, 1)
		11:
			# Sombrero de ala ancha con pluma
			var hat := Color(0.45, 0.25, 0.15)
			Art3D.cyl(head, 0.28, 0.32, 0.24, Vector3(0, 0.45, -0.04), hat, 10)
			Art3D.cyl(head, 0.6, 0.6, 0.04, Vector3(0, 0.34, -0.04), hat, 14)
			Art3D.cyl(head, 0.325, 0.325, 0.06, Vector3(0, 0.38, -0.04), Color(0.85, 0.7, 0.3), 10)
			var pl := Art3D.box(head, Vector3(0.06, 0.45, 0.03), Vector3(0.25, 0.6, -0.15), Color(0.95, 0.95, 0.9))
			pl.rotation.z = -0.6
		12:
			# Sombrero de copa
			var top := Color(0.13, 0.12, 0.13)
			Art3D.cyl(head, 0.27, 0.27, 0.42, Vector3(0, 0.55, -0.04), top, 12)
			Art3D.cyl(head, 0.44, 0.44, 0.04, Vector3(0, 0.34, -0.04), top, 14)
			Art3D.cyl(head, 0.275, 0.275, 0.07, Vector3(0, 0.39, -0.04), Color(0.55, 0.15, 0.15), 12)
		13:
			# Gorra plana de obrero
			var cl := Color(0.4, 0.38, 0.34)
			var fc := Art3D.sphere(head, 0.4, Vector3(0, 0.26, -0.02), cl)
			fc.scale = Vector3(1.05, 0.5, 1.1)
			var visor_flat := Art3D.box(head, Vector3(0.44, 0.03, 0.2), Vector3(0, 0.26, 0.4), cl.darkened(0.2))
			visor_flat.rotation.x = 0.25
		14:
			# Bombín
			var bw := Color(0.3, 0.2, 0.14)
			var bd := Art3D.sphere(head, 0.33, Vector3(0, 0.36, -0.04), bw)
			bd.scale = Vector3(1, 0.9, 1)
			Art3D.cyl(head, 0.46, 0.46, 0.04, Vector3(0, 0.28, -0.04), bw, 14)
		15:
			# Casco militar moderno
			var ol := Color(0.4, 0.45, 0.3)
			var mc := Art3D.sphere(head, 0.43, Vector3(0, 0.18, -0.06), ol)
			mc.scale = Vector3(1.05, 0.85, 1.05)
			Art3D.box(head, Vector3(0.24, 0.1, 0.1), Vector3(0, 0.44, 0.28), Color(0.2, 0.2, 0.22))
		16:
			# Gorra deportiva
			var gc := Color(0.2, 0.35, 0.65)
			var cp := Art3D.sphere(head, 0.4, Vector3(0, 0.2, -0.04), gc)
			cp.scale = Vector3(1.02, 0.7, 1.02)
			Art3D.box(head, Vector3(0.36, 0.03, 0.28), Vector3(0, 0.2, 0.45), gc.darkened(0.2))
		17:
			# Gorro de lana con auriculares
			var bn := Color(0.25, 0.27, 0.3)
			var bt := Art3D.sphere(head, 0.41, Vector3(0, 0.22, -0.06), bn)
			bt.scale = Vector3(1.02, 0.85, 1.02)
			Art3D.cyl(head, 0.42, 0.42, 0.1, Vector3(0, 0.1, -0.04), bn.lightened(0.1), 10)
			for side in [-1.0, 1.0]:
				Art3D.sphere(head, 0.1, Vector3(0.38 * side, -0.02, 0), Color(0.15, 0.15, 0.16))
		18:
			# Casco futurista con visor luminoso
			var wh := Color(0.9, 0.92, 0.95)
			var fh := Art3D.sphere(head, 0.43, Vector3(0, 0.16, -0.06), wh)
			fh.scale = Vector3(1.0, 0.92, 1.0)
			Art3D.box(head, Vector3(0.62, 0.11, 0.1), Vector3(0, 0.07, 0.33), Color(0.3, 0.9, 1.0), 1.2)
			Art3D.box(head, Vector3(0.06, 0.12, 0.5), Vector3(0, 0.56, -0.08), Color(0.3, 0.9, 1.0), 0.8)
		19:
			# Diadema con antena de neón
			Art3D.cyl(head, 0.41, 0.41, 0.05, Vector3(0, 0.22, -0.04), Color(0.88, 0.9, 0.93), 12)
			Art3D.cyl(head, 0.012, 0.012, 0.3, Vector3(0.3, 0.42, -0.04), Color(0.88, 0.9, 0.93), 4)
			Art3D.sphere(head, 0.05, Vector3(0.3, 0.58, -0.04), Color(0.75, 0.4, 1.0), 1.4)
	if beard:
		var b := Art3D.sphere(head, 0.25, Vector3(0, -0.22, 0.18), hair)
		b.scale = Vector3(1.1, 0.8, 0.8)
	_carry = Node3D.new()
	_carry.position = Vector3(0, 2.25, 0.05)
	_body.add_child(_carry)
	for part in _legs + _arms + [_torso, head, _eyes]:
		Art3D.bake(part)


func _process(delta: float) -> void:
	_t += delta
	happy = maxf(0.0, happy - delta * 2.5)
	var hop := sin(happy * PI) * 0.45
	if walking:
		var s := sin(walk_phase)
		_legs[0].rotation.x = s * 0.6
		_legs[1].rotation.x = -s * 0.6
		_body.position.y = absf(s) * 0.07 + hop
		_torso.scale.y = 1.0
	else:
		_legs[0].rotation.x = 0.0
		_legs[1].rotation.x = 0.0
		_body.position.y = hop
		_torso.scale.y = 1.0 + sin(_t * 2.2) * 0.02
	# Brazos: cargar arriba, martillar o balancear
	if carry_id != "":
		_arms[0].rotation.x = -2.9
		_arms[1].rotation.x = -2.9
	else:
		var swing := sin(walk_phase) * 0.5 if walking else sin(_t * 1.5 + _seed) * 0.05
		_arms[0].rotation.x = -swing
		_arms[1].rotation.x = swing
		match pose:
			Pose.ASSEMBLE:
				# Las dos manos sobre el banco, juntando piezas por turnos
				_arms[0].rotation.x = -1.05 + 0.3 * sin(pose_phase)
				_arms[1].rotation.x = -1.05 - 0.3 * sin(pose_phase)
			Pose.HAMMER:
				var raise := maxf(0.0, sin(pose_phase))
				_arms[0].rotation.x = -0.9
				_arms[1].rotation.x = lerpf(-0.6, -2.7, raise)
			Pose.LIFT:
				# Levanta el arma terminada para revisarla
				_arms[0].rotation.x = -2.0 + 0.1 * sin(pose_phase)
				_arms[1].rotation.x = -2.0 + 0.1 * sin(pose_phase)
	if _hammer:
		_hammer.visible = pose == Pose.HAMMER or pose == Pose.NONE
	if happy > 0.0:
		_arms[0].rotation.z = -0.8 * sin(happy * PI)
		_arms[1].rotation.z = 0.8 * sin(happy * PI)
	else:
		_arms[0].rotation.z = 0.0
		_arms[1].rotation.z = 0.0
	# Parpadeo
	var blink := fmod(_t, 3.6) < 0.12
	_eyes.scale.y = 0.15 if blink else 1.0
	# Arma cargada sobre la cabeza
	if carry_id != _carry_shown:
		for c in _carry.get_children():
			c.queue_free()
		if carry_id != "":
			var w := Art3D.weapon(carry_id)
			w.rotation.z = PI / 2
			w.scale = Vector3.ONE * 0.9
			_carry.add_child(w)
		_carry_shown = carry_id


# Gira suavemente para mirar en la dirección de movimiento (en el plano XZ).
func face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.001:
		return
	var target := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target, minf(1.0, delta * 12.0))
