# Renderiza la misma mini-armería en varios estilos y guarda una imagen de cada uno.
# Uso (necesita pantalla o Xvfb): godot --rendering-driver opengl3 --resolution 720x720 res://tests/estilos.tscn
extends Node

const OUT := "/mnt/project-files/armeryventure/estilos/"
const STYLES := ["vector", "contorno", "pixel", "lowpoly3d", "neon"]
const TITLES := {
	"vector": "1. Vectorial plano (el actual)",
	"contorno": "2. Caricatura con contorno grueso",
	"pixel": "3. Pixel art",
	"lowpoly3d": "4. 3D low-poly isométrico",
	"neon": "5. Neón (idea para la era futurista)",
}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(720, 720)
	for style in STYLES:
		var node := _build(style)
		add_child(node)
		var banner := _banner(TITLES[style])
		add_child(banner)
		for k in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(OUT + "estilo_%s.png" % style)
		print("guardado ", style, " ", img.get_size())
		node.queue_free()
		banner.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _banner(text: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.06, 0.03, 0.85)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(720, 64)
	layer.add_child(bg)
	var l := Label.new()
	l.text = text
	l.position = Vector2(20, 12)
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	layer.add_child(l)
	return layer


func _build(style: String) -> Node:
	match style:
		"vector":
			return _scene2d("vector")
		"contorno":
			return _scene2d("contorno")
		"neon":
			return _scene2d("neon")
		"pixel":
			var holder := Control.new()
			holder.size = Vector2(720, 720)
			var vp := SubViewport.new()
			vp.size = Vector2i(180, 180)
			vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			var scene := _scene2d("pixel")
			scene.scale = Vector2(0.25, 0.25)
			vp.add_child(scene)
			holder.add_child(vp)
			var tr := TextureRect.new()
			tr.texture = vp.get_texture()
			tr.size = Vector2(720, 720)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			holder.add_child(tr)
			return holder
		"lowpoly3d":
			return _scene3d()
	return Node.new()


func _scene2d(mode: String) -> Node2D:
	var n := Node2D.new()
	n.set_script(preload("res://tests/estilo_2d.gd"))
	n.mode = mode
	return n


# --- 3D low-poly --------------------------------------------------------------

