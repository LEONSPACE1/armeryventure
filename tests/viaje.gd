# Prueba del viaje entre épocas: completa las misiones de la Prehistoria,
# viaja y revisa que la partida quede en la Edad del Bronce desde cero.
# Uso: godot --headless res://tests/viaje.tscn
extends Node


func _ready() -> void:
	GameState._load_era(0)
	GameState._reset_values()
	for m in GameState.era["misiones"]:
		GameState.claimed[m["id"]] = true
	GameState.coins = 12345.0
	print("antes: época=%s puede_viajar=%s" % [GameState.era["id"], GameState.can_travel()])
	GameState.travel(false)
	var ok: bool = GameState.era["id"] == "bronce" and GameState.coins == 0.0 and GameState.stars() == 0
	GameState.load_game()
	ok = ok and GameState.era["id"] == "bronce"
	print("después: época=%s monedas=%s estrellas=%d guardado_ok=%s" % [GameState.era["id"], GameState.coins, GameState.stars(), ok])
	print("RESULTADO: " + ("OK" if ok else "FALLO"))
	get_tree().quit()
