# Progreso que se conserva entre épocas: gemas, fichas, cofres, maestros armeros
# y equipo. Los datos están en data/meta.json y la partida en user://meta.json.
extends Node

signal changed

const DATA_PATH := "res://data/meta.json"
const SAVE_PATH := "user://meta.json"
const RARITIES := ["comun", "raro", "epico", "legendario"]

var data: Dictionary = {}
var gems := 0
var tokens := 0                 # fichas de época
var chests: Dictionary = {}     # tipo de cofre -> cuántos tiene sin abrir
var masters: Dictionary = {}    # id -> {"nivel": n, "copias": n}
var active: Array = []          # ids de maestros activos (máximo ranuras_maestros)
var gear: Dictionary = {}       # id de equipo -> nivel
var equipped: Dictionary = {}   # ranura -> id de equipo
var missions_claimed := 0       # total histórico, para los cofres de madera


func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	_reset_values()
	load_game()


func _reset_values() -> void:
	gems = 0
	tokens = 0
	chests = {}
	for k in data["recompensas"]["cofres_iniciales"]:
		chests[k] = int(data["recompensas"]["cofres_iniciales"][k])
	masters = {}
	active = []
	gear = {}
	equipped = {}
	missions_claimed = 0


# --- Catálogo -------------------------------------------------------------------

func master_info(id: String) -> Dictionary:
	for m in data["maestros"]:
		if m["id"] == id:
			return m
	return {}


func gear_info(id: String) -> Dictionary:
	for g in data["equipo"]:
		if g["id"] == id:
			return g
	return {}


func rarity_name(r: String) -> String:
	return data["rarezas"][r]["nombre"]


func rarity_color(r: String) -> Color:
	return Color(data["rarezas"][r]["color"])


func bonus_name(tipo: String) -> String:
	return data["bonos"][tipo]


func max_level() -> int:
	return int(data["nivel_max"])


func master_slots() -> int:
	return int(data["ranuras_maestros"])


# --- Bonos ----------------------------------------------------------------------

# Bono de un maestro a su nivel actual (0.10 = +10 %).
func master_bonus(id: String, level := -1) -> float:
	var m := master_info(id)
	if level < 0:
		level = int(masters.get(id, {}).get("nivel", 1))
	var base := float(data["rarezas"][m["rareza"]]["maestro"])
	return base * (1.0 + float(data["bono_por_nivel_maestro"]) * (level - 1))


func gear_bonus(id: String, level := -1) -> float:
	var g := gear_info(id)
	if level < 0:
		level = int(gear.get(id, 1))
	var base := float(data["rarezas"][g["rareza"]]["equipo"])
	return base * (1.0 + float(data["bono_por_nivel_equipo"]) * (level - 1))


func gear_type(id: String) -> String:
	return data["ranuras_equipo"][gear_info(id)["ranura"]]["bono"]


# Multiplicador total de un tipo de bono: 1 + suma de maestros activos y equipo puesto.
func bonus(tipo: String) -> float:
	var total := 1.0
	for id in active:
		if master_info(id)["bono"] == tipo:
			total += master_bonus(id)
	for slot in equipped:
		if gear_type(equipped[slot]) == tipo:
			total += gear_bonus(equipped[slot])
	return total


# --- Recompensas ----------------------------------------------------------------

func on_mission_claimed() -> void:
	var r: Dictionary = data["recompensas"]
	missions_claimed += 1
	gems += int(r["gemas_por_mision"])
	if missions_claimed % int(r["cofre_madera_cada_misiones"]) == 0:
		chests["madera"] = int(chests.get("madera", 0)) + 1
	_changed()


func on_era_completed() -> void:
	var r: Dictionary = data["recompensas"]
	gems += int(r["gemas_por_epoca"])
	tokens += int(r["fichas_por_epoca"])
	var kind: String = r["cofre_por_epoca"]
	chests[kind] = int(chests.get(kind, 0)) + 1
	_changed()


func chests_owned() -> int:
	var n := 0
	for k in chests:
		n += int(chests[k])
	return n


# --- Cofres ---------------------------------------------------------------------

func chest_price(kind: String) -> int:
	return int(data["cofres"][kind]["precio"])


func can_open(kind: String) -> bool:
	return int(chests.get(kind, 0)) > 0 or gems >= chest_price(kind)


# Abre un cofre (gratis si hay uno guardado, si no con gemas) y devuelve lo que salió:
# una lista de {"tipo": "maestro"|"equipo"|"gemas", "id", "nuevo", "cantidad"}.
func open_chest(kind: String, rng: RandomNumberGenerator = null) -> Array:
	if not can_open(kind):
		return []
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if int(chests.get(kind, 0)) > 0:
		chests[kind] = int(chests[kind]) - 1
	else:
		gems -= chest_price(kind)
	var c: Dictionary = data["cofres"][kind]
	var rewards := []
	var floor_rarity: String = c.get("garantiza", "")
	for k in int(c["cartas"]):
		var r := _roll_rarity(c["probabilidad"], rng)
		# La última carta respeta la rareza garantizada si no salió ninguna igual o mejor
		if k == int(c["cartas"]) - 1 and floor_rarity != "" and not _has_rarity(rewards, floor_rarity):
			r = floor_rarity if RARITIES.find(r) < RARITIES.find(floor_rarity) else r
		rewards.append(_grant_card(r, rng))
	var g: Array = c["gemas"]
	var extra := rng.randi_range(int(g[0]), int(g[1]))
	gems += extra
	rewards.append({"tipo": "gemas", "cantidad": extra})
	_changed()
	return rewards


