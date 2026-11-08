# Primer plano de un armero en su banco con distintos estilos de gráficos.
# Uso: xvfb-run godot --rendering-driver opengl3 res://tests/estilos_v2.tscn -- <estilo> <salida.png>
# Estilos: actual, msaa, glow, color, contorno, toon, combinado
extends Node

const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front;
uniform vec4 color : source_color = vec4(0.12, 0.07, 0.04, 1.0);
uniform float grow = 0.035;
void vertex() { VERTEX += NORMAL * grow; }
void fragment() { ALBEDO = color.rgb; }
"""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var style: String = args[0] if args.size() > 0 else "actual"
	var out: String = args[1] if args.size() > 1 else "/tmp/estilo.png"
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(720, 720)
	GameState._reset_values()
	GameState.levels = [5, 0, 0, 0, 0]
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(3.0).timeout
	main._ui.visible = false
	var cam: Camera3D = main._camera
	cam.size = 3.6
	cam.h_offset = main.stations[0].position.x
	for j in 3:
		var y: float = main._screen(main.stations[0].position).y
		cam.v_offset -= (y - 430.0) / (720.0 / cam.size)
	var env: Environment = _find_env(main)
	var all := style == "combinado"
	if style == "msaa" or all:
		get_viewport().msaa_3d = Viewport.MSAA_4X
	if style == "glow" or all:
		env.glow_enabled = true
		env.glow_intensity = 0.7
		env.glow_strength = 1.0
		env.glow_bloom = 0.03
		env.glow_hdr_threshold = 0.85
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	if style == "color" or all:
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.06
		env.adjustment_contrast = 1.08
		env.adjustment_saturation = 1.15
	if style == "toon" or all:
		_each_mat(main, func(m: StandardMaterial3D):
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			m.specular_mode = BaseMaterial3D.SPECULAR_TOON)
	if style == "contorno" or all:
		var sm := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = OUTLINE_SHADER
		sm.shader = sh
		_each_mat(main, func(m: StandardMaterial3D):
			if m.emission_enabled or m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				return
			m.next_pass = sm)
	for k in 6:
		await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


func _find_env(n: Node) -> Environment:
	if n is WorldEnvironment:
		return n.environment
	for c in n.get_children():
		var e := _find_env(c)
		if e:
			return e
	return null


func _each_mat(n: Node, f: Callable, seen := {}) -> void:
	if n is MeshInstance3D:
		var mats: Array = [n.material_override]
		if n.mesh:
			for i in n.mesh.get_surface_count():
				mats.append(n.mesh.surface_get_material(i))
		for m in mats:
			if m is StandardMaterial3D and not seen.has(m):
				seen[m] = true
				f.call(m)
	for c in n.get_children():
		_each_mat(c, f, seen)
