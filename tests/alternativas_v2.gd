# Primer plano del armero de la Prehistoria con cada alternativa de assets gratuitos.
# Los modelos van en res://_alt/ (no se suben al repo).
# Uso: xvfb-run godot --rendering-driver opengl3 res://tests/alternativas_v2.tscn -- <alternativa> <salida.png>
# Alternativas: kenney, kaykit, quaternius, polypizza, texturas
extends Node

const A := "res://_alt/"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var alt: String = args[0] if args.size() > 0 else "kenney"
	var out: String = args[1] if args.size() > 1 else "/tmp/alt.png"
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
	var st = main.stations[0]
	cam.h_offset = st.position.x
	for j in 3:
		var y: float = main._screen(st.position).y
		cam.v_offset -= (y - 430.0) / (720.0 / cam.size)
	# Acabado común de la "versión final": bordes suaves y color un poco más vivo
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var env: Environment = _find_env(main)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.12
	st.set_process(false)
	var bench: Node3D = st._bench
	var smith: Node3D = st._smiths[0]
	var smith_pos: Vector3 = smith.position
	if alt != "texturas":
		smith.visible = false
		for e in st._embers + st._sparks + st._parts + st._crafting:
			e.visible = false
	match alt:
		"kenney":
			_hide_bench_meshes(bench)
			var t := _place(bench, A + "kenney_table.glb", Vector3(0, 0, 0), "width", 2.4)
			if t == null:
				_show_bench_meshes(bench)
			_place(bench, A + "character-male-d.glb", smith_pos, "height", 1.75)
			_place(bench, A + "weapon-sword.glb", Vector3(0.55, _top(bench), 0.15), "height", 0.55, Vector3(PI / 2, 0, 0.3))
			_place(bench, A + "weapon-spear.glb", Vector3(-0.1, _top(bench), 0.25), "height", 0.9, Vector3(PI / 2, 0, PI / 2))
			_place(bench, A + "shield-round.glb", Vector3(-0.8, _top(bench) + 0.02, 0.0), "height", 0.4, Vector3(-PI / 2 + 0.2, 0, 0))
		"kaykit":
			_place(bench, A + "kaykit_barbarian.glb", smith_pos, "height", 1.8)
			_place(bench, A + "kaykit_assets/axe_1handed.gltf", Vector3(0.45, 1.03, 0.1), "height", 0.7, Vector3(0, 0.3, PI / 2))
			_place(bench, A + "kaykit_assets/axe_1handed.gltf", Vector3(-0.15, 1.03, 0.2), "height", 0.7, Vector3(0, -0.2, PI / 2))
		"quaternius":
			_place(bench, A + "armeryventure_pp_quaternius_blacksmith.glb", Vector3(0, 0, -2.6), "width", 3.2)
			_place(bench, A + "armeryventure_pp_quaternius_characters_matt.glb", smith_pos, "height", 1.7)
		"polypizza":
			_place(bench, A + "armeryventure_pp_zsky_ccby_black_smith_shop.glb", Vector3(0, 0, -2.6), "width", 3.0)
			_place(bench, A + "character-male-b.glb", smith_pos, "height", 1.6)
			_place(bench, A + "kaykit_assets/axe_1handed.gltf", Vector3(0.45, 1.03, 0.1), "height", 0.7, Vector3(0, 0.3, PI / 2))
		"texturas":
			var wood := load(A + "armeryventure_polyhaven_wood_table_001_diff_1k.jpg") as Texture2D
			var rock := load(A + "armeryventure_polyhaven_rock_wall_08_diff_1k.jpg") as Texture2D
			_texture_meshes(main._world, rock, 0.35, [smith, bench], main)
			_texture_meshes(bench, wood, 0.8, [smith], main, true)
	for k in 6:
		await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


# Aplica una textura (triplanar) a las mallas bajo `root`, sin entrar en `skip`
func _texture_meshes(root: Node, tex: Texture2D, scale: float, skip: Array, main, plain := false) -> void:
	if root in skip:
		return
	if root != main._world and root.get_script() != null and root.get_script().resource_path.ends_with("person3d.gd"):
		return
	if root is MeshInstance3D and root.visible:
		var m0 = root.material_override
		if m0 == null and root.mesh and root.mesh.get_surface_count() > 0:
			m0 = root.mesh.surface_get_material(0)
		if m0 is StandardMaterial3D and not m0.emission_enabled and m0.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			var m: StandardMaterial3D = m0.duplicate()
			m.albedo_texture = tex
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * scale
			m.albedo_color = Color(1.6, 1.5, 1.4)
			if plain:
				m.vertex_color_use_as_albedo = false
				m.albedo_color = Color(1.5, 1.25, 1.05)
			root.material_override = m
	for c in root.get_children():
		_texture_meshes(c, tex, scale, skip, main, plain)


func _top(_bench: Node3D) -> float:
	return 0.98


func _hide_bench_meshes(bench: Node3D) -> void:
	for c in bench.get_children():
		if c is MeshInstance3D:
			c.visible = false


func _show_bench_meshes(bench: Node3D) -> void:
	for c in bench.get_children():
		if c is MeshInstance3D:
			c.visible = true


# Carga un modelo, lo escala para que mida `size` en alto o ancho y lo apoya en `pos`
func _place(parent: Node3D, path: String, pos: Vector3, mode: String, size: float, rot := Vector3.ZERO) -> Node3D:
	if not ResourceLoader.exists(path):
		push_warning("Falta " + path)
		return null
	var scn := load(path) as PackedScene
	var holder := Node3D.new()
	var inst := scn.instantiate() as Node3D
	holder.add_child(inst)
	parent.add_child(holder)
	holder.rotation = rot
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		var names := ap.get_animation_list()
		print(path, " anims: ", names)
		for want in ["Idle", "idle", "Idle_Neutral", "Unarmed_Idle"]:
			if want in names:
				ap.play(want)
				break
	var box := _aabb(inst, inst.global_transform.affine_inverse())
	var dim := box.size.y if mode == "height" else maxf(box.size.x, box.size.z)
	if dim <= 0.0:
		return holder
	var s := size / dim
	inst.scale = Vector3.ONE * s
	# centrar en x/z y apoyar la base en y
	if rot == Vector3.ZERO:
		inst.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * s
	else:
		inst.position = -box.get_center() * s
	holder.position = pos
	return holder


func _aabb(n: Node, inv: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "VisualInstance3D", true, false):
		if not (mi is MeshInstance3D):
			continue
		var b: AABB = (inv * mi.global_transform) * mi.get_aabb()
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out


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
