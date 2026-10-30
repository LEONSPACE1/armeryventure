# Piezas 3D low-poly hechas con mallas básicas de Godot (sin modelos externos).
class_name Art3D

const SEGMENTS := 8
const BRONZE := Color(0.8, 0.52, 0.22)
const IRON := Color(0.6, 0.62, 0.66)
const DARK_IRON := Color(0.3, 0.31, 0.34)
const STEEL := Color(0.78, 0.8, 0.84)
const OLIVE := Color(0.4, 0.45, 0.3)
const POLYMER := Color(0.18, 0.19, 0.21)
const NEON := Color(0.3, 0.9, 1.0)
const PLASMA := Color(0.75, 0.4, 1.0)
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


# Arma de cualquier época, a lo largo del eje Y (de -0.6 a 0.6 aprox.).
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
		# --- Edad del Bronce ---
		"daga":
			var blade := cyl(w, 0.0, 0.09, 0.55, Vector3(0, 0.22, 0), BRONZE, 4)
			blade.scale.z = 0.3
			box(w, Vector3(0.26, 0.05, 0.07), Vector3(0, -0.07, 0), BRONZE.darkened(0.25))
			cyl(w, 0.035, 0.04, 0.22, Vector3(0, -0.2, 0), Color(0.35, 0.22, 0.12), 6)
			sphere(w, 0.055, Vector3(0, -0.33, 0), BRONZE.darkened(0.2))
		"hacha_bronce":
			cyl(w, 0.04, 0.045, 1.0, Vector3.ZERO, wood)
			var axe := box(w, Vector3(0.32, 0.2, 0.05), Vector3(0.16, 0.36, 0), BRONZE)
			axe.rotation.z = -0.15
			var edge := cyl(w, 0.16, 0.16, 0.05, Vector3(0.3, 0.36, 0), BRONZE.lightened(0.15), 8)
			edge.rotation.x = PI / 2
			edge.scale = Vector3(0.5, 1, 1.25)
			box(w, Vector3(0.1, 0.24, 0.1), Vector3(0, 0.36, 0), BRONZE.darkened(0.25))
		"escudo":
			var leather := Color(0.55, 0.36, 0.2)
			var disc := cyl(w, 0.45, 0.45, 0.07, Vector3.ZERO, leather, 12)
			disc.rotation.x = PI / 2
			var rim := torus(w, 0.4, 0.47, Vector3.ZERO, BRONZE)
			rim.rotation.x = PI / 2
			sphere(w, 0.12, Vector3(0, 0, 0.05), BRONZE.lightened(0.1))
			for k in 4:
				var ang := k * PI / 2 + PI / 4
				sphere(w, 0.035, Vector3(cos(ang) * 0.28, sin(ang) * 0.28, 0.04), BRONZE)
		"jabalina":
			cyl(w, 0.025, 0.03, 1.4, Vector3(0, -0.1, 0), Color(0.68, 0.5, 0.3), 6)
			var tip := cyl(w, 0.0, 0.07, 0.28, Vector3(0, 0.74, 0), BRONZE, 4)
			tip.scale.z = 0.45
			cyl(w, 0.04, 0.04, 0.16, Vector3(0, 0.0, 0), Color(0.85, 0.75, 0.55), 6)
		"espada":
			var long := cyl(w, 0.03, 0.1, 0.95, Vector3(0, 0.38, 0), BRONZE, 4)
			long.scale.z = 0.3
			box(w, Vector3(0.03, 0.85, 0.035), Vector3(0, 0.36, 0), BRONZE.lightened(0.2))
			box(w, Vector3(0.3, 0.06, 0.08), Vector3(0, -0.12, 0), BRONZE.darkened(0.25))
			cyl(w, 0.04, 0.045, 0.24, Vector3(0, -0.27, 0), Color(0.3, 0.2, 0.12), 6)
			sphere(w, 0.06, Vector3(0, -0.41, 0), BRONZE.darkened(0.2))
		# --- Antigüedad clásica ---
		"dory":
			cyl(w, 0.03, 0.035, 1.35, Vector3(0, -0.05, 0), wood, 6)
			var leaf := cyl(w, 0.0, 0.08, 0.3, Vector3(0, 0.77, 0), IRON, 4)
			leaf.scale.z = 0.35
			cyl(w, 0.04, 0.03, 0.1, Vector3(0, 0.58, 0), IRON.darkened(0.2), 6)
			cyl(w, 0.03, 0.04, 0.14, Vector3(0, -0.76, 0), BRONZE, 4)
		"aspis":
			var face := cyl(w, 0.48, 0.48, 0.08, Vector3.ZERO, Color(0.72, 0.18, 0.14), 14)
			face.rotation.x = PI / 2
			var brim := torus(w, 0.44, 0.52, Vector3.ZERO, BRONZE)
			brim.rotation.x = PI / 2
			# lambda (Λ) espartana en el frente
			var l1 := box(w, Vector3(0.06, 0.5, 0.02), Vector3(-0.09, -0.02, 0.05), BRONZE.lightened(0.2))
			l1.rotation.z = -0.38
			var l2 := box(w, Vector3(0.06, 0.5, 0.02), Vector3(0.09, -0.02, 0.05), BRONZE.lightened(0.2))
			l2.rotation.z = 0.38
		"gladius":
			box(w, Vector3(0.13, 0.62, 0.03), Vector3(0, 0.26, 0), IRON)
			var gtip := cyl(w, 0.0, 0.092, 0.16, Vector3(0, 0.65, 0), IRON, 4)
			gtip.scale.z = 0.22
			box(w, Vector3(0.24, 0.07, 0.1), Vector3(0, -0.08, 0), Color(0.85, 0.8, 0.68))
			cyl(w, 0.04, 0.045, 0.2, Vector3(0, -0.21, 0), Color(0.75, 0.66, 0.5), 6)
			sphere(w, 0.075, Vector3(0, -0.36, 0), Color(0.85, 0.8, 0.68))
		"pilum":
			cyl(w, 0.035, 0.04, 0.85, Vector3(0, -0.3, 0), wood, 6)
			cyl(w, 0.012, 0.012, 0.6, Vector3(0, 0.4, 0), IRON, 4)
			cyl(w, 0.0, 0.035, 0.12, Vector3(0, 0.76, 0), IRON.lightened(0.15), 4)
			box(w, Vector3(0.09, 0.12, 0.09), Vector3(0, 0.12, 0), IRON.darkened(0.25))
		"balista":
			box(w, Vector3(0.16, 1.1, 0.12), Vector3.ZERO, wood)
			for sx in [-1, 1]:
				var arm := box(w, Vector3(0.45, 0.06, 0.06), Vector3(sx * 0.28, 0.32, 0), wood.darkened(0.2))
				arm.rotation.z = sx * 0.3
				cyl(w, 0.07, 0.07, 0.2, Vector3(sx * 0.1, 0.38, 0), Color(0.45, 0.3, 0.2), 6)
			cyl(w, 0.006, 0.006, 0.9, Vector3(0, 0.0, 0.06), Color(0.95, 0.9, 0.8), 3)
			cyl(w, 0.02, 0.02, 0.9, Vector3(0, 0.2, 0.09), Color(0.75, 0.6, 0.38), 4)
			cyl(w, 0.0, 0.05, 0.14, Vector3(0, 0.71, 0.09), IRON, 4)
		# --- Edad Media ---
		"arco_largo":
			# segmentos tangentes a una elipse de radios 0.24 x 0.66
			for k in 11:
				var ang := lerpf(-1.2, 1.2, k / 10.0)
				var seg := cyl(w, 0.026, 0.026, 0.17, Vector3(-cos(ang) * 0.24 + 0.1, sin(ang) * 0.66, 0), Color(0.7, 0.5, 0.26), 5)
				seg.rotation.z = atan2(-0.24 * sin(ang), 0.66 * cos(ang))
			cyl(w, 0.005, 0.005, 1.26, Vector3(0.08, 0, 0), Color(0.95, 0.92, 0.85), 3)
			box(w, Vector3(0.07, 0.16, 0.07), Vector3(-0.14, 0, 0), Color(0.3, 0.2, 0.12))
		"cota":
			var mail := Color(0.66, 0.68, 0.72)
			box(w, Vector3(0.62, 0.7, 0.14), Vector3(0, 0.0, 0), mail)
			for sx in [-1, 1]:
				var sl := box(w, Vector3(0.24, 0.2, 0.13), Vector3(sx * 0.38, 0.22, 0), mail)
				sl.rotation.z = sx * -0.5
			for row in 5:
				box(w, Vector3(0.63, 0.025, 0.15), Vector3(0, -0.28 + row * 0.14, 0), mail.darkened(0.2))
			box(w, Vector3(0.24, 0.08, 0.15), Vector3(0, 0.36, 0), Color(0.45, 0.3, 0.18))
		"ballesta":
			box(w, Vector3(0.1, 1.0, 0.1), Vector3(0, -0.1, 0), wood)
			var bow := cyl(w, 0.025, 0.025, 0.85, Vector3(0, 0.3, 0), IRON, 6)
			bow.rotation.z = PI / 2
			cyl(w, 0.005, 0.005, 0.8, Vector3(0, 0.18, 0.04), Color(0.95, 0.9, 0.8), 3)
			box(w, Vector3(0.03, 0.4, 0.03), Vector3(0, 0.3, 0.07), Color(0.75, 0.6, 0.38))
			cyl(w, 0.0, 0.035, 0.1, Vector3(0, 0.55, 0.07), IRON, 4)
			box(w, Vector3(0.05, 0.14, 0.05), Vector3(0, -0.35, -0.08), IRON.darkened(0.3))
		"espada_larga":
			var lb := cyl(w, 0.02, 0.08, 1.0, Vector3(0, 0.4, 0), STEEL, 4)
			lb.scale.z = 0.25
			box(w, Vector3(0.022, 0.9, 0.03), Vector3(0, 0.38, 0), STEEL.darkened(0.2))
			box(w, Vector3(0.42, 0.06, 0.07), Vector3(0, -0.12, 0), IRON.darkened(0.2))
			cyl(w, 0.035, 0.04, 0.3, Vector3(0, -0.3, 0), Color(0.3, 0.16, 0.1), 6)
			sphere(w, 0.065, Vector3(0, -0.48, 0), IRON.darkened(0.2))
		"armadura":
			var plate := STEEL
			var torso := cyl(w, 0.26, 0.3, 0.62, Vector3(0, 0.0, 0), plate, 10)
			torso.scale.z = 0.7
			cyl(w, 0.27, 0.22, 0.14, Vector3(0, -0.36, 0), plate.darkened(0.15), 10)
			for sx in [-1, 1]:
				var pau := sphere(w, 0.16, Vector3(sx * 0.32, 0.26, 0), plate.darkened(0.08))
				pau.scale = Vector3(1, 0.7, 0.9)
			box(w, Vector3(0.03, 0.55, 0.03), Vector3(0, 0.0, 0.2), plate.lightened(0.2))
			cyl(w, 0.13, 0.15, 0.1, Vector3(0, 0.36, 0), Color(0.6, 0.16, 0.14), 10)
		# --- Pólvora ---
		"lanza_fuego":
			cyl(w, 0.03, 0.035, 1.1, Vector3(0, -0.15, 0), wood, 6)
			cyl(w, 0.07, 0.07, 0.35, Vector3(0, 0.45, 0), Color(0.82, 0.72, 0.42), 8)
			for k in 3:
				cyl(w, 0.075, 0.075, 0.03, Vector3(0, 0.33 + k * 0.12, 0), Color(0.6, 0.15, 0.12), 8)
			cyl(w, 0.0, 0.05, 0.16, Vector3(0, 0.7, 0), IRON, 4)
		"canon_mano":
			cyl(w, 0.07, 0.085, 0.55, Vector3(0, 0.3, 0), BRONZE.darkened(0.1), 8)
			cyl(w, 0.09, 0.09, 0.05, Vector3(0, 0.56, 0), BRONZE.darkened(0.25), 8)
			cyl(w, 0.03, 0.035, 0.75, Vector3(0, -0.32, 0), wood, 6)
			sphere(w, 0.03, Vector3(0, 0.12, 0.08), Color(0.2, 0.18, 0.16))
		"arcabuz":
			cyl(w, 0.03, 0.035, 0.85, Vector3(0, 0.32, 0), DARK_IRON, 6)
			var stock := box(w, Vector3(0.1, 0.55, 0.08), Vector3(0.02, -0.28, 0), wood)
			stock.rotation.z = -0.12
			box(w, Vector3(0.13, 0.2, 0.09), Vector3(0.06, -0.6, 0), wood.darkened(0.15))
			var match_lock := box(w, Vector3(0.02, 0.12, 0.02), Vector3(0.07, 0.02, 0.03), IRON)
			match_lock.rotation.z = 0.6
		"mosquete":
			cyl(w, 0.026, 0.03, 0.95, Vector3(0, 0.3, 0), STEEL.darkened(0.15), 6)
			box(w, Vector3(0.08, 0.6, 0.07), Vector3(0, -0.05, -0.02), wood)
			var mstock := box(w, Vector3(0.12, 0.32, 0.08), Vector3(0.04, -0.5, -0.02), wood.darkened(0.1))
			mstock.rotation.z = -0.15
			for k in 3:
				cyl(w, 0.036, 0.036, 0.025, Vector3(0, 0.05 + k * 0.22, 0), Color(0.82, 0.72, 0.42), 6)
			box(w, Vector3(0.04, 0.08, 0.04), Vector3(0.05, -0.18, 0.03), IRON)
		"canon":
			cyl(w, 0.11, 0.17, 0.85, Vector3(0, 0.22, 0), DARK_IRON, 10)
			cyl(w, 0.14, 0.14, 0.05, Vector3(0, 0.62, 0), DARK_IRON.lightened(0.1), 10)
			sphere(w, 0.15, Vector3(0, -0.22, 0), DARK_IRON)
			for sx in [-1, 1]:
				var wheel := cyl(w, 0.22, 0.22, 0.05, Vector3(sx * 0.22, -0.32, 0), wood, 10)
				wheel.rotation.z = PI / 2
		# --- Revolución Industrial ---
		"rifle_avancarga":
			cyl(w, 0.022, 0.025, 0.9, Vector3(0, 0.35, 0), STEEL.darkened(0.2), 6)
			box(w, Vector3(0.07, 0.65, 0.06), Vector3(0, 0.0, -0.02), wood.lightened(0.05))
			var rs := box(w, Vector3(0.11, 0.3, 0.07), Vector3(0.03, -0.45, -0.02), wood)
			rs.rotation.z = -0.15
			cyl(w, 0.008, 0.008, 0.75, Vector3(0.04, 0.3, -0.01), STEEL, 3)
			box(w, Vector3(0.04, 0.06, 0.04), Vector3(0.05, -0.15, 0.03), Color(0.82, 0.72, 0.42))
		"revolver":
			cyl(w, 0.035, 0.035, 0.42, Vector3(0, 0.3, 0), DARK_IRON, 8)
			box(w, Vector3(0.03, 0.4, 0.05), Vector3(-0.03, 0.29, 0), DARK_IRON.lightened(0.1))
			cyl(w, 0.085, 0.085, 0.17, Vector3(0, 0.02, 0), STEEL.darkened(0.25), 6)
			var grip := box(w, Vector3(0.1, 0.3, 0.07), Vector3(0.1, -0.22, 0), Color(0.42, 0.24, 0.12))
			grip.rotation.z = 0.6
			torus(w, 0.04, 0.06, Vector3(-0.05, -0.16, 0), STEEL.darkened(0.2))
		"bayoneta":
			var bb := cyl(w, 0.0, 0.07, 0.7, Vector3(0, 0.3, 0), STEEL, 3)
			bb.scale.z = 0.4
			torus(w, 0.025, 0.045, Vector3(0, -0.07, 0), STEEL.darkened(0.2))
			cyl(w, 0.035, 0.035, 0.2, Vector3(0, -0.2, 0), STEEL.darkened(0.3), 6)
			box(w, Vector3(0.16, 0.04, 0.05), Vector3(0, -0.06, 0), STEEL.darkened(0.25))
		"rifle_cerrojo":
			cyl(w, 0.022, 0.026, 0.85, Vector3(0, 0.38, 0), DARK_IRON, 6)
			box(w, Vector3(0.08, 0.7, 0.07), Vector3(0, 0.0, -0.02), wood)
			var cs := box(w, Vector3(0.12, 0.3, 0.08), Vector3(0.04, -0.45, -0.02), wood.darkened(0.1))
			cs.rotation.z = -0.18
			var boltk := cyl(w, 0.012, 0.012, 0.12, Vector3(0.08, -0.06, 0.03), STEEL, 4)
			boltk.rotation.z = PI / 2
			sphere(w, 0.025, Vector3(0.14, -0.06, 0.03), STEEL)
			box(w, Vector3(0.05, 0.1, 0.04), Vector3(-0.02, -0.08, -0.08), DARK_IRON)
		"ametralladora":
			cyl(w, 0.07, 0.07, 0.65, Vector3(0, 0.25, 0), Color(0.36, 0.4, 0.3), 8)
			cyl(w, 0.025, 0.025, 0.25, Vector3(0, 0.68, 0), DARK_IRON, 6)
			box(w, Vector3(0.16, 0.3, 0.14), Vector3(0, -0.2, 0), DARK_IRON)
			box(w, Vector3(0.22, 0.06, 0.04), Vector3(0.14, -0.15, 0.04), Color(0.82, 0.72, 0.42))
			for sx in [-1, 1]:
				var leg := cyl(w, 0.018, 0.018, 0.5, Vector3(sx * 0.16, -0.45, 0), DARK_IRON, 4)
				leg.rotation.z = sx * 0.4
		# --- Era moderna ---
		"casco":
			var shell := sphere(w, 0.3, Vector3(0, 0.0, 0), OLIVE)
			shell.scale = Vector3(1.1, 0.8, 1.15)
			cyl(w, 0.35, 0.35, 0.04, Vector3(0, -0.06, 0), OLIVE.darkened(0.15), 12)
			box(w, Vector3(0.04, 0.2, 0.03), Vector3(0, -0.18, 0.3), Color(0.25, 0.22, 0.18))
		"chaleco":
			box(w, Vector3(0.6, 0.72, 0.16), Vector3.ZERO, Color(0.25, 0.27, 0.3))
			for k in 3:
				box(w, Vector3(0.14, 0.16, 0.06), Vector3(-0.18 + k * 0.18, -0.12, 0.1), OLIVE)
			box(w, Vector3(0.48, 0.18, 0.04), Vector3(0, 0.12, 0.09), Color(0.2, 0.22, 0.24))
			for sx in [-1, 1]:
				box(w, Vector3(0.12, 0.16, 0.14), Vector3(sx * 0.22, 0.42, 0), Color(0.25, 0.27, 0.3))
		"rifle_asalto":
			cyl(w, 0.02, 0.022, 0.35, Vector3(0, 0.6, 0), POLYMER, 6)
			box(w, Vector3(0.09, 0.45, 0.07), Vector3(0, 0.25, 0), POLYMER)
			var mag := box(w, Vector3(0.07, 0.24, 0.05), Vector3(0.12, 0.04, 0), POLYMER.lightened(0.1))
			mag.rotation.z = 0.35
			var pg := box(w, Vector3(0.06, 0.14, 0.05), Vector3(0.08, -0.12, 0), POLYMER)
			pg.rotation.z = 0.3
			box(w, Vector3(0.08, 0.32, 0.06), Vector3(0.01, -0.28, 0), OLIVE.darkened(0.3))
			box(w, Vector3(0.03, 0.22, 0.04), Vector3(-0.07, 0.3, 0), POLYMER.lightened(0.15))
		"visor":
			cyl(w, 0.055, 0.055, 0.7, Vector3(0, 0.0, 0), POLYMER, 10)
			cyl(w, 0.085, 0.07, 0.14, Vector3(0, 0.38, 0), POLYMER, 10)
			cyl(w, 0.07, 0.07, 0.01, Vector3(0, 0.455, 0), Color(0.3, 0.6, 0.85), 10)
			cyl(w, 0.07, 0.06, 0.12, Vector3(0, -0.38, 0), POLYMER, 10)
			box(w, Vector3(0.06, 0.08, 0.06), Vector3(-0.08, 0.05, 0), POLYMER.lightened(0.1))
		"dron":
			box(w, Vector3(0.24, 0.24, 0.1), Vector3.ZERO, Color(0.85, 0.86, 0.88))
			for k in 4:
				var ang := k * PI / 2 + PI / 4
				var dir := Vector3(cos(ang), sin(ang), 0)
				var armd := box(w, Vector3(0.42, 0.04, 0.04), dir * 0.2, POLYMER)
				armd.rotation.z = ang
				var rotor := cyl(w, 0.13, 0.13, 0.01, dir * 0.4 + Vector3(0, 0, 0.05), Color(0.2, 0.2, 0.22, 0.6), 10)
				rotor.rotation.x = PI / 2
			sphere(w, 0.05, Vector3(0, -0.1, 0.06), Color(0.15, 0.4, 0.7))
		# --- Futurista ---
		"pistola_laser":
			box(w, Vector3(0.12, 0.42, 0.08), Vector3(0, 0.18, 0), Color(0.9, 0.92, 0.95))
			cyl(w, 0.03, 0.045, 0.16, Vector3(0, 0.46, 0), NEON, 8)
			box(w, Vector3(0.04, 0.3, 0.09), Vector3(-0.05, 0.2, 0), NEON, 1.2)
			var lg := box(w, Vector3(0.1, 0.28, 0.07), Vector3(0.1, -0.12, 0), POLYMER)
			lg.rotation.z = 0.45
		"escudo_energia":
			var ring := torus(w, 0.42, 0.5, Vector3.ZERO, Color(0.85, 0.87, 0.9))
			ring.rotation.x = PI / 2
			var field := cyl(w, 0.43, 0.43, 0.02, Vector3.ZERO, Color(NEON.r, NEON.g, NEON.b, 0.45), 16)
			field.rotation.x = PI / 2
			sphere(w, 0.09, Vector3(0, 0, 0.03), NEON, 1.4)
		"rifle_plasma":
			box(w, Vector3(0.12, 0.8, 0.09), Vector3(0, 0.1, 0), Color(0.88, 0.9, 0.93))
			cyl(w, 0.05, 0.05, 0.3, Vector3(0, 0.62, 0), POLYMER, 8)
			for k in 3:
				cyl(w, 0.065, 0.065, 0.025, Vector3(0, 0.25 + k * 0.1, 0), PLASMA, 8)
			box(w, Vector3(0.05, 0.4, 0.1), Vector3(-0.06, 0.12, 0), PLASMA, 1.0)
			var pp := box(w, Vector3(0.08, 0.16, 0.07), Vector3(0.1, -0.2, 0), POLYMER)
			pp.rotation.z = 0.4
			box(w, Vector3(0.1, 0.2, 0.08), Vector3(0, -0.42, 0), POLYMER)
		"exotraje":
			var suit := Color(0.88, 0.9, 0.93)
			box(w, Vector3(0.5, 0.42, 0.24), Vector3(0, 0.12, 0), suit)
			box(w, Vector3(0.38, 0.2, 0.2), Vector3(0, -0.2, 0), POLYMER)
			sphere(w, 0.09, Vector3(0, 0.16, 0.12), NEON, 1.4)
			for sx in [-1, 1]:
				sphere(w, 0.14, Vector3(sx * 0.32, 0.3, 0), suit.darkened(0.1))
				cyl(w, 0.07, 0.08, 0.3, Vector3(sx * 0.14, -0.45, 0), suit.darkened(0.05), 8)
		"canon_riel":
			for sx in [-1, 1]:
				box(w, Vector3(0.05, 1.0, 0.08), Vector3(sx * 0.06, 0.15, 0), Color(0.75, 0.78, 0.82))
			box(w, Vector3(0.04, 0.9, 0.04), Vector3(0, 0.15, 0), PLASMA, 1.2)
			box(w, Vector3(0.22, 0.3, 0.14), Vector3(0, -0.4, 0), POLYMER)
			for k in 4:
				box(w, Vector3(0.2, 0.03, 0.12), Vector3(0, -0.1 + k * 0.18, 0), Color(0.3, 0.32, 0.36))
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
	m.material = mat(Color(1, 0.75, 0.3), 1.6)
	p.mesh = m
	parent.add_child(p)
	return p
