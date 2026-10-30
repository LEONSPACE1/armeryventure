# Escenario de cada época: suelo, paredes, decoración y luces que titilan.
# Se elige con "escenario" en el tema del archivo de la época.
class_name Scenery

# Centro de los rincones del fondo, entre el banco de la orilla y la pared lateral
const CORNER_X := 4.77


# Construye el escenario y devuelve las luces de fuego (para hacerlas titilar).
static func build(world: Node3D, back_z: float, spot_z: float) -> Array:
	var lights: Array = []
	match GameState.theme("escenario", "cueva"):
		"taller_bronce":
			_bronze_workshop(world, back_z, spot_z, lights)
		"templo":
			_temple(world, back_z, spot_z, lights)
		"castillo":
			_castle(world, back_z, spot_z, lights)
		"puerto":
			_harbor(world, back_z, spot_z, lights)
		"fabrica":
			_factory(world, back_z, spot_z, lights)
		"tienda":
			_shop(world, back_z, spot_z, lights)
		"hangar":
			_hangar(world, back_z, spot_z, lights)
		_:
			_cave(world, back_z, spot_z, lights)
	return lights


# Llama con luz naranja (antorcha, brasero u horno).
static func _flame(world: Node3D, at: Vector3, lights: Array, size := 1.0, energy := 0.55) -> void:
	Art3D.sphere(world, 0.17 * size, at, Color(0.95, 0.45, 0.12), 0.9)
	Art3D.sphere(world, 0.09 * size, at + Vector3(0, 0.1, 0.05) * size, Color(1, 0.75, 0.4), 1.1)
	# Halo: resplandor suave alrededor de la llama
	Art3D.sphere(world, 0.38 * size, at + Vector3(0, 0.05, 0), Color(1, 0.6, 0.25, 0.16), 1.0)
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
		Art3D.cyl(world, 0.32, 0.18, 0.22, base + Vector3(0, 1.3, 0), Art3D.BRONZE, 10, 0.7)
		_flame(world, base + Vector3(0, 1.5, 0), lights, 1.1, 0.45)
	# Horno de fundición (rincón izquierdo) con boca encendida y crisol
	var oven := Vector3(-CORNER_X, 0, back_z + 0.9)
	Art3D.cyl(world, 0.3, 0.38, 1.5, oven + Vector3(0, 0.75, 0), Color(0.6, 0.38, 0.25), 10)
	Art3D.cyl(world, 0.14, 0.2, 0.5, oven + Vector3(0, 1.75, 0), Color(0.5, 0.32, 0.22), 8)
	var mouth := Art3D.sphere(world, 0.18, oven + Vector3(0.0, 0.45, 0.33), Color(0.95, 0.4, 0.1), 1.2)
	mouth.scale = Vector3(1.0, 0.8, 0.35)
	_flame(world, oven + Vector3(0, 2.1, 0), lights, 0.7, 0.35)
	Art3D.cyl(world, 0.17, 0.12, 0.22, oven + Vector3(0, 0.11, 0.95), Color(0.35, 0.3, 0.28), 8)
	Art3D.sphere(world, 0.11, oven + Vector3(0, 0.22, 0.95), Color(0.95, 0.55, 0.15), 0.9)
	# Ánforas y lingotes (rincón derecho)
	for k in 2:
		var p := Vector3(CORNER_X, 0, back_z + 0.6 + k * 0.65)
		var body := Art3D.sphere(world, 0.26, p + Vector3(0, 0.4, 0), Color(0.7, 0.42, 0.26).darkened(k * 0.08))
		body.scale = Vector3(1, 1.45, 1)
		Art3D.cyl(world, 0.09, 0.1, 0.18, p + Vector3(0, 0.86, 0), Color(0.65, 0.4, 0.25), 8)
	for k in 5:
		Art3D.box(world, Vector3(0.36, 0.09, 0.16), Vector3(CORNER_X, 0.05 + (k / 3) * 0.09, back_z + 1.75 + (k % 3) * 0.17), Art3D.BRONZE.darkened(0.1), 0.0, 0.6)


# --- Piezas compartidas ---------------------------------------------------------

# Lámpara eléctrica: bombillo que brilla y luz fija (no titila como el fuego).
# Con size = 0 solo pone la luz (para piezas que ya brillan, como el reactor).
static func _lamp(world: Node3D, at: Vector3, color: Color, energy := 0.7, size := 1.0) -> void:
	if size > 0.0:
		Art3D.sphere(world, 0.12 * size, at, color.lerp(Color.WHITE, 0.4), 1.2)
		Art3D.sphere(world, 0.32 * size, at, Color(color.r, color.g, color.b, 0.16), 1.0)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0, -0.1, 0.6)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 5.5
	world.add_child(light)


