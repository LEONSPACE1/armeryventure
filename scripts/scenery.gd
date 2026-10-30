# Escenario de cada época: suelo, paredes, decoración y luces que titilan.
# Se elige con "escenario" en el tema del archivo de la época.
class_name Scenery


# Construye el escenario y devuelve las luces de fuego (para hacerlas titilar).
static func build(world: Node3D, back_z: float, spot_z: float) -> Array:
	var lights: Array = []
	match GameState.theme("escenario", "cueva"):
		"taller_bronce":
			_bronze_workshop(world, back_z, spot_z, lights)
		_:
			_cave(world, back_z, spot_z, lights)
	return lights


# Llama con luz naranja (antorcha, brasero u horno).
static func _flame(world: Node3D, at: Vector3, lights: Array, size := 1.0, energy := 0.55) -> void:
	Art3D.sphere(world, 0.17 * size, at, Color(0.95, 0.45, 0.12), 0.9)
	Art3D.sphere(world, 0.09 * size, at + Vector3(0, 0.1, 0.05) * size, Color(1, 0.75, 0.4), 1.1)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0, 0.12, 0.6)
	light.light_color = Color(1, 0.6, 0.25)
	light.light_energy = energy
	light.set_meta("base", energy)
	light.omni_range = 4.5
	world.add_child(light)
	lights.append(light)


# --- Prehistoria: cueva ---------------------------------------------------------

static func _cave(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# Suelo de tierra con piedras, camino claro hacia la entrada y algo de pasto
	Art3D.box(world, Vector3(40, 0.2, 50), Vector3(0, -0.1, 6), Color(GameState.theme("suelo", "#6b4f38")))
	Art3D.box(world, Vector3(3.2, 0.02, 14), Vector3(0, 0.0, 10), Color(GameState.theme("camino", "#85694d")))
	Art3D.box(world, Vector3(9, 0.02, 1.8), Vector3(0, 0.006, spot_z + 0.1), Color(GameState.theme("alfombra", "#805c3d")))
	for k in 70:
		var p := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(-7, 16))
		var st := Art3D.cyl(world, 0.0, rng.randf_range(0.06, 0.18), 0.05, p, Color(0.4, 0.3, 0.21).lerp(Color(0.55, 0.5, 0.45), rng.randf()), 6)
		st.scale.z = rng.randf_range(0.6, 1.0)
	for k in 26:
		var p := Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(9, 18))
		if absf(p.x) < 1.8:
			continue
		Art3D.cyl(world, 0.0, 0.12, rng.randf_range(0.25, 0.45), p + Vector3(0, 0.15, 0), Color(0.4, 0.6, 0.28), 5)
	# Pared del fondo y rocas
	Art3D.box(world, Vector3(14, 4.2, 1.2), Vector3(0, 2.1, back_z - 0.6), Color(0.33, 0.27, 0.23))
	# Pared alta del fondo: en pantallas altas se ve como roca sobre la cueva
	Art3D.box(world, Vector3(16, 40, 1.0), Vector3(0, 20.0, back_z - 1.6), Color(0.24, 0.19, 0.16))
	for k in 18:
		var rp := Vector3(rng.randf_range(-5.5, 5.5), rng.randf_range(5.0, 12.0), back_z - 1.1)
		Art3D.sphere(world, rng.randf_range(0.5, 1.1), rp, Color(0.3, 0.24, 0.2).darkened(rng.randf() * 0.25))
	for k in 16:
		var x := -7.0 + k * 0.95
		Art3D.sphere(world, rng.randf_range(0.45, 0.8), Vector3(x, rng.randf_range(0.0, 0.4), back_z + 0.05), Color(0.38, 0.31, 0.26).darkened(rng.randf() * 0.2))
		Art3D.sphere(world, rng.randf_range(0.5, 0.9), Vector3(x, 4.1, back_z - 0.2), Color(0.28, 0.23, 0.2))
		var st := Art3D.cyl(world, 0.12, 0.0, rng.randf_range(0.5, 1.0), Vector3(x + 0.4, 3.6, back_z + 0.15), Color(0.3, 0.25, 0.21), 5)
		st.rotation.x = 0.1
	for side in [-1.0, 1.0]:
		for k in 5:
			Art3D.sphere(world, rng.randf_range(0.5, 0.8), Vector3(side * rng.randf_range(4.9, 5.4), 0.2, back_z + 0.8 + k * 1.3), Color(0.36, 0.3, 0.25))
	# Pinturas rupestres en la pared
	for px in [-3.4, 3.4]:
		var ochre := Color(0.78, 0.42, 0.2)
		var z := back_z + 0.02
		Art3D.box(world, Vector3(0.7, 0.3, 0.02), Vector3(px, 2.6, z), ochre)
		Art3D.box(world, Vector3(0.22, 0.2, 0.02), Vector3(px + 0.42, 2.78, z), ochre)
		for lx in [-0.25, -0.1, 0.12, 0.27]:
			Art3D.box(world, Vector3(0.05, 0.28, 0.02), Vector3(px + lx, 2.35, z), ochre)
	# Antorchas con luz que titila
	for tx in [-1.55, 1.55]:
		var base := Vector3(tx, 2.0, back_z + 0.25)
		Art3D.cyl(world, 0.06, 0.08, 0.7, base, Color(0.35, 0.22, 0.12), 6)
		_flame(world, base + Vector3(0, 0.48, 0), lights)


