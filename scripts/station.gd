# Estación de fabricación en 3D: banco de trabajo con sus armeros.
# Los armeros fabrican solo cuando hay pedidos pendientes de esa arma.
extends Node3D

const PersonScript := preload("res://scripts/person3d.gd")

# Etapas de la fabricación según el progreso (0..1)
const ASSEMBLE_END := 0.3
const FORGE_END := 0.8
const WEAPON_SCALE := 0.7

var idx := 0
var stock := 0      # armas listas en la estación
var reserved := 0   # armas listas que un dependiente ya viene a recoger
var slots: Array = []  # progreso de cada armero (0..1), -1 = libre
var selected := false
var _t := 0.0
var _phases: Array = []
var _smiths: Array = []
# Por armero: piezas sueltas (ensamblar), arma entera (forjar y revisar) y brasas
var _parts: Array = []
var _crafting: Array = []
var _embers: Array = []
var _stock_models: Array = []
var _sparks: Array = []
var _big_sparks: CPUParticles3D
var _bench: Node3D
var _locked: Node3D
var _lock_icon: Node3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _built_unlocked := false
var _pop := 0.0


func _ready() -> void:
	_t = randf() * 10.0
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = Color(1, 0.8, 0.25, 0.5)
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var rm := CylinderMesh.new()
	rm.top_radius = 1.7
	rm.bottom_radius = 1.7
	rm.height = 0.02
	rm.radial_segments = 24
	_ring = MeshInstance3D.new()
	_ring.mesh = rm
	_ring.material_override = _ring_mat
	_ring.scale = Vector3(1, 1, 0.75)
	_ring.position = Vector3(0, 0.02, -0.2)
	add_child(_ring)
	_big_sparks = Art3D.sparks(self, Vector3(0, 1.2, 0), 30)
	_rebuild()


func _rebuild() -> void:
	for n in [_bench, _locked]:
		if n:
			n.queue_free()
	_bench = null
	_locked = null
	_lock_icon = null
	_smiths.clear()
	_parts.clear()
	_crafting.clear()
	_embers.clear()
	_sparks.clear()
	_stock_models.clear()
	_built_unlocked = GameState.is_unlocked(idx)
	if _built_unlocked:
		_build_bench()
	else:
		_build_locked()


func _build_bench() -> void:
	_bench = Node3D.new()
	add_child(_bench)
	var accent := Color(GameState.station(idx)["color"])
	var wood := Color(0.52, 0.35, 0.2)
	Art3D.box(_bench, Vector3(2.3, 0.85, 0.9), Vector3(0, 0.43, 0), wood.darkened(0.15))
	Art3D.box(_bench, Vector3(2.45, 0.12, 1.05), Vector3(0, 0.91, 0), wood)
	for x in [-0.6, 0.0, 0.6]:
		Art3D.box(_bench, Vector3(0.03, 0.8, 0.02), Vector3(x, 0.43, 0.455), wood.darkened(0.35))
	Art3D.box(_bench, Vector3(2.32, 0.12, 0.03), Vector3(0, 0.72, 0.46), accent)
	Art3D.box(_bench, Vector3(0.45, 0.28, 0.4), Vector3(-0.85, 1.11, -0.1), Color(0.5, 0.5, 0.53))
	for k in 4:
		var w := Art3D.weapon(GameState.station(idx)["id"])
		w.rotation = Vector3(PI / 2, 0, PI / 2 + 0.15 * k)
		w.position = Vector3(0.75, 1.0 + k * 0.05, 0.3 - k * 0.1)
		w.scale = Vector3.ONE * 0.45
		w.visible = false
		_bench.add_child(w)
		_stock_models.append(w)
	Art3D.bake(_bench)