# Suelo de baldosas con variación de color, camino y alfombra frente al mostrador.
static func _tiled_floor(world: Node3D, back_z: float, spot_z: float, rng: RandomNumberGenerator, tile := 1.0, alt := Color(0, 0, 0, 0)) -> void:
	var floor_col := Color(GameState.theme("suelo", "#8c785e"))
	if alt.a == 0.0:
		alt = floor_col.lightened(0.15)
	Art3D.box(world, Vector3(40, 0.2, 50), Vector3(0, -0.1, 6), floor_col.darkened(0.3))
	var n := int(12.0 / tile)
	for ix in n:
		for iz in int(11.0 / tile):
			var p := Vector3(-6.0 + tile * (ix + 0.5), 0.0, back_z + tile * (iz + 0.6))
			Art3D.box(world, Vector3(tile * 0.94, 0.04, tile * 0.94), p, floor_col.lerp(alt, rng.randf() * 0.6))
	Art3D.box(world, Vector3(3.2, 0.03, 14), Vector3(0, 0.01, 10), Color(GameState.theme("camino", "#b8a382")))
	_rug(world, spot_z)


static func _rug(world: Node3D, spot_z: float) -> void:
	var rug := Color(GameState.theme("alfombra", "#8c3b2e"))
	Art3D.box(world, Vector3(9, 0.03, 1.8), Vector3(0, 0.03, spot_z + 0.1), rug)
	Art3D.box(world, Vector3(8.4, 0.035, 1.3), Vector3(0, 0.035, spot_z + 0.1), rug.lightened(0.25))
	Art3D.box(world, Vector3(7.8, 0.04, 0.9), Vector3(0, 0.04, spot_z + 0.1), rug)


# Pared del fondo (la parte alta se ve en pantallas altas) y paredes laterales.
static func _walls(world: Node3D, back_z: float, wall: Color, high: Color, side: Color) -> void:
	Art3D.box(world, Vector3(14, 4.2, 1.2), Vector3(0, 2.1, back_z - 0.6), wall)
	Art3D.box(world, Vector3(16, 40, 1.0), Vector3(0, 20.0, back_z - 1.6), high)
	for sx in [-1.0, 1.0]:
		Art3D.box(world, Vector3(0.8, 3.0, 12.0), Vector3(sx * 5.6, 1.5, back_z + 6.0), side)


# Hileras de bloques (ladrillo, piedra o tablas) pegadas a la pared del fondo.
static func _rows(world: Node3D, back_z: float, rng: RandomNumberGenerator, a: Color, b: Color, rows := 9, h := 0.45, w := 1.2) -> void:
	for row in rows:
		var off := w * 0.3 if row % 2 == 0 else 0.0
		for k in int(13.0 / w) + 1:
			var x := -6.5 + k * w + off
			Art3D.box(world, Vector3(w - 0.08, h - 0.07, 0.05), Vector3(x, 0.25 + row * h, back_z + 0.02), a.lerp(b, rng.randf()))


# Brasero de metal sobre trípode con fuego.
static func _brazier(world: Node3D, base: Vector3, metal: Color, lights: Array, energy := 0.45) -> void:
	for a in 3:
		var leg := Art3D.cyl(world, 0.025, 0.025, 1.3, base + Vector3(cos(a * TAU / 3.0) * 0.15, 0.62, sin(a * TAU / 3.0) * 0.15), metal.darkened(0.3), 4)
		leg.rotation = Vector3(sin(a * TAU / 3.0) * 0.2, 0, -cos(a * TAU / 3.0) * 0.2)
	Art3D.cyl(world, 0.32, 0.18, 0.22, base + Vector3(0, 1.3, 0), metal, 10, 0.7)
	_flame(world, base + Vector3(0, 1.5, 0), lights, 1.1, energy)


# Escudo redondo colgado (decoración).
static func _round_shield(world: Node3D, at: Vector3, face: Color, rim: Color, r := 0.35) -> void:
	var d := Art3D.cyl(world, r, r, 0.06, at, face, 12)
	d.rotation.x = PI / 2
	var t := Art3D.torus(world, r * 0.88, r * 1.05, at, rim, 0.7)
	t.rotation.x = PI / 2
	Art3D.sphere(world, r * 0.25, at + Vector3(0, 0, 0.04), rim, 0.0, 0.7)


# Barril de madera con aros.
static func _barrel(world: Node3D, at: Vector3, wood := Color(0.5, 0.33, 0.18)) -> void:
	Art3D.cyl(world, 0.26, 0.26, 0.7, at + Vector3(0, 0.35, 0), wood, 10)
	Art3D.sphere(world, 0.3, at + Vector3(0, 0.35, 0), wood).scale = Vector3(1, 1.05, 1)
	for y in [0.12, 0.58]:
		Art3D.cyl(world, 0.3, 0.3, 0.05, at + Vector3(0, y, 0), Color(0.3, 0.3, 0.32), 10, 0.7)


static func _crate(world: Node3D, at: Vector3, s: float, c: Color) -> void:
	Art3D.box(world, Vector3(s, s, s), at + Vector3(0, s / 2.0, 0), c)
	Art3D.box(world, Vector3(s + 0.02, 0.08, s + 0.02), at + Vector3(0, s * 0.8, 0), c.darkened(0.25))
	Art3D.box(world, Vector3(s + 0.02, 0.08, s + 0.02), at + Vector3(0, s * 0.2, 0), c.darkened(0.25))


