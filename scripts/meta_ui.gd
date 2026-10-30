# Paneles de Cofres, Maestros y Equipo. Usa los ayudantes de interfaz de main.gd
# (_sheet, _label, _button, _icon_view, _box) para verse igual que el resto.
extends RefCounted

const SLOT_ORDER := ["delantal", "martillo", "guantes", "gafas"]

var main
var chests_panel: PanelContainer
var rewards_panel: PanelContainer
var masters_panel: PanelContainer
var chests_badge: Control
var masters_badge: Control
var _gems_label: Label
var _chests_box: VBoxContainer
var _chests_header: Label
var _rewards_box: VBoxContainer
var _masters_box: VBoxContainer
var _masters_header: Label
var _tab := "maestros"
var _tab_buttons: Dictionary = {}


func _init(m) -> void:
	main = m


# Gemas y botones de la barra superior (antes del fondo oscuro de los paneles).
func build_hud() -> void:
	# Gemas, debajo de las monedas
	var gp: PanelContainer = main._pill(Vector2(10, 104), Vector2(210, 58))
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 8)
	gp.add_child(grow)
	main._icon_view("gema", 40, grow).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gems_label = main._label("0", 28, grow, 6)
	_gems_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	# Botones redondos a la derecha, debajo de los ajustes
	var cb: Button = main._square_button("cofre_oro", "", Vector2(630, 104), 78, func(): open_chests())
	cb.get_meta("icon").custom_minimum_size = Vector2(52, 52)
	chests_badge = main._badge(cb)
	var mb: Button = main._square_button("maestro", "", Vector2(630, 192), 78, func(): open_masters())
	mb.get_meta("icon").custom_minimum_size = Vector2(52, 52)
	masters_badge = main._badge(mb)


func build_panels() -> void:
	# Cofres
	chests_panel = main._sheet("Cofres", 760.0)
	var cv: VBoxContainer = chests_panel.get_meta("content")
	_chests_header = main._label("", 21, cv, 4)
	_chests_header.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	_chests_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chests_header.custom_minimum_size.x = 680
	_chests_box = VBoxContainer.new()
	_chests_box.add_theme_constant_override("separation", 12)
	cv.add_child(_chests_box)

	# Resultado de abrir un cofre
	rewards_panel = main._sheet("¡Cofre abierto!", 820.0)
	var rv: VBoxContainer = rewards_panel.get_meta("content")
	var rs := ScrollContainer.new()
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(rs)
	_rewards_box = VBoxContainer.new()
	_rewards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rewards_box.add_theme_constant_override("separation", 8)
	rs.add_child(_rewards_box)
	main._button("¡Genial!", rv, func(): open_chests(), "BuyButton")

	# Maestros y equipo
	masters_panel = main._sheet("Maestros", 1000.0)
	var mv: VBoxContainer = masters_panel.get_meta("content")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	mv.add_child(tabs)
	for t in [["maestros", "Maestros"], ["equipo", "Equipo"]]:
		var key: String = t[0]
		var b: Button = main._button(t[1], tabs, func(): _set_tab(key), "PillButton")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tab_buttons[key] = b
	_masters_header = main._label("", 19, mv, 4)
	_masters_header.add_theme_color_override("font_color", Color(0.9, 0.84, 0.72))
	_masters_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_masters_header.custom_minimum_size.x = 680
	var ms := ScrollContainer.new()
	ms.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ms.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mv.add_child(ms)
	_masters_box = VBoxContainer.new()
	_masters_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_masters_box.add_theme_constant_override("separation", 10)
	ms.add_child(_masters_box)

	# Diferido: los botones que cambian el estado se reconstruyen en el cuadro siguiente
	Meta.changed.connect(refresh, CONNECT_DEFERRED)
	refresh()


func refresh() -> void:
	_gems_label.text = str(Meta.gems)
	main._set_badge(chests_badge, Meta.chests_owned())
	main._set_badge(masters_badge, Meta.pending_actions())
	if main._open_sheet == chests_panel:
		_refresh_chests()
	elif main._open_sheet == masters_panel:
		_refresh_masters()


# Los globos laten igual que los de la barra inferior.
func animate() -> void:
	main._set_badge(chests_badge, Meta.chests_owned())
	main._set_badge(masters_badge, Meta.pending_actions())


func open_chests() -> void:
	_refresh_chests()
	main._open_window(chests_panel)


func open_masters() -> void:
	_refresh_masters()
	main._open_window(masters_panel)


func _clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _card(parent: Control, border := Color(0.55, 0.38, 0.2), bg := Color(0.32, 0.22, 0.13)) -> HBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", main._box(bg, border, 12, 4))
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	return row


