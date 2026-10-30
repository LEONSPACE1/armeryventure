# Mostrador donde esperan los clientes (colores según la época).
extends Node3D

const LENGTH := 7.6


func _ready() -> void:
	Art3D.box(self, Vector3(LENGTH, 0.95, 0.85), Vector3(0, 0.47, 0), Color(GameState.theme("mostrador_base", "#73695f")))
	Art3D.box(self, Vector3(LENGTH + 0.15, 0.12, 1.0), Vector3(0, 1.0, 0), Color(GameState.theme("mostrador_tapa", "#996b42")))
	# Piedras en la cara frontal
	var x := -LENGTH / 2.0 + 0.4
	var row := 0
	while x < LENGTH / 2.0 - 0.3:
		Art3D.box(self, Vector3(0.55, 0.25, 0.04), Vector3(x, 0.3 + (row % 2) * 0.32, 0.43), Color(GameState.theme("mostrador_base", "#73695f")).lightened(0.15))
		x += 0.62
		row += 1
	# Cuenco de monedas y una piel sobre el mostrador
	Art3D.cyl(self, 0.28, 0.2, 0.14, Vector3(LENGTH / 2.0 - 0.6, 1.12, 0), Color(0.38, 0.24, 0.12))
	for k in 5:
		Art3D.cyl(self, 0.09, 0.09, 0.04, Vector3(LENGTH / 2.0 - 0.7 + (k % 3) * 0.1, 1.2 + k * 0.025, -0.05 + (k % 2) * 0.08), Color(1, 0.8, 0.25))
	var fur := Art3D.box(self, Vector3(0.9, 0.04, 0.7), Vector3(-LENGTH / 2.0 + 0.7, 1.08, 0), Color(0.82, 0.7, 0.52))
	fur.rotation.y = 0.3
	Art3D.bake(self)