# --- Antigüedad clásica: templo de mármol ---------------------------------------

static func _temple(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var marble := Color(0.86, 0.83, 0.77)
	_tiled_floor(world, back_z, spot_z, rng, 1.0, Color(0.8, 0.77, 0.71))
	_walls(world, back_z, Color(0.72, 0.36, 0.26), Color(0.3, 0.24, 0.22), marble.darkened(0.12))
	# Friso con meandro griego y columnas delante de la pared
	Art3D.box(world, Vector3(14, 0.6, 0.3), Vector3(0, 3.95, back_z + 0.1), marble)
	for k in 14:
		Art3D.box(world, Vector3(0.45, 0.08, 0.04), Vector3(-6.3 + k * 0.97, 3.95, back_z + 0.27), Color(0.75, 0.55, 0.25))
		Art3D.box(world, Vector3(0.08, 0.3, 0.04), Vector3(-6.1 + k * 0.97, 3.9, back_z + 0.27), Color(0.75, 0.55, 0.25))
	for x in [-5.0, -2.6, 2.6, 5.0]:
		Art3D.cyl(world, 0.26, 0.3, 3.4, Vector3(x, 1.85, back_z + 0.35), marble, 10)
		Art3D.box(world, Vector3(0.8, 0.2, 0.8), Vector3(x, 3.6, back_z + 0.35), marble.lightened(0.1))
		Art3D.box(world, Vector3(0.8, 0.15, 0.8), Vector3(x, 0.08, back_z + 0.35), marble.darkened(0.08))
	# Frontón triangular en la pared alta
	var prism := PrismMesh.new()
	prism.size = Vector3(11.0, 1.8, 0.4)
	Art3D._add(world, prism, Vector3(0, 5.35, back_z - 1.0), marble.darkened(0.05))
	Art3D.box(world, Vector3(11.4, 0.25, 0.5), Vector3(0, 4.35, back_z - 1.0), marble)
	# Escudos colgados
	_round_shield(world, Vector3(-3.8, 2.6, back_z + 0.08), Color(0.72, 0.18, 0.14), Art3D.BRONZE)
	_round_shield(world, Vector3(3.8, 2.6, back_z + 0.08), Color(0.2, 0.3, 0.55), Art3D.BRONZE)
	for tx in [-1.55, 1.55]:
		_brazier(world, Vector3(tx, 0.0, back_z + 0.5), Art3D.BRONZE, lights, 0.42)
	# Estatua sobre pedestal (rincón izquierdo)
	var st := Vector3(-CORNER_X, 0, back_z + 1.1)
	Art3D.box(world, Vector3(0.65, 0.6, 0.65), st + Vector3(0, 0.3, 0), marble.darkened(0.1))
	Art3D.cyl(world, 0.17, 0.24, 1.0, st + Vector3(0, 1.1, 0), marble, 8)
	Art3D.sphere(world, 0.17, st + Vector3(0, 1.75, 0), marble)
	Art3D.cyl(world, 0.02, 0.02, 1.4, st + Vector3(0.24, 1.4, 0), marble.darkened(0.15), 4)
	# Ánforas (rincón derecho)
	for k in 3:
		var p := Vector3(CORNER_X, 0, back_z + 0.6 + k * 0.62)
		var body := Art3D.sphere(world, 0.26, p + Vector3(0, 0.4, 0), Color(0.78, 0.45, 0.25).darkened(k * 0.05))
		body.scale = Vector3(1, 1.45, 1)
		Art3D.cyl(world, 0.09, 0.1, 0.18, p + Vector3(0, 0.86, 0), Color(0.15, 0.12, 0.1), 8)
	# Afuera: olivos y cipreses
	for k in 10:
		var x := rng.randf_range(2.2, 5.0) * (1.0 if k % 2 == 0 else -1.0)
		var p := Vector3(x, 0, rng.randf_range(9, 17))
		if k % 3 == 0:
			Art3D.cyl(world, 0.0, 0.35, 2.0, p + Vector3(0, 1.1, 0), Color(0.2, 0.38, 0.22), 6)
		else:
			Art3D.cyl(world, 0.07, 0.1, 0.8, p + Vector3(0, 0.4, 0), Color(0.45, 0.36, 0.28), 6)
			Art3D.sphere(world, 0.5, p + Vector3(0, 1.05, 0), Color(0.45, 0.55, 0.35)).scale = Vector3(1.2, 0.8, 1.2)


# --- Edad Media: salón de castillo ----------------------------------------------

static func _castle(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var stone := Color(0.5, 0.49, 0.47)
	var wood := Color(GameState.theme("suelo", "#6e5338"))
	# Piso de tablones
	Art3D.box(world, Vector3(40, 0.2, 50), Vector3(0, -0.1, 6), Color(0.35, 0.4, 0.28))
	for k in 24:
		var x := -5.75 + k * 0.5
		Art3D.box(world, Vector3(0.46, 0.04, 11.5), Vector3(x, 0.0, back_z + 5.8), wood.lerp(wood.lightened(0.18), rng.randf()))
	Art3D.box(world, Vector3(3.2, 0.03, 14), Vector3(0, 0.01, 10), Color(GameState.theme("camino", "#7d7a74")))
	_rug(world, spot_z)
	_walls(world, back_z, stone.darkened(0.2), Color(0.22, 0.22, 0.24), stone.darkened(0.1))
	_rows(world, back_z, rng, stone, stone.lightened(0.15), 9, 0.45, 0.9)
	# Almenas en lo alto de la pared
	Art3D.box(world, Vector3(16, 0.5, 1.0), Vector3(0, 4.45, back_z - 0.9), stone.darkened(0.1))
	for k in 9:
		Art3D.box(world, Vector3(0.9, 0.6, 1.0), Vector3(-7.2 + k * 1.8, 5.0, back_z - 0.9), stone.darkened(0.1))
	# Estandartes con escudo de armas
	for px in [-3.4, 3.4]:
		var cloth := Color(0.2, 0.3, 0.6) if px < 0 else Color(0.6, 0.15, 0.15)
		Art3D.box(world, Vector3(0.9, 1.6, 0.04), Vector3(px, 2.7, back_z + 0.08), cloth)
		Art3D.box(world, Vector3(1.05, 0.08, 0.08), Vector3(px, 3.52, back_z + 0.1), Color(0.3, 0.2, 0.12))
		var crest := Art3D.cyl(world, 0.28, 0.0, 0.6, Vector3(px, 2.75, back_z + 0.12), Color(0.95, 0.8, 0.3), 3)
		crest.rotation = Vector3(0, 0, PI)
		crest.scale.z = 0.12
	# Antorchas de pared
	for tx in [-1.55, 1.55]:
		var base := Vector3(tx, 2.0, back_z + 0.25)
		Art3D.cyl(world, 0.06, 0.08, 0.7, base, Color(0.35, 0.22, 0.12), 6)
		Art3D.cyl(world, 0.12, 0.08, 0.12, base + Vector3(0, 0.3, 0), Color(0.3, 0.3, 0.32), 6)
		_flame(world, base + Vector3(0, 0.48, 0), lights, 1.0, 0.5)
	# Chimenea en la pared lateral izquierda, con la boca hacia el salón
	var fp := Vector3(-5.0, 0, back_z + 1.3)
	Art3D.box(world, Vector3(0.6, 1.6, 1.5), fp + Vector3(0, 0.8, 0), stone.darkened(0.05))
	Art3D.box(world, Vector3(0.1, 0.9, 0.9), fp + Vector3(0.28, 0.45, 0), Color(0.12, 0.1, 0.09))
	Art3D.box(world, Vector3(0.75, 0.18, 1.65), fp + Vector3(0.05, 1.62, 0), stone.lightened(0.1))
	for k in 3:
		Art3D.cyl(world, 0.05, 0.05, 0.5, fp + Vector3(0.36, 0.08 + (k / 2) * 0.09, -0.12 + (k % 2) * 0.24), Color(0.4, 0.25, 0.12), 5).rotation.x = PI / 2
	_flame(world, fp + Vector3(0.38, 0.32, 0), lights, 1.0, 0.4)
	# Armero de pared con lanzas y un barril (rincón derecho)
	var rack := Vector3(5.0, 0, back_z + 1.1)
	Art3D.box(world, Vector3(0.12, 0.1, 1.3), rack + Vector3(0, 1.3, 0), Color(0.35, 0.22, 0.12))
	Art3D.box(world, Vector3(0.12, 0.1, 1.3), rack + Vector3(0, 0.3, 0), Color(0.35, 0.22, 0.12))
	for k in 3:
		Art3D.cyl(world, 0.02, 0.02, 1.5, rack + Vector3(-0.1, 0.75, -0.45 + k * 0.45), Color(0.55, 0.38, 0.2), 4)
		Art3D.cyl(world, 0.0, 0.05, 0.18, rack + Vector3(-0.1, 1.58, -0.45 + k * 0.45), Art3D.STEEL, 4, 0.7)
	_barrel(world, Vector3(CORNER_X, 0, back_z + 2.1))
	# Afuera: pasto y pinos
	for k in 10:
		var x := rng.randf_range(2.2, 5.0) * (1.0 if k % 2 == 0 else -1.0)
		var p := Vector3(x, 0, rng.randf_range(9, 17))
		Art3D.cyl(world, 0.06, 0.08, 0.5, p + Vector3(0, 0.25, 0), Color(0.4, 0.28, 0.18), 6)
		Art3D.cyl(world, 0.0, 0.55, 1.3, p + Vector3(0, 1.0, 0), Color(0.22, 0.42, 0.26), 7)


# --- Pólvora: almacén del puerto ------------------------------------------------

static func _harbor(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	var wood := Color(GameState.theme("suelo", "#7a5a3a"))
	# Muelle de tablones sobre el agua
	Art3D.box(world, Vector3(40, 0.2, 50), Vector3(0, -0.25, 6), Color(0.16, 0.36, 0.5))
	Art3D.box(world, Vector3(12, 0.2, 11.6), Vector3(0, -0.1, back_z + 5.8), wood.darkened(0.3))
	for k in 22:
		var z := back_z + 0.3 + k * 0.52
		Art3D.box(world, Vector3(12, 0.04, 0.48), Vector3(0, 0.0, z), wood.lerp(wood.lightened(0.15), rng.randf()))
	Art3D.box(world, Vector3(3.2, 0.2, 14), Vector3(0, -0.08, 10), Color(GameState.theme("camino", "#6b5038")))
	for k in 7:
		Art3D.box(world, Vector3(3.2, 0.04, 0.12), Vector3(0, 0.03, 4.5 + k * 1.6), wood.darkened(0.4))
	for sx in [-1.8, 1.8]:
		for k in 4:
			Art3D.cyl(world, 0.12, 0.12, 1.2, Vector3(sx, 0.1, 5.5 + k * 3.0), Color(0.35, 0.25, 0.16), 6)
	_rug(world, spot_z)
	# Paredes de tablas
	var plank := Color(0.45, 0.32, 0.2)
	_walls(world, back_z, plank.darkened(0.2), Color(0.18, 0.14, 0.12), plank.darkened(0.1))
	_rows(world, back_z, rng, plank, plank.lightened(0.15), 13, 0.32, 2.6)
	for x in [-6.0, -2.0, 2.0, 6.0]:
		Art3D.box(world, Vector3(0.3, 8.0, 0.3), Vector3(x, 4.0, back_z + 0.1), plank.darkened(0.35))
	Art3D.box(world, Vector3(15, 0.3, 0.3), Vector3(0, 4.3, back_z + 0.1), plank.darkened(0.35))
	# Timón de barco y mapa en la pared
	var helm := Vector3(-3.4, 2.6, back_z + 0.12)
	Art3D.torus(world, 0.42, 0.52, helm, Color(0.5, 0.32, 0.16)).rotation.x = PI / 2
	for k in 4:
		var spoke := Art3D.box(world, Vector3(0.06, 1.3, 0.06), helm, Color(0.55, 0.36, 0.18))
		spoke.rotation.z = k * PI / 4
	Art3D.sphere(world, 0.1, helm + Vector3(0, 0, 0.04), Color(0.82, 0.7, 0.4))
	Art3D.box(world, Vector3(1.2, 0.85, 0.03), Vector3(3.4, 2.6, back_z + 0.08), Color(0.88, 0.8, 0.6))
	Art3D.box(world, Vector3(0.5, 0.3, 0.035), Vector3(3.2, 2.7, back_z + 0.09), Color(0.55, 0.65, 0.4))
	Art3D.box(world, Vector3(0.3, 0.2, 0.035), Vector3(3.7, 2.45, back_z + 0.09), Color(0.55, 0.65, 0.4))
	# Faroles colgados
	for tx in [-1.55, 1.55]:
		var base := Vector3(tx, 2.6, back_z + 0.3)
		Art3D.box(world, Vector3(0.04, 0.5, 0.04), base + Vector3(0, 0.45, 0), Color(0.2, 0.2, 0.2))
		Art3D.box(world, Vector3(0.3, 0.04, 0.3), base + Vector3(0, 0.2, 0), Color(0.2, 0.2, 0.2))
		Art3D.box(world, Vector3(0.3, 0.04, 0.3), base + Vector3(0, -0.2, 0), Color(0.2, 0.2, 0.2))
		_flame(world, base, lights, 0.7, 0.42)
	# Cañón apuntando al salón con balas apiladas (rincón izquierdo)
	var cn := Vector3(-CORNER_X, 0, back_z + 0.9)
	Art3D.box(world, Vector3(0.5, 0.3, 0.9), cn + Vector3(0, 0.28, 0), Color(0.45, 0.3, 0.18))
	var tube := Art3D.cyl(world, 0.1, 0.15, 1.1, cn + Vector3(0, 0.55, 0.15), Art3D.DARK_IRON, 10, 0.7)
	tube.rotation.x = PI / 2 - 0.15
	for sx in [-1, 1]:
		var wh := Art3D.cyl(world, 0.2, 0.2, 0.06, cn + Vector3(sx * 0.28, 0.2, 0.15), Color(0.35, 0.22, 0.12), 10)
		wh.rotation.z = PI / 2
	for k in 3:
		Art3D.sphere(world, 0.11, cn + Vector3(-0.22 + k * 0.22, 0.11, 1.15), Art3D.DARK_IRON, 0.0, 0.7)
	Art3D.sphere(world, 0.11, cn + Vector3(-0.11, 0.3, 1.15), Art3D.DARK_IRON, 0.0, 0.7)
	# Barriles de pólvora, caja y cuerda (rincón derecho)
	_barrel(world, Vector3(CORNER_X, 0, back_z + 0.6))
	_barrel(world, Vector3(CORNER_X, 0, back_z + 1.3))
	_crate(world, Vector3(CORNER_X, 0, back_z + 2.0), 0.5, Color(0.6, 0.45, 0.28))
	Art3D.torus(world, 0.08, 0.2, Vector3(CORNER_X, 0.54, back_z + 2.0), Color(0.8, 0.7, 0.5))


# --- Revolución Industrial: fábrica de ladrillo ----------------------------------

static func _factory(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	var brick := Color(0.58, 0.28, 0.2)
	var iron := Color(0.25, 0.26, 0.28)
	_tiled_floor(world, back_z, spot_z, rng, 1.0)
	_walls(world, back_z, brick.darkened(0.25), Color(0.2, 0.15, 0.14), brick.darkened(0.15))
	_rows(world, back_z, rng, brick, brick.lightened(0.12), 9, 0.3, 0.7)
	# Vigas de hierro y ventanales en la pared alta
	for x in [-6.0, -2.0, 2.0, 6.0]:
		Art3D.box(world, Vector3(0.3, 8.0, 0.35), Vector3(x, 4.0, back_z + 0.12), iron)
	Art3D.box(world, Vector3(15, 0.35, 0.35), Vector3(0, 4.3, back_z + 0.12), iron)
	for x in [-4.0, 0.0, 4.0]:
		Art3D.box(world, Vector3(2.6, 2.0, 0.1), Vector3(x, 6.2, back_z - 1.05), Color(0.35, 0.45, 0.5))
		Art3D.box(world, Vector3(0.08, 2.0, 0.12), Vector3(x, 6.2, back_z - 1.0), iron)
		Art3D.box(world, Vector3(2.6, 0.08, 0.12), Vector3(x, 6.2, back_z - 1.0), iron)
	# Engranajes en la pared
	for g in [[-3.4, 2.7, 0.55], [-2.75, 2.1, 0.3], [3.4, 2.6, 0.5]]:
		var at := Vector3(g[0], g[1], back_z + 0.1)
		Art3D.cyl(world, g[2], g[2], 0.08, at, Color(0.45, 0.42, 0.38), 12, 0.6).rotation.x = PI / 2
		for k in 8:
			var a := k * TAU / 8.0
			var tooth := Art3D.box(world, Vector3(0.14, 0.14, 0.08), at + Vector3(cos(a), sin(a), 0) * g[2], Color(0.45, 0.42, 0.38))
			tooth.rotation.z = a
		Art3D.sphere(world, g[2] * 0.25, at + Vector3(0, 0, 0.05), iron)
	# Tubería a lo largo de la pared
	var pipe := Art3D.cyl(world, 0.1, 0.1, 13.0, Vector3(0, 3.7, back_z + 0.3), Color(0.55, 0.4, 0.25), 8, 0.7)
	pipe.rotation.z = PI / 2
	# Lámparas colgantes de bombillo
	for tx in [-1.55, 1.55]:
		Art3D.cyl(world, 0.01, 0.01, 1.2, Vector3(tx, 3.4, back_z + 0.6), Color(0.1, 0.1, 0.1), 4)
		Art3D.cyl(world, 0.05, 0.25, 0.15, Vector3(tx, 2.8, back_z + 0.6), Color(0.2, 0.35, 0.3), 8)
		_lamp(world, Vector3(tx, 2.68, back_z + 0.6), Color(1, 0.75, 0.45), 0.6)
	# Horno de carbón (rincón izquierdo)
	var fn := Vector3(-CORNER_X, 0, back_z + 1.0)
	Art3D.box(world, Vector3(0.7, 1.3, 0.9), fn + Vector3(0, 0.65, 0), iron.lightened(0.05))
	Art3D.cyl(world, 0.17, 0.17, 3.0, fn + Vector3(0, 2.7, -0.2), iron, 8)
	Art3D.box(world, Vector3(0.4, 0.35, 0.05), fn + Vector3(0, 0.5, 0.46), Color(0.95, 0.4, 0.1), 1.0)
	_flame(world, fn + Vector3(0, 0.45, 0.55), lights, 0.6, 0.35)
	for k in 5:
		Art3D.sphere(world, 0.12, fn + Vector3(-0.15 + (k % 3) * 0.15, 0.08 + (k / 3) * 0.1, 0.95), Color(0.12, 0.12, 0.13))
	# Cajas y un barril (rincón derecho)
	_crate(world, Vector3(CORNER_X, 0, back_z + 0.6), 0.6, Color(0.62, 0.48, 0.3))
	_crate(world, Vector3(CORNER_X, 0.6, back_z + 0.6), 0.45, Color(0.6, 0.46, 0.28))
	_crate(world, Vector3(CORNER_X, 0, back_z + 1.3), 0.55, Color(0.55, 0.42, 0.26))
	_barrel(world, Vector3(CORNER_X, 0, back_z + 2.05), Color(0.3, 0.35, 0.3))
	# Afuera: adoquines y faroles de gas
	for k in 40:
		var p := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(9, 17))
		if absf(p.x) > 1.7:
			Art3D.box(world, Vector3(0.4, 0.04, 0.3), p, Color(0.4, 0.38, 0.36).lightened(rng.randf() * 0.15))
	for sx in [-2.3, 2.3]:
		Art3D.cyl(world, 0.05, 0.07, 2.2, Vector3(sx, 1.1, 11.0), iron, 6)
		Art3D.box(world, Vector3(0.25, 0.3, 0.25), Vector3(sx, 2.35, 11.0), Color(0.95, 0.85, 0.6), 0.9)
		_lamp(world, Vector3(sx, 2.35, 10.4), Color(1, 0.8, 0.5), 0.5, 0.0)


# --- Era moderna: tienda táctica ------------------------------------------------

static func _shop(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var paint := Color(0.52, 0.56, 0.6)
	_tiled_floor(world, back_z, spot_z, rng, 1.0, Color(0.58, 0.6, 0.63))
	_walls(world, back_z, paint, Color(0.2, 0.22, 0.25), paint.darkened(0.1))
	# Zócalo, paneles perforados con siluetas de armas y letrero luminoso
	Art3D.box(world, Vector3(14, 0.5, 0.06), Vector3(0, 0.25, back_z + 0.03), Color(0.25, 0.27, 0.3))
	for px in [-3.6, 3.6]:
		Art3D.box(world, Vector3(1.8, 1.4, 0.04), Vector3(px, 2.5, back_z + 0.05), Color(0.3, 0.32, 0.35))
		for k in 3:
			Art3D.box(world, Vector3(1.3, 0.1, 0.05), Vector3(px, 2.05 + k * 0.45, back_z + 0.09), Color(0.12, 0.13, 0.14))
			Art3D.box(world, Vector3(0.12, 0.2, 0.05), Vector3(px + 0.4, 1.95 + k * 0.45, back_z + 0.09), Color(0.12, 0.13, 0.14))
	Art3D.box(world, Vector3(3.2, 0.6, 0.1), Vector3(0, 3.7, back_z + 0.1), Color(0.15, 0.17, 0.2))
	Art3D.box(world, Vector3(2.8, 0.22, 0.05), Vector3(0, 3.7, back_z + 0.16), Color(0.95, 0.55, 0.2), 0.8)
	# Paneles de luz en el techo (pared alta) y luces fijas
	for x in [-4.0, 0.0, 4.0]:
		Art3D.box(world, Vector3(2.4, 0.15, 0.6), Vector3(x, 4.5, back_z + 0.1), Color(0.8, 0.83, 0.88), 0.3)
	_lamp(world, Vector3(0, 4.3, back_z + 0.2), Color(0.9, 0.95, 1.0), 0.5, 0.0)
	for tx in [-1.55, 1.55]:
		_lamp(world, Vector3(tx, 3.2, back_z + 0.4), Color(0.9, 0.95, 1.0), 0.5, 0.8)
	# Vitrina de vidrio contra la pared lateral izquierda
	var vt := Vector3(-4.85, 0, back_z + 1.2)
	Art3D.box(world, Vector3(0.6, 0.8, 1.5), vt + Vector3(0, 0.4, 0), Color(0.3, 0.32, 0.35))
	Art3D.box(world, Vector3(0.6, 0.7, 1.5), vt + Vector3(0, 1.15, 0), Color(0.7, 0.85, 0.95, 0.3), 0.0, 1.0)
	for k in 2:
		Art3D.box(world, Vector3(0.15, 0.06, 0.55), vt + Vector3(0, 0.86, -0.35 + k * 0.7), Color(0.15, 0.15, 0.16), 0.0, 0.7)
	# Estantería con cajas de munición contra la pared lateral derecha
	var shelf := Vector3(4.9, 0, back_z + 1.2)
	Art3D.box(world, Vector3(0.5, 2.0, 1.5), shelf + Vector3(0.05, 1.0, 0), Color(0.35, 0.37, 0.4), 0.0, 0.6)
	for row in 3:
		for k in 3:
			Art3D.box(world, Vector3(0.36, 0.3, 0.36), shelf + Vector3(-0.15, 0.35 + row * 0.6, -0.45 + k * 0.45), Color(0.4, 0.45, 0.3).darkened(rng.randf() * 0.2))
	# Afuera: asfalto con líneas y matas
	Art3D.box(world, Vector3(40, 0.02, 9), Vector3(0, -0.005, 13.5), Color(0.25, 0.26, 0.28))
	for k in 5:
		Art3D.box(world, Vector3(0.18, 0.025, 1.4), Vector3(-4.0 + k * 2.0, 0.0, 14.5), Color(0.95, 0.8, 0.25))
	for sx in [-3.0, 3.0]:
		Art3D.box(world, Vector3(0.8, 0.4, 0.8), Vector3(sx, 0.2, 10.5), Color(0.5, 0.52, 0.55))
		Art3D.sphere(world, 0.45, Vector3(sx, 0.6, 10.5), Color(0.3, 0.5, 0.3))


# --- Futurista: hangar espacial -------------------------------------------------

static func _hangar(world: Node3D, back_z: float, spot_z: float, lights: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 81
	var panel := Color(0.3, 0.34, 0.42)
	var neon := Color(0.3, 0.9, 1.0)
	var violet := Color(0.7, 0.4, 1.0)
	_tiled_floor(world, back_z, spot_z, rng, 1.5, Color(0.22, 0.26, 0.34))
	# Líneas de luz en el piso, a los lados del camino
	for sx in [-1.65, 1.65]:
		Art3D.box(world, Vector3(0.06, 0.04, 14), Vector3(sx, 0.03, 10), neon, 0.8)
	_walls(world, back_z, panel, Color(0.06, 0.07, 0.12), panel.darkened(0.15))
	# Paneles de pared con franjas de neón
	for k in 6:
		var x := -5.0 + k * 2.0
		Art3D.box(world, Vector3(1.8, 3.6, 0.06), Vector3(x, 2.0, back_z + 0.03), panel.lightened(0.08))
		Art3D.box(world, Vector3(1.6, 0.05, 0.05), Vector3(x, 3.5, back_z + 0.08), neon if k % 2 == 0 else violet, 0.8)
	# Ventanal con estrellas y planeta en la pared alta
	Art3D.box(world, Vector3(10, 3.4, 0.1), Vector3(0, 6.6, back_z - 1.05), Color(0.03, 0.04, 0.1))
	for k in 30:
		Art3D.box(world, Vector3(0.05, 0.05, 0.02), Vector3(rng.randf_range(-4.8, 4.8), rng.randf_range(5.0, 8.2), back_z - 0.98), Color(0.9, 0.95, 1.0), 0.8)
	var planet := Art3D.sphere(world, 0.8, Vector3(2.8, 6.8, back_z - 1.2), Color(0.55, 0.35, 0.85))
	planet.scale.z = 0.3
	Art3D.box(world, Vector3(10.4, 0.2, 0.2), Vector3(0, 4.85, back_z - 0.95), panel.darkened(0.2))
	# Holograma central sobre la pared
	Art3D.box(world, Vector3(2.0, 0.08, 0.08), Vector3(0, 3.6, back_z + 0.15), neon, 0.9)
	Art3D.box(world, Vector3(1.6, 0.9, 0.02), Vector3(0, 4.1, back_z + 0.2), Color(neon.r, neon.g, neon.b, 0.25))
	# Luces de color fijas
	_lamp(world, Vector3(-1.55, 3.0, back_z + 0.3), neon, 0.6, 0.8)
	_lamp(world, Vector3(1.55, 3.0, back_z + 0.3), violet, 0.6, 0.8)
	# Luz del holograma y de las líneas del piso
	_lamp(world, Vector3(0, 4.1, back_z + 0.3), neon, 0.4, 0.0)
	for sx in [-1.65, 1.65]:
		_lamp(world, Vector3(sx, 0.4, 7.0), neon, 0.45, 0.0)
	# Reactor de energía (rincón izquierdo), con luz propia
	var rc := Vector3(-CORNER_X, 0, back_z + 1.1)
	Art3D.cyl(world, 0.36, 0.4, 0.25, rc + Vector3(0, 0.12, 0), panel.darkened(0.2), 12, 0.6)
	Art3D.cyl(world, 0.24, 0.24, 1.3, rc + Vector3(0, 0.9, 0), Color(neon.r, neon.g, neon.b, 0.45), 12)
	Art3D.cyl(world, 0.11, 0.11, 1.2, rc + Vector3(0, 0.9, 0), neon, 12).material_override = Art3D.mat(neon, 1.4)
	Art3D.cyl(world, 0.32, 0.36, 0.22, rc + Vector3(0, 1.65, 0), panel.darkened(0.2), 12, 0.6)
	for k in 3:
		Art3D.torus(world, 0.26, 0.31, rc + Vector3(0, 0.5 + k * 0.4, 0), Color(0.75, 0.78, 0.85), 0.7)
	_lamp(world, rc + Vector3(0.3, 1.0, 0.4), neon, 0.6, 0.0)
	# Contenedores con franja luminosa (rincón derecho)
	for c in [[0.0, 0.6, 0.6], [0.6, 0.6, 0.45], [0.0, 1.3, 0.55], [0.0, 2.0, 0.5]]:
		var at := Vector3(CORNER_X, c[0], back_z + c[1])
		Art3D.box(world, Vector3(c[2], c[2], c[2]), at + Vector3(0, c[2] / 2.0, 0), Color(0.82, 0.85, 0.9), 0.0, 0.5)
		Art3D.box(world, Vector3(c[2] + 0.02, 0.05, c[2] + 0.02), at + Vector3(0, c[2] * 0.5, 0), violet, 0.8)
	# Afuera: plataforma oscura con balizas
	for k in 8:
		var sx := -3.0 if k % 2 == 0 else 3.0
		Art3D.sphere(world, 0.08, Vector3(sx, 0.08, 9.5 + (k / 2) * 2.2), neon if k % 4 < 2 else violet, 1.0)