func _mat(c: Color, emit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if emit:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 2.0
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, r: float, pos: Vector3, c: Color, emit := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = _mat(c, emit)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, top: float, bottom: float, h: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _spear(parent: Node3D, pos: Vector3, rot: Vector3) -> void:
	var s := Node3D.new()
	s.position = pos
	s.rotation_degrees = rot
	parent.add_child(s)
	_cyl(s, 0.045, 0.045, 1.6, Vector3.ZERO, Color(0.55, 0.35, 0.18))
	_cyl(s, 0.0, 0.11, 0.3, Vector3(0, 0.95, 0), Color(0.6, 0.62, 0.66))


func _person(parent: Node3D, pos: Vector3, outfit: Color, skin: Color, hair: Color, yaw := 0.0) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	p.rotation_degrees.y = yaw
	parent.add_child(p)
	_cyl(p, 0.11, 0.1, 0.5, Vector3(-0.15, 0.25, 0), skin.darkened(0.15))
	_cyl(p, 0.11, 0.1, 0.5, Vector3(0.15, 0.25, 0), skin.darkened(0.15))
	_cyl(p, 0.3, 0.38, 0.75, Vector3(0, 0.85, 0), outfit)
	_sphere(p, 0.34, Vector3(0, 1.55, 0), skin)
	var h := _sphere(p, 0.36, Vector3(0, 1.66, -0.04), hair)
	h.scale = Vector3(1, 0.6, 1)
	_sphere(p, 0.05, Vector3(-0.12, 1.58, 0.31), Color(0.1, 0.07, 0.05))
	_sphere(p, 0.05, Vector3(0.12, 1.58, 0.31), Color(0.1, 0.07, 0.05))
	return p


func _scene3d() -> Node3D:
	var root := Node3D.new()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.11, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.62, 0.5)
	e.ambient_light_energy = 0.3
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.7
	sun.light_color = Color(1, 0.92, 0.8)
	sun.shadow_enabled = true
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 9.5
	root.add_child(cam)
	cam.position = Vector3(9, 8.5, 9)
	cam.look_at_from_position(cam.position, Vector3(0, 0.6, 0.3))
	# Suelo y paredes de la cueva
	_box(root, Vector3(12, 0.2, 12), Vector3(0, -0.1, 0), Color(0.42, 0.31, 0.22))
	_box(root, Vector3(12, 3.2, 0.5), Vector3(0, 1.6, -6), Color(0.36, 0.3, 0.26))
	_box(root, Vector3(0.5, 3.2, 12), Vector3(-6, 1.6, 0), Color(0.32, 0.27, 0.23))
	for k in 5:
		_sphere(root, 0.5 + (k % 2) * 0.2, Vector3(-5.6, 3.1, -4.5 + k * 2.2), Color(0.3, 0.25, 0.21))
		_sphere(root, 0.5 + (k % 3) * 0.15, Vector3(-4.5 + k * 2.2, 3.1, -5.6), Color(0.3, 0.25, 0.21))
	# Antorcha con luz
	_cyl(root, 0.06, 0.08, 0.8, Vector3(-2, 1.8, -5.6), Color(0.35, 0.22, 0.12))
	_sphere(root, 0.16, Vector3(-2, 2.3, -5.6), Color(1, 0.6, 0.15), true)
	var torch := OmniLight3D.new()
	torch.position = Vector3(-2, 2.4, -5.0)
	torch.light_color = Color(1, 0.6, 0.25)
	torch.light_energy = 1.2
	torch.omni_range = 5.0
	root.add_child(torch)
	# Banco de trabajo, yunque de piedra y armero
	_box(root, Vector3(3.2, 0.9, 1.2), Vector3(-0.5, 0.45, -2.2), Color(0.62, 0.42, 0.24))
	_box(root, Vector3(3.3, 0.12, 1.3), Vector3(-0.5, 0.95, -2.2), Color(0.74, 0.53, 0.3))
	_box(root, Vector3(0.6, 0.35, 0.5), Vector3(-1.2, 1.18, -2.2), Color(0.55, 0.55, 0.58))
	_spear(root, Vector3(0.5, 1.05, -2.1), Vector3(0, 0, 80))
	var smith := _person(root, Vector3(-1.2, 0, -3.3), Color(0.55, 0.32, 0.18), Color(0.85, 0.65, 0.48), Color(0.2, 0.13, 0.08))
	_cyl(smith, 0.04, 0.04, 0.5, Vector3(0.38, 1.35, 0.25), Color(0.45, 0.28, 0.14)).rotation_degrees = Vector3(40, 0, 0)
	_box(smith, Vector3(0.25, 0.18, 0.18), Vector3(0.38, 1.58, 0.45), Color(0.55, 0.56, 0.6))
	# Mostrador, dependiente y clientes
	_box(root, Vector3(6, 1.0, 0.9), Vector3(0.5, 0.5, 1.6), Color(0.45, 0.41, 0.38))
	_box(root, Vector3(6.1, 0.12, 1.0), Vector3(0.5, 1.05, 1.6), Color(0.72, 0.52, 0.3))
	for k in 4:
		_cyl(root, 0.12, 0.12, 0.05, Vector3(2.6 + (k % 2) * 0.15, 1.14 + k * 0.05, 1.5), Color(1, 0.8, 0.25))
	var helper := _person(root, Vector3(1.8, 0, -0.5), Color(0.22, 0.5, 0.62), Color(0.96, 0.8, 0.65), Color(0.12, 0.1, 0.1), 30)
	_spear(helper, Vector3(0, 2.2, 0), Vector3(0, 0, 90))
	_person(root, Vector3(-1.2, 0, 3.0), Color(0.62, 0.42, 0.24), Color(0.68, 0.48, 0.33), Color(0.42, 0.26, 0.12), 180)
	_person(root, Vector3(1.6, 0, 3.0), Color(0.45, 0.5, 0.32), Color(0.96, 0.8, 0.65), Color(0.72, 0.5, 0.25), 180)
	_person(root, Vector3(3.8, 0, 3.4), Color(0.6, 0.3, 0.22), Color(0.52, 0.36, 0.24), Color(0.55, 0.53, 0.5), 200)
	return root
