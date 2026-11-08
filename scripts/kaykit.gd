# Modelos de KayKit (Kay Lousberg, CC0): carga, ajuste de tamaño y props por época.
# Los archivos están en res://assets/kaykit/<pack>/ (ver CREDITOS.md).
class_name KayKit

const DIR := "res://assets/kaykit/"
const CHARACTERS := ["Barbarian", "Knight", "Mage", "Rogue"]

static var _scenes := {}


static func scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(DIR + path) as PackedScene
	return _scenes[path]


# Instancia un modelo y lo escala para que su caja mida `size` (0 en un eje = proporcional).
# El modelo queda centrado en x/z y apoyado en y = 0 dentro del nodo devuelto.
static func fit(path: String, size: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.set_meta("kk", true)
	var inst := scene(path).instantiate() as Node3D
	holder.add_child(inst)
	var box := aabb(inst)
	var ref := 0.0
	for a in 3:
		if size[a] > 0.0 and box.size[a] > 0.0:
			ref = size[a] / box.size[a]
			break
	var s := Vector3.ONE * ref
	for a in 3:
		if size[a] > 0.0 and box.size[a] > 0.0:
			s[a] = size[a] / box.size[a]
	inst.scale = s
	inst.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * s
	return holder


# Escala proporcional para que quepa en la caja `size`, apoyado en y = 0.
static func fit_max(path: String, size: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.set_meta("kk", true)
	var inst := scene(path).instantiate() as Node3D
	holder.add_child(inst)
	var box := aabb(inst)
	var k := INF
	for a in 3:
		if box.size[a] > 0.0:
			k = minf(k, size[a] / box.size[a])
	inst.scale = Vector3.ONE * k
	inst.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * k
	return holder


# Pone un modelo en `parent` sin pasar de `height` de alto ni de `width` de ancho/fondo.
static func prop(parent: Node3D, path: String, at: Vector3, height: float, rot_y := 0.0, width := 0.9) -> Node3D:
	var n := fit_max(path, Vector3(width, height, width))
	n.position = at
	n.rotation.y = rot_y
	parent.add_child(n)
	return n


# Caja de todas las mallas de `root`, en el espacio de `root` (pose de reposo).
static func aabb(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse() if root.is_inside_tree() else Transform3D.IDENTITY
	var out := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf: Transform3D = _local_xf(mi, root) if not root.is_inside_tree() else inv * mi.global_transform
		var b: AABB = xf * mi.get_aabb()
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out


static func _local_xf(n: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


# Decoración extra de cada época en los costados (barriles, cajas, estantes...)
static func era_props(world: Node3D, back_z: float, scenario: String) -> void:
	var L := -Scenery.CORNER_X - 0.1
	var R := Scenery.CORNER_X + 0.1
	var z1 := back_z + 3.4
	var z2 := back_z + 4.5
	match scenario:
		"cueva":
			prop(world, "hexagon/rock_single_A.gltf", Vector3(L, 0, z1), 0.7)
			prop(world, "hexagon/resource_lumber.gltf", Vector3(R, 0, z1), 0.55, 0.4)
			prop(world, "hexagon/resource_stone.gltf", Vector3(L + 0.1, 0, z2), 0.5)
			prop(world, "hexagon/sack.gltf", Vector3(R, 0, z2), 0.6)
		"taller_bronce":
			prop(world, "hexagon/crate_A_big.gltf", Vector3(L, 0, z1), 0.75)
			prop(world, "hexagon/bucket_water.gltf", Vector3(R, 0, z1), 0.5)
			prop(world, "hexagon/sack.gltf", Vector3(L, 0, z2), 0.6, 0.6)
			prop(world, "hexagon/pallet.gltf", Vector3(R, 0, z2), 0.25)
		"templo":
			prop(world, "hexagon/weaponrack.gltf", Vector3(L, 0, z1), 1.2, PI / 2)
			prop(world, "dungeon/keg.glb", Vector3(R, 0, z1), 0.7)
			prop(world, "hexagon/crate_long_A.gltf", Vector3(L, 0, z2), 0.5, PI / 2)
			prop(world, "hexagon/target.gltf", Vector3(R, 0, z2), 1.1, -PI / 2)
		"castillo":
			prop(world, "dungeon/shelves.glb", Vector3(L, 0, z1), 1.6, PI / 2)
			prop(world, "dungeon/sword_shield.glb", Vector3(R, 0, z1), 0.9, -PI / 2)
			prop(world, "dungeon/chest.glb", Vector3(L, 0, z2), 0.6, PI / 2)
			prop(world, "dungeon/trunk_large_A.glb", Vector3(R, 0, z2), 0.65, -PI / 2)
		"puerto":
			prop(world, "dungeon/keg.glb", Vector3(L, 0, z1), 0.8)
			prop(world, "dungeon/crates_stacked.glb", Vector3(R, 0, z1), 1.1)
			prop(world, "dungeon/coin_stack_large.glb", Vector3(L, 0, z2), 0.35)
			prop(world, "dungeon/chest.glb", Vector3(R, 0, z2), 0.6, -PI / 2)
		"fabrica":
			prop(world, "city/box_A.gltf", Vector3(L, 0, z1), 0.7)
			prop(world, "city/box_B.gltf", Vector3(R, 0, z1), 0.8)
			prop(world, "city/trash_A.gltf", Vector3(L, 0, z2), 0.7)
			prop(world, "hexagon/crate_long_A.gltf", Vector3(R, 0, z2), 0.5, PI / 2)
		"tienda":
			prop(world, "furniture/shelf_B_large_decorated.gltf", Vector3(L, 0, z1), 1.6, PI / 2)
			prop(world, "furniture/cabinet_medium_decorated.gltf", Vector3(R, 0, z1), 1.0, -PI / 2)
			prop(world, "city/box_A.gltf", Vector3(L, 0, z2), 0.6)
			prop(world, "furniture/lamp_standing.gltf", Vector3(R, 0, z2), 1.6)
		"hangar":
			prop(world, "space/cargo_A_stacked.gltf", Vector3(L, 0, z1), 1.1)
			prop(world, "space/containers_A.gltf", Vector3(R, 0, z1), 0.9)
			prop(world, "space/cargo_B_packed.gltf", Vector3(L, 0, z2), 0.7)
			prop(world, "space/lights.gltf", Vector3(R, 0, z2), 1.4)


# Cuerpos de KayKit que encajan con la ropa de cada época (de la Prehistoria a la futurista)
const ERA_BODIES := [
	["Barbarian"],
	["Barbarian", "Rogue"],
	["Knight", "Rogue"],
	["Knight", "Mage", "Rogue"],
	["Rogue", "Knight"],
	["Rogue", "Mage"],
	["Rogue"],
	["Rogue", "Knight"],
]


static func era_body(seed: int) -> String:
	var list: Array = ERA_BODIES[clampi(GameState.era_index, 0, ERA_BODIES.size() - 1)]
	return list[seed % list.size()]


# Mesa de trabajo de cada época
static func bench_path() -> String:
	return "dungeon/table_long.glb" if GameState.era_index <= 4 else ("furniture/table_medium_long.gltf" if GameState.era_index <= 5 else "restaurant/kitchentable_A_large.gltf")