func _texts(row: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	return v


func _pct(x: float) -> String:
	return "+%d %%" % roundi(x * 100.0)


# --- Cofres ---------------------------------------------------------------------

func _refresh_chests() -> void:
	_clear(_chests_box)
	_chests_header.text = "Gemas: %d  ·  Fichas: %d  ·  Ganas gemas con cada misión y cofres de madera cada %d misiones." % [
		Meta.gems, Meta.tokens, int(Meta.data["recompensas"]["cofre_madera_cada_misiones"])]
	for kind in Meta.data["cofres"]:
		var c: Dictionary = Meta.data["cofres"][kind]
		var row := _card(_chests_box)
		main._icon_view("cofre_" + kind, 84, row)
		var tv := _texts(row)
		main._label(c["nombre"], 24, tv, 5).add_theme_color_override("font_color", main.GOLD)
		var odds := []
		for r in Meta.RARITIES:
			var p := float(c["probabilidad"].get(r, 0.0))
			if p > 0.0:
				odds.append("%s %s %%" % [Meta.rarity_name(r).to_lower(), str(snappedf(p * 100.0, 0.1)).trim_suffix(".0")])
		var desc: String = "%d cartas  ·  %s" % [int(c["cartas"]), ", ".join(odds)]
		if c.has("garantiza"):
			desc += "  ·  al menos un %s" % Meta.rarity_name(c["garantiza"]).to_lower()
		var dl: Label = main._label(desc, 16, tv, 3)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size.x = 330
		var owned := int(Meta.chests.get(kind, 0))
		var b: Button
		if owned > 0:
			b = main._button("Abrir (%d)" % owned, row, func(): _open_chest(kind), "ClaimButton")
		else:
			b = main._button(str(Meta.chest_price(kind)), row, func(): _open_chest(kind), "BuyButton")
			b.disabled = not Meta.can_open(kind)
			var gi: Control = main._icon_view("gema", 30, b)
			gi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			gi.position = Vector2(14, 17)
		b.custom_minimum_size = Vector2(170, 70)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _open_chest(kind: String) -> void:
	var rewards: Array = Meta.open_chest(kind)
	if rewards.is_empty():
		return
	_clear(_rewards_box)
	(rewards_panel.get_meta("title") as Label).text = "¡%s abierto!" % Meta.data["cofres"][kind]["nombre"]
	for rw in rewards:
		var color := Color(0.6, 0.9, 1.0)
		var icon := "gema"
		var name := "%d gemas" % int(rw.get("cantidad", 0))
		var note := ""
		if rw["tipo"] == "maestro":
			var m := Meta.master_info(rw["id"])
			icon = "maestro"
			name = m["nombre"]
			color = Meta.rarity_color(rw["rareza"])
			note = "¡Nuevo maestro!" if rw["nuevo"] else "+1 copia"
		elif rw["tipo"] == "equipo":
			var g := Meta.gear_info(rw["id"])
			icon = g["ranura"]
			name = g["nombre"]
			color = Meta.rarity_color(rw["rareza"])
			if rw["nuevo"]:
				note = "¡Nuevo!"
			elif int(rw.get("gemas", 0)) > 0:
				note = "Ya al máximo: +%d gemas" % int(rw["gemas"])
			else:
				note = "Sube a nivel %d" % int(Meta.gear[rw["id"]])
		var row := _card(_rewards_box, color)
		main._icon_view(icon, 60, row)
		var tv := _texts(row)
		main._label(name, 22, tv, 5).add_theme_color_override("font_color", color)
		var sub := note
		if rw.has("rareza"):
			sub = Meta.rarity_name(rw["rareza"]) + ("  ·  " + note if note != "" else "")
		main._label(sub, 17, tv, 3)
	main._open_window(rewards_panel)


# --- Maestros y equipo ----------------------------------------------------------

func _set_tab(t: String) -> void:
	_tab = t
	_refresh_masters()


func _bonus_summary() -> String:
	var parts := []
	for tipo in Meta.data["bonos"]:
		var b: float = Meta.bonus(tipo) - 1.0
		if b > 0.0:
			parts.append("%s %s" % [Meta.bonus_name(tipo), _pct(b)])
	return "Bonos activos: " + (", ".join(parts) if not parts.is_empty() else "ninguno todavía (abre cofres)")


func _refresh_masters() -> void:
	_clear(_masters_box)
	(masters_panel.get_meta("title") as Label).text = "Maestros" if _tab == "maestros" else "Equipo"
	for k in _tab_buttons:
		_tab_buttons[k].theme_type_variation = "ClaimButton" if k == _tab else "PillButton"
	if _tab == "maestros":
		_masters_header.text = "Fichas: %d  ·  Activos: %d/%d  ·  %s" % [Meta.tokens, Meta.active.size(), Meta.master_slots(), _bonus_summary()]
		_fill_masters()
	else:
		_masters_header.text = "Una pieza por ranura. Los bonos se conservan entre épocas.  ·  " + _bonus_summary()
		_fill_gear()


func _fill_masters() -> void:
	var list: Array = Meta.data["maestros"].duplicate()
	# Primero los que tiene (activos arriba), luego los que faltan; dentro, por rareza
	list.sort_custom(func(a, b): return _order(a) < _order(b))
	for m in list:
		var id: String = m["id"]
		var owned := Meta.masters.has(id)
		var color := Meta.rarity_color(m["rareza"])
		var row := _card(_masters_box, color if owned else Color(0.35, 0.3, 0.25), Color(0.32, 0.22, 0.13) if owned else Color(0.2, 0.15, 0.1))
		var iv: Control = main._icon_view("maestro", 64, row)
		iv.modulate = Color.WHITE if owned else Color(0, 0, 0, 0.6)
		var tv := _texts(row)
		var era_name := _era_name(m["epoca"])
		if not owned:
			main._label("???", 22, tv, 5).add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
			main._label("%s  ·  %s  ·  %s" % [Meta.rarity_name(m["rareza"]), era_name, Meta.bonus_name(m["bono"])], 16, tv, 3)
			continue
		var lv := int(Meta.masters[id]["nivel"])
		main._label(m["nombre"], 22, tv, 5).add_theme_color_override("font_color", color)
		main._label("Nivel %d  ·  %s %s  ·  %s" % [lv, Meta.bonus_name(m["bono"]), _pct(Meta.master_bonus(id)), era_name], 16, tv, 3)
		if lv < Meta.max_level():
			main._label("Para subir: copias %d/%d, fichas %d/%d" % [int(Meta.masters[id]["copias"]), Meta.copies_needed(id), Meta.tokens, Meta.tokens_needed(id)], 15, tv, 3).add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
		else:
			main._label("Nivel máximo", 15, tv, 3).add_theme_color_override("font_color", main.GOLD)
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 6)
		row.add_child(bv)
		var is_active: bool = id in Meta.active
		var t: Button = main._button("Quitar" if is_active else "Activar", bv, func(): Meta.toggle_master(id), "PillButton" if is_active else "BuyButton")
		t.custom_minimum_size = Vector2(130, 52)
		t.disabled = not is_active and Meta.active.size() >= Meta.master_slots()
		if Meta.can_level_master(id):
			var up: Button = main._button("Subir", bv, func(): Meta.level_master(id), "ClaimButton")
			up.custom_minimum_size = Vector2(130, 52)


