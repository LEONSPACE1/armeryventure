# Prueba del viaje entre épocas: completa las misiones de cada época, viaja y
# revisa que la partida siga en la época nueva desde cero, hasta la última.
# Uso: godot --headless res://tests/viaje.tscn
extends Node


func _ready() -> void:
	GameState._load_era(0)
	GameState._reset_values()
	var ok := true
	var expected := 1
	while GameState.has_next_era():
		for m in GameState.era["misiones"]:
			GameState.claimed[m["id"]] = true
		GameState.coins = 12345.0
		var from: String = GameState.era["id"]
		GameState.travel(false)
		var fresh: bool = GameState.coins == 0.0 and GameState.stars() == 0 and GameState.era_index == expected
		GameState.load_game()
		var saved: bool = GameState.era["id"] == GameState.era_ids[expected]
		print("%s -> %s  desde_cero=%s guardado=%s" % [from, GameState.era["id"], fresh, saved])
		ok = ok and fresh and saved
		expected += 1
	# En la última época no hay a dónde viajar aunque se completen las misiones
	for m in GameState.era["misiones"]:
		GameState.claimed[m["id"]] = true
	var last_ok: bool = not GameState.can_travel() and not GameState.travel(false) and GameState.era["id"] == "futurista"
	print("última época: %s  viaje_bloqueado=%s" % [GameState.era["id"], last_ok])
	ok = ok and last_ok and expected == GameState.era_ids.size()
	print("RESULTADO: " + ("OK" if ok else "FALLO"))
	get_tree().quit()