func _build_locked() -> void:
	_locked = Node3D.new()
	add_child(_locked)
	var ghost := Color(0.35, 0.31, 0.28, 0.55)
	Art3D.box(_locked, Vector3(2.3, 0.85, 0.9), Vector3(0, 0.43, 0), ghost)
	Art3D.box(_locked, Vector3(2.45, 0.12, 1.05), Vector3(0, 0.91, 0), ghost)
	_lock_icon = Node3D.new()
	_lock_icon.position = Vector3(0, 1.55, 0.2)
	_locked.add_child(_lock_icon)
	Art3D.box(_lock_icon, Vector3(0.5, 0.4, 0.2), Vector3.ZERO, Color(0.9, 0.68, 0.2))
	var shackle := Art3D.torus(_lock_icon, 0.11, 0.17, Vector3(0, 0.22, 0), Color(0.75, 0.75, 0.78))
	shackle.rotation.x = PI / 2
	Art3D.box(_lock_icon, Vector3(0.08, 0.14, 0.04), Vector3(0, -0.02, 0.1), Color(0.35, 0.22, 0.05))
	Art3D.bake(_locked)
	Art3D.bake(_lock_icon)


func _armero_x(i: int, n: int) -> float:
	return (i - (n - 1) / 2.0) * minf(0.7, 1.8 / maxf(n, 1)) - 0.1


func _sync_smiths() -> void:
	var n := GameState.armeros(idx)
	while slots.size() < n:
		slots.append(-1.0)
		_phases.append(randf() * TAU)
	if _smiths.size() == n:
		return
	for list in [_smiths, _parts, _crafting, _embers, _sparks]:
		for node in list:
			node.queue_free()
		list.clear()
	for i in n:
		var x := _armero_x(i, n)
		var p := PersonScript.new()
		p.outfit = Color(GameState.theme("ropa_armeros", "#8c5230"))
		p.skin = Art.SKINS[(idx + i) % 4]
		p.hair = Art.HAIRS[(idx * 2 + i) % 5]
		p.style = int(GameState.theme("estilo_armeros", 2))
		p.beard = (idx + i) % 2 == 0
		p.with_hammer = true
		p.position = Vector3(x, 0, -0.85)
		p.scale = Vector3.ONE * 0.95
		_bench.add_child(p)
		_smiths.append(p)
		var id: String = GameState.station(idx)["id"]
		for baked in [false, true]:
			var w := Art3D.weapon(id, baked)
			w.rotation = Vector3(PI / 2, 0, PI / 2)
			w.position = _rest_point(x)
			w.scale = Vector3.ONE * WEAPON_SCALE
			w.visible = false
			_bench.add_child(w)
			(_crafting if baked else _parts).append(w)
		var ember := Art3D.sphere(_bench, 0.16, _rest_point(x) + Vector3(0, -0.05, 0), Color(0.95, 0.35, 0.05), 0.9)
		ember.scale = Vector3(1.8, 0.25, 1.1)
		ember.visible = false
		_embers.append(ember)
		_sparks.append(Art3D.sparks(_bench, _rest_point(x) + Vector3(0, 0.05, 0), 8))


# Donde se apoya el arma que fabrica el armero de la posición x
func _rest_point(x: float) -> Vector3:
	return Vector3(x + 0.1, 1.02, 0.05)


func free_stock() -> int:
	return stock - reserved


func crafting_count() -> int:
	var n := 0
	for s in slots:
		if s >= 0.0:
			n += 1
	return n


func pickup_point(offset_x := 0.0) -> Vector3:
	return position + Vector3(offset_x, 0, 0.95)


