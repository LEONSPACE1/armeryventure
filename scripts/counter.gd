# Mostrador donde esperan los clientes (colores según la época).
extends Node3D

const LENGTH := 7.6


func _ready() -> void:
	# Mostrador de KayKit: varias mesas en fila (mesa larga con mantel o mostrador de cocina)
	var path := "dungeon/table_long.glb" if GameState.era_index <= 4 else "restaurant/kitchencounter_straight_A.gltf"
	var n := 3 if GameState.era_index <= 4 else 7
	var seg := LENGTH / n
	for i in n:
		var t := KayKit.fit(path, Vector3(seg, 1.05, 0.95))
		t.position = Vector3(-LENGTH / 2.0 + seg * (i + 0.5), 0, 0)
		add_child(t)
	# Cuenco de monedas y una piel sobre el mostrador
	Art3D.cyl(self, 0.28, 0.2, 0.14, Vector3(LENGTH / 2.0 - 0.6, 1.12, 0), Color(0.38, 0.24, 0.12))
	for k in 5:
		Art3D.cyl(self, 0.09, 0.09, 0.04, Vector3(LENGTH / 2.0 - 0.7 + (k % 3) * 0.1, 1.2 + k * 0.025, -0.05 + (k % 2) * 0.08), Color(1, 0.8, 0.25))
	var fur := Art3D.box(self, Vector3(0.9, 0.04, 0.7), Vector3(-LENGTH / 2.0 + 0.7, 1.08, 0), Color(0.82, 0.7, 0.52))
	fur.rotation.y = 0.3
	Art3D.bake(self)
