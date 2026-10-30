# Piezas 3D low-poly hechas con mallas básicas de Godot (sin modelos externos).
class_name Art3D

const SEGMENTS := 8
static var _mats: Dictionary = {}
static var _vc_mat: StandardMaterial3D


static func mat(c: Color, emit := 0.0) -> StandardMaterial3D:
	var key := "%s|%s" % [c.to_html(), emit]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


static func _add(parent: Node3D, mesh: Mesh, pos: Vector3, c: Color, emit := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(c, emit)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, emit := 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _add(parent, m, pos, c, emit)


static func cyl(parent: Node3D, top: float, bottom: float, h: float, pos: Vector3, c: Color, seg := SEGMENTS) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return _add(parent, m, pos, c)


static func sphere(parent: Node3D, r: float, pos: Vector3, c: Color, emit := 0.0) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 5
	return _add(parent, m, pos, c, emit)


static func torus(parent: Node3D, inner: float, outer: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 12
	m.ring_segments = 6
	return _add(parent, m, pos, c)


# Arma de la Prehistoria, a lo largo del eje Y (de -0.6 a 0.6 aprox.).
# Con baked = false las piezas quedan sueltas (para animar el ensamblaje).
static func weapon(id: String, baked := true) -> Node3D:
	var w := Node3D.new()
	var wood := Color(0.58, 0.37, 0.19)
	var stone := Color(0.62, 0.63, 0.67)
	match id:
		"lanza":
			cyl(w, 0.035, 0.04, 1.25, Vector3.ZERO, wood)
			cyl(w, 0.0, 0.085, 0.26, Vector3(0, 0.75, 0), stone, 5)
			cyl(w, 0.05, 0.05, 0.06, Vector3(0, 0.6, 0), Color(0.3, 0.2, 0.1))
		"hacha":
			cyl(w, 0.045, 0.05, 0.85, Vector3.ZERO, wood)
			var head := box(w, Vector3(0.34, 0.24, 0.09), Vector3(0.12, 0.36, 0), stone)
			head.rotation.z = 0.35
			box(w, Vector3(0.1, 0.12, 0.11), Vector3(0, 0.33, 0), Color(0.3, 0.2, 0.1))
		"honda":
			var a := cyl(w, 0.015, 0.015, 0.7, Vector3(-0.12, 0.05, 0), Color(0.82, 0.7, 0.48), 4)
			a.rotation.z = -0.35
			var b := cyl(w, 0.015, 0.015, 0.7, Vector3(0.12, 0.05, 0), Color(0.82, 0.7, 0.48), 4)
			b.rotation.z = 0.35
			var pouch := sphere(w, 0.11, Vector3(0, -0.3, 0), Color(0.5, 0.32, 0.18))
			pouch.scale = Vector3(1.2, 0.7, 1)
			sphere(w, 0.07, Vector3(0, -0.24, 0.03), stone)
		"atlatl":
			cyl(w, 0.04, 0.05, 0.75, Vector3(-0.08, -0.15, 0), wood)
			var dart := Node3D.new()
			dart.position = Vector3(0.06, 0.1, 0.04)
			dart.rotation.z = -0.15
			w.add_child(dart)
			cyl(dart, 0.02, 0.02, 1.2, Vector3.ZERO, Color(0.82, 0.68, 0.45), 5)
			cyl(dart, 0.0, 0.06, 0.18, Vector3(0, 0.68, 0), stone, 5)
			box(dart, Vector3(0.12, 0.14, 0.01), Vector3(0, -0.55, 0), Color(0.9, 0.3, 0.25))
		"arco":
			for k in 7:
				var ang := lerpf(-1.2, 1.2, k / 6.0)
				var seg := cyl(w, 0.03, 0.03, 0.24, Vector3(-cos(ang) * 0.32 + 0.15, sin(ang) * 0.55, 0), wood, 5)
				seg.rotation.z = -ang * 0.85
			cyl(w, 0.006, 0.006, 1.02, Vector3(0.12, 0, 0), Color(0.95, 0.92, 0.85), 3)
			var arrow := Node3D.new()
			arrow.rotation.z = -PI / 2
			w.add_child(arrow)
			cyl(arrow, 0.015, 0.015, 0.9, Vector3(0, 0.05, 0), Color(0.75, 0.6, 0.38), 4)
			cyl(arrow, 0.0, 0.05, 0.14, Vector3(0, 0.55, 0), stone, 4)
			box(arrow, Vector3(0.1, 0.12, 0.01), Vector3(0, -0.36, 0), Color(0.9, 0.3, 0.25))
		_:
			sphere(w, 0.2, Vector3.ZERO, stone)
	if baked:
		bake(w, true)
	return w


# Junta las piezas fijas de un nodo en una sola malla con colores por vértice.
# Así el celular dibuja una pieza en lugar de decenas (muchas menos "draw calls").
# Solo junta los MeshInstance3D hijos directos (y sus hijos malla); con deep
# también entra en los Node3D simples. Las piezas con meta "keep" se dejan sueltas.
static func bake(root: Node3D, deep := false) -> void:
	var groups := {}
	var victims: Array = []
	_collect(root, Transform3D.IDENTITY, deep, groups, victims, true)
	if victims.size() < 2:
		return
	var am := ArrayMesh.new()
	for key in groups:
		var g: Dictionary = groups[key]
		g["st"].commit(am)
		am.surface_set_material(am.get_surface_count() - 1, g["mat"])
	for v in victims:
		root.remove_child(v)
		v.queue_free()
	var mi := MeshInstance3D.new()
	mi.mesh = am
	root.add_child(mi)


static func _collect(n: Node, xf: Transform3D, deep: bool, groups: Dictionary, victims: Array, top: bool) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and not c.has_meta("keep"):
			var cx: Transform3D = xf * c.transform
			_append(c, cx, groups)
			_collect(c, cx, deep, groups, victims, false)
		elif deep and c.get_class() == "Node3D":
			_collect(c, xf * c.transform, deep, groups, victims, false)
		else:
			continue
		if top:
			victims.append(c)


static func _append(mi: MeshInstance3D, xf: Transform3D, groups: Dictionary) -> void:
	var m := mi.material_override as StandardMaterial3D
	var plain := m != null and not m.emission_enabled and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
	var key = "vc" if plain else m.get_instance_id()
	if not groups.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		groups[key] = {"st": st, "mat": _vertex_color_mat() if plain else m}
	var st: SurfaceTool = groups[key]["st"]
	var arr := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx = arr[Mesh.ARRAY_INDEX]
	if idx == null or idx.is_empty():
		idx = range(verts.size())
	var nb := xf.basis.inverse().transposed()
	st.set_color(m.albedo_color if m else Color.WHITE)
	for i in idx:
		st.set_normal((nb * norms[i]).normalized())
		st.add_vertex(xf * verts[i])


static func _vertex_color_mat() -> StandardMaterial3D:
	if _vc_mat == null:
		_vc_mat = StandardMaterial3D.new()
		_vc_mat.vertex_color_use_as_albedo = true
		_vc_mat.vertex_color_is_srgb = true
		_vc_mat.roughness = 0.85
	return _vc_mat


# Partículas de chispas (se disparan con restart()).
static func sparks(parent: Node3D, pos: Vector3, amount := 10) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var m := BoxMesh.new()
	m.size = Vector3(0.05, 0.05, 0.05)
	m.material = mat(Color(1, 0.8, 0.3), 3.0)
	p.mesh = m
	parent.add_child(p)
	return p