func tick(delta: float, demand: int) -> void:
	_t += delta
	_pop = maxf(0.0, _pop - delta * 3.5)
	scale = Vector3.ONE * (1.0 + 0.1 * sin(_pop * PI))
	_ring.visible = selected
	if selected:
		_ring_mat.albedo_color.a = 0.25 + 0.2 * sin(_t * 5.0)
	if GameState.is_unlocked(idx) != _built_unlocked:
		_rebuild()
	if not GameState.is_unlocked(idx):
		if _lock_icon:
			_lock_icon.position.y = 1.55 + (sin(_t * 3.0) * 0.08 if GameState.can_unlock(idx) else 0.0)
			_lock_icon.rotation.y = sin(_t * 1.5) * 0.3
		return
	_sync_smiths()
	var t := GameState.craft_time(idx)
	for i in slots.size():
		if slots[i] < 0.0 and free_stock() + crafting_count() < demand:
			slots[i] = 0.0
		if slots[i] >= 0.0:
			slots[i] += delta / t
			if slots[i] >= 1.0:
				slots[i] = -1.0
				stock += 1
		_animate_smith(i, delta)
	for k in _stock_models.size():
		var show := k < stock
		if show and not _stock_models[k].visible:
			# El arma terminada "cae" en la pila con un rebote
			_stock_models[k].scale = Vector3.ONE * 0.1
			_stock_models[k].create_tween().tween_property(_stock_models[k], "scale", Vector3.ONE * 0.45, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_stock_models[k].visible = show


# Animación del armero i según la etapa: ensamblar piezas, forjar a martillazos
# sobre las brasas y levantar el arma terminada para revisarla.
func _animate_smith(i: int, delta: float) -> void:
	var p: float = slots[i]
	var smith = _smiths[i]
	var parts: Node3D = _parts[i]
	var whole: Node3D = _crafting[i]
	var ember: Node3D = _embers[i]
	var rest := _rest_point(smith.position.x)
	parts.visible = p >= 0.0 and p < ASSEMBLE_END
	whole.visible = p >= ASSEMBLE_END
	ember.visible = p >= ASSEMBLE_END and p < FORGE_END
	if p < 0.0:
		smith.pose = PersonScript.Pose.NONE
		return
	smith.pose_phase = _phases[i]
	if p < ASSEMBLE_END:
		# Las piezas aparecen una tras otra con un pequeño salto
		_phases[i] += delta * 7.0
		smith.pose = PersonScript.Pose.ASSEMBLE
		var n := parts.get_child_count()
		var shown := p / ASSEMBLE_END * n
		for k in n:
			var piece: Node3D = parts.get_child(k)
			var grow := clampf((shown - k) * 2.5, 0.0, 1.0)
			piece.visible = grow > 0.0
			piece.scale = Vector3.ONE * (grow * (1.0 + 0.3 * sin(grow * PI)))
	elif p < FORGE_END:
		var before := sin(_phases[i])
		_phases[i] += delta * 9.0
		smith.pose = PersonScript.Pose.HAMMER
		var hit := before > 0.0 and sin(_phases[i]) <= 0.0
		if hit:
			_sparks[i].restart()
		# Cada golpe aplasta un poco el arma y aviva las brasas
		var squash := maxf(0.0, -sin(_phases[i])) * 0.15
		whole.position = rest
		whole.rotation = Vector3(PI / 2, 0, PI / 2)
		whole.scale = Vector3(1.0 + squash, 1.0, 1.0 - squash) * WEAPON_SCALE
		var glow := 0.8 + 0.4 * maxf(0.0, -sin(_phases[i]))
		ember.scale = Vector3(1.8 * glow, 0.25, 1.1 * glow)
	else:
		_phases[i] += delta * 3.0
		smith.pose = PersonScript.Pose.LIFT
		var k := smoothstep(FORGE_END, FORGE_END + 0.08, p)
		whole.position = rest.lerp(Vector3(smith.position.x, 1.85, -0.3), k)
		whole.rotation = Vector3(PI / 2 * (1.0 - k), (p - FORGE_END) * 18.0 * k, PI / 2 * (1.0 - k) + 0.25 * k)
		whole.scale = Vector3.ONE * WEAPON_SCALE


# Toque del jugador: adelanta el trabajo de todos los armeros activos.
func boost(amount: float) -> void:
	_pop = maxf(_pop, 0.5)
	for i in slots.size():
		if slots[i] >= 0.0:
			slots[i] = minf(slots[i] + amount, 0.999)
			if i < _sparks.size():
				_sparks[i].restart()


# Subida de nivel o desbloqueo: rebote y chispas.
func celebrate() -> void:
	_pop = 1.0
	_big_sparks.restart()
