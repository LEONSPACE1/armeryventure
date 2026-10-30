# Capturas de los paneles de Cofres, Maestros y Equipo.
# Uso: xvfb-run godot --rendering-driver opengl3 res://tests/captura_meta.tscn
extends Node

const OUT := "/tmp/claude-0/sim/meta_%d.png"


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(720, 1558)
	Meta.reset_game()
	GameState._load_era(2)
	GameState._reset_values()
	GameState.levels = [27, 12, 3, 0, 0]
	Meta.gems = 420
	Meta.tokens = 30
	Meta.chests = {"madera": 2}
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 3:
		Meta.chests["plata"] = 1
		Meta.open_chest("plata", rng)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(3.0).timeout
	var ui = main._meta_ui
	var steps := [
		func(): pass,
		func(): ui.open_chests(),
		func(): ui._open_chest("oro"),
		func(): ui.open_masters(),
		func(): ui._set_tab("equipo"),
	]
	for k in steps.size():
		steps[k].call()
		await get_tree().create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT % k)
		print("captura ", k, " cofres: ", ui.chests_panel.visible, " ", ui.chests_panel.position, " ", ui.chests_panel.size)
	Meta.reset_game()
	get_tree().quit()
