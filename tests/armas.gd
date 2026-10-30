# Junta los íconos de todas las armas de todas las épocas en una sola imagen.
# Uso (necesita pantalla o Xvfb): godot --rendering-driver opengl3 res://tests/armas.tscn
extends Node

const OUT := "/tmp/claude-0/sim/armas.png"


func _ready() -> void:
	var ids := []
	for e in GameState.era_ids.size():
		GameState._load_era(e)
		for i in GameState.station_count():
			ids.append(GameState.station(i)["id"])
	for id in ids:
		WeaponIcons.texture(id)
	var pending := true
	while pending:
		await get_tree().process_frame
		pending = false
		for id in ids:
			if WeaponIcons.texture(id) == null:
				pending = true
	var s := WeaponIcons.SIZE
	var grid := Image.create(s * 5, s * 8, false, Image.FORMAT_RGBA8)
	grid.fill(Color(0.93, 0.88, 0.8))
	for k in ids.size():
		var img: Image = WeaponIcons.texture(ids[k]).get_image()
		img.convert(Image.FORMAT_RGBA8)
		grid.blend_rect(img, Rect2i(0, 0, s, s), Vector2i((k % 5) * s, (k / 5) * s))
	grid.save_png(OUT)
	print("guardado ", ids.size(), " armas")
	get_tree().quit()
