# Captura de pantalla del juego con una partida de ejemplo (para revisar el arte).
# Uso: xvfb-run godot --rendering-driver opengl3 res://tests/captura.tscn
extends Node

const OUT := "/tmp/claude-0/sim/captura_%d.png"


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(720, 1558)
	GameState._reset_values()
	GameState.levels = [27, 12, 3, 0, 0]
	GameState.coins = 4200.0
	GameState.purchased = {"dep2": true}
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for k in 3:
		await get_tree().create_timer(4.0 + k * 2.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT % k)
		print("captura ", k, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objetos=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " fps=", Engine.get_frames_per_second())
	get_tree().quit()