func _fill_gear() -> void:
	for slot in SLOT_ORDER:
		var info: Dictionary = Meta.data["ranuras_equipo"][slot]
		var row := _card(_masters_box)
		main._icon_view(slot, 64, row)
		var tv := _texts(row)
		main._label("%s  ·  %s" % [info["nombre"], Meta.bonus_name(info["bono"])], 20, tv, 4).add_theme_color_override("font_color", main.GOLD)
		if Meta.equipped.has(slot):
			var id: String = Meta.equipped[slot]
			var g := Meta.gear_info(id)
			main._label("%s (nivel %d)  %s" % [g["nombre"], int(Meta.gear[id]), _pct(Meta.gear_bonus(id))], 18, tv, 3).add_theme_color_override("font_color", Meta.rarity_color(g["rareza"]))
		else:
			main._label("Vacío: sale en los cofres", 18, tv, 3)
		# Las demás piezas de esta ranura que ya tiene, para cambiar
		for g in Meta.data["equipo"]:
			var gid: String = g["id"]
			if g["ranura"] != slot or not Meta.gear.has(gid) or Meta.equipped.get(slot, "") == gid:
				continue
			var b: Button = main._button("Poner %s %s" % [g["nombre"], _pct(Meta.gear_bonus(gid))], tv, func(): Meta.equip(gid), "PillButton")
			b.custom_minimum_size = Vector2(0, 48)
			b.add_theme_font_size_override("font_size", 18)
			b.add_theme_color_override("font_color", Meta.rarity_color(g["rareza"]))


func _order(m: Dictionary) -> int:
	var group := 0 if m["id"] in Meta.active else (1 if Meta.masters.has(m["id"]) else 2)
	return group * 10 - Meta.RARITIES.find(m["rareza"])


func _era_name(era_id: String) -> String:
	var names := {"prehistoria": "Prehistoria", "bronce": "Edad del Bronce", "antiguedad": "Antigüedad",
		"medieval": "Edad Media", "polvora": "Era de la pólvora", "industrial": "Era industrial",
		"moderna": "Era moderna", "futurista": "Era futurista"}
	return names.get(era_id, era_id)
