# Íconos de armas sacados de sus modelos 3D (un solo dibujo por arma).
# Cada ícono se fotografía una vez en un SubViewport y queda guardado.
# Sin tarjeta gráfica (pruebas sin pantalla) no hay foto y se usa el dibujo 2D.
extends Node

signal icon_ready(id: String)

const SIZE := 128

var _cache: Dictionary = {}   # id -> Texture2D, o null si no se pudo
var _queue: Array = []
var _busy := false
var _vp: SubViewport
var _holder: Node3D
var _cam: Camera3D


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(SIZE, SIZE)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 0.95, 0.9)
	e.ambient_light_energy = 0.55
	env.environment = e
	_vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -30, 0)
	sun.light_energy = 0.9
	_vp.add_child(sun)
	_cam = Camera3D.new()
	var cam := _cam
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.55
	cam.position = Vector3(0, 0, 5)
	_vp.add_child(cam)
	_holder = Node3D.new()
	_vp.add_child(_holder)


# Devuelve el ícono si ya está listo; si no, lo encarga y devuelve null.
func texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	if id not in _queue:
		_queue.append(id)
		if not _busy:
			_render_next()
	return null


func _render_next() -> void:
	_busy = true
	while not _queue.is_empty():
		var id: String = _queue[0]
		for c in _holder.get_children():
			_holder.remove_child(c)
			c.queue_free()
		var w := Art3D.weapon(id)
		# En diagonal, como en los íconos de los juegos de armas
		w.rotation = Vector3(0.25, 0.35, -PI / 4)
		_holder.add_child(w)
		_frame(w)
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		_cache[id] = ImageTexture.create_from_image(img) if img and not img.is_empty() else null
		_queue.pop_front()
		icon_ready.emit(id)
	_busy = false


# Centra la cámara en el arma y la acerca para que llene el ícono.
func _frame(w: Node3D) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for mi in w.get_children():
		if not mi is MeshInstance3D:
			continue
		var box: AABB = mi.get_aabb()
		for k in 8:
			var p: Vector3 = w.transform * (mi.transform * box.get_endpoint(k))
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	if lo.x == INF:
		return
	var c := (lo + hi) / 2.0
	_cam.position = Vector3(c.x, c.y, 5)
	_cam.size = maxf(hi.x - lo.x, hi.y - lo.y) * 1.12