func _roll_rarity(odds: Dictionary, rng: RandomNumberGenerator) -> String:
	var x := rng.randf()
	var acc := 0.0
	for r in RARITIES:
		acc += float(odds.get(r, 0.0))
		if x < acc:
			return r
	return "comun"


func _has_rarity(rewards: Array, at_least: String) -> bool:
	for rw in rewards:
		if rw.has("rareza") and RARITIES.find(rw["rareza"]) >= RARITIES.find(at_least):
			return true
	return false


func _grant_card(rarity: String, rng: RandomNumberGenerator) -> Dictionary:
	var is_master := rng.randf() < float(data["carta_maestro"])
	var pool := []
	for e in (data["maestros"] if is_master else data["equipo"]):
		if e["rareza"] == rarity:
			pool.append(e["id"])
	var id: String = pool[rng.randi() % pool.size()]
	if is_master:
		var nuevo := not masters.has(id)
		if nuevo:
			masters[id] = {"nivel": 1, "copias": 0}
			# El primer maestro se pone solo en una ranura libre
			if active.size() < master_slots():
				active.append(id)
		else:
			masters[id]["copias"] = int(masters[id]["copias"]) + 1
		return {"tipo": "maestro", "id": id, "rareza": rarity, "nuevo": nuevo}
	var new_gear := not gear.has(id)
	var extra_gems := 0
	if new_gear:
		gear[id] = 1
		var slot: String = gear_info(id)["ranura"]
		# Se pone sola si la ranura está vacía o lo nuevo es mejor
		if not equipped.has(slot) or gear_bonus(id) > gear_bonus(equipped[slot]):
			equipped[slot] = id
	elif int(gear[id]) < max_level():
		gear[id] = int(gear[id]) + 1
	else:
		extra_gems = int(data["gemas_por_equipo_repetido"])
		gems += extra_gems
	return {"tipo": "equipo", "id": id, "rareza": rarity, "nuevo": new_gear, "gemas": extra_gems}


# --- Maestros y equipo ----------------------------------------------------------

func copies_needed(id: String) -> int:
	var lv := int(masters[id]["nivel"])
	return int(data["copias_por_nivel"][lv]) if lv < max_level() else 0


func tokens_needed(id: String) -> int:
	var lv := int(masters[id]["nivel"])
	return int(data["fichas_por_nivel"][lv]) if lv < max_level() else 0


func can_level_master(id: String) -> bool:
	if not masters.has(id) or int(masters[id]["nivel"]) >= max_level():
		return false
	return int(masters[id]["copias"]) >= copies_needed(id) and tokens >= tokens_needed(id)


func level_master(id: String) -> bool:
	if not can_level_master(id):
		return false
	tokens -= tokens_needed(id)
	masters[id]["copias"] = int(masters[id]["copias"]) - copies_needed(id)
	masters[id]["nivel"] = int(masters[id]["nivel"]) + 1
	_changed()
	return true


func toggle_master(id: String) -> bool:
	if id in active:
		active.erase(id)
	elif masters.has(id) and active.size() < master_slots():
		active.append(id)
	else:
		return false
	_changed()
	return true


func equip(id: String) -> void:
	if gear.has(id):
		equipped[gear_info(id)["ranura"]] = id
		_changed()


# Cuántas cosas puede hacer el jugador ahora mismo (para el globo rojo).
func pending_actions() -> int:
	var n := 0
	for id in masters:
		if can_level_master(id):
			n += 1
	if active.size() < mini(master_slots(), masters.size()):
		n += 1
	return n


# --- Guardado -------------------------------------------------------------------

func _changed() -> void:
	save_game()
	changed.emit()


func save_game() -> void:
	var d := {
		"version": 1,
		"gemas": gems,
		"fichas": tokens,
		"cofres": chests,
		"maestros": masters,
		"activos": active,
		"equipo": gear,
		"equipado": equipped,
		"misiones": missions_claimed,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	gems = int(d.get("gemas", 0))
	tokens = int(d.get("fichas", 0))
	chests = {}
	for k in d.get("cofres", {}):
		if data["cofres"].has(k):
			chests[k] = int(d["cofres"][k])
	masters = {}
	for id in d.get("maestros", {}):
		if not master_info(id).is_empty():
			masters[id] = {"nivel": int(d["maestros"][id]["nivel"]), "copias": int(d["maestros"][id]["copias"])}
	active = []
	for id in d.get("activos", []):
		if masters.has(id) and active.size() < master_slots():
			active.append(id)
	gear = {}
	for id in d.get("equipo", {}):
		if not gear_info(id).is_empty():
			gear[id] = int(d["equipo"][id])
	equipped = {}
	for slot in d.get("equipado", {}):
		var id: String = d["equipado"][slot]
		if gear.has(id) and gear_info(id)["ranura"] == slot:
			equipped[slot] = id
	missions_claimed = int(d.get("misiones", 0))


func reset_game() -> void:
	_reset_values()
	_changed()
