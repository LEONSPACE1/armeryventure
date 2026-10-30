# Capturas de cerca de una estación para revisar la animación de fabricación.
# Uso: xvfb-run godot --rendering-driver opengl3 res://tests/primer_plano.tscn
extends Node

const OUT := "/tmp/claude-0/sim/cerca_%d.png"


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(720, 1558)
	GameState._reset_values()
	GameState.levels = [27, 0, 0, 0, 0]
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(4.0).timeout
	main._ui.visible = false
	var cam: Camera3D = main._camera
	cam.size = 3.2
	cam.h_offset = main.stations[0].position.x
	for j in 3:
		var y: float = main._screen(main.stations[0].position).y
		cam.v_offset -= (y - 820.0) / (720.0 / cam.size)
	for k in 8:
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT % k)
	get_tree().quit()