# --- Edad del Bronce: taller de adobe con horno de fundición --------------------

static func _bronze_workshop(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var floor_col := Color(GameState.theme("suelo", "#a08a6c"))
	var adobe := Color(0.64, 0.49, 0.35)
	var beam := Color(0.42, 0.28, 0.16)
	# Suelo de losas de piedra, camino de tierra y alfombra frente al mostrador
	Art3D.box(world, Vector3(40, 0.2, 50), Vector3(0, -0.1, 6), floor_col.darkened(0.25))
	for ix in 12:
		for iz in 11:
			var p := Vector3(-5.5 + ix * 1.0, 0.0, back_z + 0.6 + iz * 1.0)
			Art3D.box(world, Vector3(0.94, 0.04, 0.94), p, floor_col.lerp(Color(0.7, 0.62, 0.5), rng.randf() * 0.5).darkened(rng.randf() * 0.1))
	Art3D.box(world, Vector3(3.2, 0.03, 14), Vector3(0, 0.01, 10), Color(GameState.theme("camino", "#b8a382")))
	var rug := Color(GameState.theme("alfombra", "#8c3b2e"))
	Art3D.box(world, Vector3(9, 0.03, 1.8), Vector3(0, 0.03, spot_z + 0.1), rug)
	Art3D.box(world, Vector3(8.4, 0.035, 1.3), Vector3(0, 0.035, spot_z + 0.1), rug.lightened(0.25))
	Art3D.box(world, Vector3(7.8, 0.04, 0.9), Vector3(0, 0.04, spot_z + 0.1), rug)
	# Afuera: arena y palmeras pequeñas junto a la entrada
	for k in 10:
		var x := rng.randf_range(2.2, 5.0) * (1.0 if k % 2 == 0 else -1.0)
		var p := Vector3(x, 0, rng.randf_range(9, 17))
		Art3D.cyl(world, 0.07, 0.1, 1.2, p + Vector3(0, 0.6, 0), Color(0.5, 0.36, 0.2), 6)
		for a in 5:
			var leaf := Art3D.box(world, Vector3(0.12, 0.04, 0.7), p + Vector3(0, 1.25, 0), Color(0.35, 0.58, 0.25))
			leaf.rotation = Vector3(0.5, a * TAU / 5.0, 0)
			leaf.position += Vector3(sin(a * TAU / 5.0), 0, cos(a * TAU / 5.0)) * 0.28
	# Pared del fondo de adobe con hileras de ladrillos y vigas de madera
	Art3D.box(world, Vector3(14, 4.2, 1.2), Vector3(0, 2.1, back_z - 0.6), adobe)
	Art3D.box(world, Vector3(16, 40, 1.0), Vector3(0, 20.0, back_z - 1.6), adobe.darkened(0.45))
	for row in 9:
		var y := 0.25 + row * 0.45
		var off := 0.35 if row % 2 == 0 else 0.0
		for k in 11:
			var x := -6.0 + k * 1.2 + off
			Art3D.box(world, Vector3(1.1, 0.38, 0.05), Vector3(x, y, back_z + 0.02), adobe.lerp(Color(0.68, 0.5, 0.33), rng.randf() * 0.6))
	for y in [4.25, 6.5, 9.0]:
		var b := Art3D.cyl(world, 0.16, 0.16, 15.0, Vector3(0, y, back_z - 0.05), beam, 6)
		b.rotation.z = PI / 2
	for x in [-6.0, -2.0, 2.0, 6.0]:
		Art3D.box(world, Vector3(0.35, 8.0, 0.3), Vector3(x, 6.0, back_z - 0.4), beam.darkened(0.15))
	# Paredes laterales de adobe
	for side in [-1.0, 1.0]:
		Art3D.box(world, Vector3(0.8, 3.0, 12.0), Vector3(side * 5.6, 1.5, back_z + 6.0), adobe.darkened(0.08))
		Art3D.box(world, Vector3(0.9, 0.2, 12.0), Vector3(side * 5.6, 3.05, back_z + 6.0), beam)
	# Estandartes del palacio colgados en la pared
	for px in [-3.4, 3.4]:
		var cloth := Color(0.62, 0.18, 0.15) if px < 0 else Color(0.2, 0.32, 0.55)
		Art3D.box(world, Vector3(0.9, 1.5, 0.04), Vector3(px, 2.7, back_z + 0.08), cloth)
		Art3D.box(world, Vector3(1.05, 0.08, 0.08), Vector3(px, 3.47, back_z + 0.1), Art3D.BRONZE)
		var emblem := Art3D.sphere(world, 0.2, Vector3(px, 2.8, back_z + 0.12), Color(0.95, 0.8, 0.35))
		emblem.scale.z = 0.25
		var tip := Art3D.cyl(world, 0.45, 0.0, 0.35, Vector3(px, 1.8, back_z + 0.08), cloth, 4)
		tip.rotation.y = PI / 4
		tip.scale.z = 0.08
	# Braseros de bronce sobre trípodes
	for tx in [-1.55, 1.55]:
		var base := Vector3(tx, 0.0, back_z + 0.5)
		for a in 3:
			var leg := Art3D.cyl(world, 0.025, 0.025, 1.3, base + Vector3(cos(a * TAU / 3.0) * 0.15, 0.62, sin(a * TAU / 3.0) * 0.15), Art3D.BRONZE.darkened(0.3), 4)
			leg.rotation = Vector3(sin(a * TAU / 3.0) * 0.2, 0, -cos(a * TAU / 3.0) * 0.2)
		Art3D.cyl(world, 0.32, 0.18, 0.22, base + Vector3(0, 1.3, 0), Art3D.BRONZE, 10)
		_flame(world, base + Vector3(0, 1.5, 0), lights, 1.1, 0.45)
	# Horno de fundición (izquierda) con boca encendida y crisol
	var oven := Vector3(-4.2, 0, back_z + 1.7)
	Art3D.cyl(world, 0.55, 0.85, 1.7, oven + Vector3(0, 0.85, 0), Color(0.6, 0.38, 0.25), 10)
	Art3D.cyl(world, 0.2, 0.3, 0.6, oven + Vector3(0, 1.95, 0), Color(0.5, 0.32, 0.22), 8)
	var mouth := Art3D.sphere(world, 0.3, oven + Vector3(0.0, 0.5, 0.72), Color(0.95, 0.4, 0.1), 1.2)
	mouth.scale = Vector3(1.0, 0.8, 0.35)
	_flame(world, oven + Vector3(0, 2.3, 0), lights, 0.8, 0.35)
	Art3D.cyl(world, 0.2, 0.14, 0.25, oven + Vector3(0.95, 0.12, 0.5), Color(0.35, 0.3, 0.28), 8)
	Art3D.sphere(world, 0.13, oven + Vector3(0.95, 0.25, 0.5), Color(0.95, 0.55, 0.15), 0.9)
	# Ánforas y lingotes (derecha)
	var store := Vector3(4.5, 0, back_z + 1.4)
	for k in 4:
		var p := store + Vector3((k % 2) * 0.55 - 0.25, 0, (k / 2) * 0.6)
		var body := Art3D.sphere(world, 0.3, p + Vector3(0, 0.45, 0), Color(0.7, 0.42, 0.26).darkened(k * 0.05))
		body.scale = Vector3(1, 1.45, 1)
		Art3D.cyl(world, 0.1, 0.12, 0.2, p + Vector3(0, 0.98, 0), Color(0.65, 0.4, 0.25), 8)
	for k in 5:
		Art3D.box(world, Vector3(0.4, 0.1, 0.18), store + Vector3(-0.1 + (k % 3) * 0.1, 0.05 + (k / 3) * 0.1, 1.5), Art3D.BRONZE.darkened(0.1))
