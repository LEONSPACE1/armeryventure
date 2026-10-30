# Captura de pantalla del juego con una partida de ejemplo (para revisar el arte).
# Uso: xvfb-run godot --rendering-driver opengl3 res://tests/captura.tscn
extends Node

const OUT := "/tmp/claude-0/sim/captura_%d.png"


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(720, 1558)
	# Época a capturar: godot ... res://tests/captura.tscn -- --epoca=1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--epoca="):
			GameState._load_era(int(arg.split("=")[1]))
	GameState._reset_values()
	GameState.levels = [27, 12, 3, 0, 0]
	# Niveles a mano (p. ej. --niveles=100,75,50,25,1 para ver bancos llenos de armeros)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--niveles="):
			GameState.levels = Array(arg.split("=")[1].split(",")).map(func(v): return int(v))
	GameState.coins = 4200.0
	GameState.purchased = {"dep2": true}
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for k in 3:
		await get_tree().create_timer(4.0 + k * 2.0).timeout
		# Segunda captura: panel de la estación; tercera: misiones desplegadas
		if k == 1:
			main._select(0)
		elif k == 2:
			main._open_window(main._missions_panel)
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT % k)
		print("captura ", k, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objetos=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " fps=", Engine.get_frames_per_second())
	get_tree().quit()
