# Pantalla completa de una época con los personajes y props de KayKit (CC0).
# Los modelos van en res://_alt/ (no se suben al repo).
# Uso: xvfb-run godot --rendering-driver opengl3 res://tests/kaykit_epocas_v2.tscn -- <epoca> <salida.png>
extends Node

const A := "res://_alt/"
const PERSON := "res://scripts/person3d.gd"
const CLIENTES := ["kaykit_Knight", "kaykit_Mage", "kaykit_Rogue_Hooded", "kaykit_barbarian"]

var _main
var _n := 0
var _cache := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var era := int(args[0]) if args.size() > 0 else 0
	var out: String = args[1] if args.size() > 1 else "/tmp/kk.png"
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(720, 1558)
	GameState._load_era(era)
	GameState._reset_values()
	GameState.levels = [27, 12, 3, 0, 0]
	GameState.coins = 4200.0
	GameState.purchased = {"dep2": true}
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	await get_tree().process_frame
	var env := _find_env(_main)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.12
	if era <= 4:
		_props()
	await get_tree().create_timer(9.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


func _process(_delta: float) -> void:
	if _main == null:
		return
	for p in _main.find_children("*", "Node3D", true, false):
		if p.get_script() == null or p.get_script().resource_path != PERSON:
			continue
		if not p.has_meta("kk"):
			_swap(p)
		var ap: AnimationPlayer = p.get_meta("kk")
		if ap:
			var want := "Walking_A" if p.walking else ("1H_Melee_Attack_Chop" if p.with_hammer and p.pose == 2 else "Idle")
			if ap.current_animation != want and ap.has_animation(want):
				ap.play(want, 0.2)


# Cambia el cuerpo hecho por código por un personaje KayKit de la misma altura
func _swap(p: Node3D) -> void:
	if p._body == null:
		return
	var h := 1.75 * p.scale.y
	var name: String
	if p.with_hammer:
		name = "kaykit_barbarian"
	elif p.apron:
		name = "kaykit_Rogue"
	else:
		name = CLIENTES[_n % CLIENTES.size()]
		_n += 1
	var inst := (load(A + name + ".glb") as PackedScene).instantiate() as Node3D
	p.add_child(inst)
	var box := _aabb(inst, inst.global_transform.affine_inverse())
	var s := 1.6 / maxf(box.size.y, 0.01)
	inst.scale = Vector3.ONE * s
	inst.position = Vector3(0, -box.position.y * s, 0)
	p._body.visible = false
	if p._carry:
		p._carry.reparent(p, false)
		p._carry.position = Vector3(0, 0.95, 0.4)
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	p.set_meta("kk", ap)
	if ap:
		ap.play("Idle")
		ap.seek(randf() * 1.5, true)


# Barriles, cajas, estandartes y antorchas de KayKit Dungeon en las épocas antiguas
func _props() -> void:
	var w: Node3D = _main._world
	var bz: float = _main.BACK_WALL_Z
	var x := 4.77
	_put(w, "kkdg_barrel_large", Vector3(x, 0, bz + 3.0), 0.9)
	_put(w, "kkdg_crates_stacked", Vector3(-x, 0, bz + 3.2), 1.1)
	_put(w, "kkdg_barrel_small_stack", Vector3(x - 0.2, 0, bz + 4.2), 0.8)
	_put(w, "kkdg_box_stacked", Vector3(-x + 0.1, 0, bz + 4.4), 0.9)


func _put(parent: Node3D, file: String, pos: Vector3, height: float) -> void:
	var path := A + "armeryventure_" + file + ".glb"
	if not ResourceLoader.exists(path):
		push_warning("Falta " + path)
		return
	var inst := (load(path) as PackedScene).instantiate() as Node3D
	parent.add_child(inst)
	var box := _aabb(inst, inst.global_transform.affine_inverse())
	var s := height / maxf(box.size.y, 0.01)
	inst.scale = Vector3.ONE * s
	inst.position = pos - Vector3(box.get_center().x, box.position.y, box.get_center().z) * s


func _aabb(n: Node, inv: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
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
