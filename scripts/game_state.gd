# Estado global del juego: época actual, monedas, niveles, mejoras, misiones y guardado.
# Cada época es un archivo de data/epocas/ (economía, estaciones, mejoras, misiones y
# tema visual) para poder ajustarla o agregar épocas sin programar.
extends Node

signal coins_changed
signal station_changed(idx: int)
signal upgrades_changed
signal missions_changed

const SAVE_PATH := "user://partida.json"
const ERAS_DIR := "res://data/epocas/"
const SAVE_EVERY := 10.0

var era_ids: Array = []         # orden de las épocas (data/epocas/indice.json)
var era_index := 0
var era: Dictionary = {}
var welcome := ""               # mensaje pendiente al llegar a una época nueva
var econ: Dictionary = {}
var coins := 0.0
var total_earned := 0.0
var levels: Array = []          # 0 = estación bloqueada
var purchased: Dictionary = {}  # id de mejora -> true
var claimed: Dictionary = {}    # id de misión -> true
var earn_rate := 0.0            # monedas por segundo (promedio móvil)
var offline_reward := 0.0       # pendiente de mostrar al jugador

var _window_earned := 0.0
var _window_time := 0.0
var _save_timer := 0.0


func _ready() -> void:
	era_ids = JSON.parse_string(FileAccess.get_file_as_string(ERAS_DIR + "indice.json"))
	_load_era(0)
	_reset_values()
	load_game()


func _load_era(i: int) -> void:
	era_index = clampi(i, 0, era_ids.size() - 1)
	era = JSON.parse_string(FileAccess.get_file_as_string(ERAS_DIR + era_ids[era_index] + ".json"))
	econ = era["economia"]


func theme(key: String, fallback = null):
	return era.get("tema", {}).get(key, fallback)


func has_next_era() -> bool:
	return era_index + 1 < era_ids.size()


func can_travel() -> bool:
	return has_next_era() and stars() >= total_missions()


# Viaje a la siguiente época: se reinician monedas, niveles, mejoras y misiones.
func travel(reload := true) -> bool:
	if not can_travel():
		return false
	_load_era(era_index + 1)
	_reset_values()
	welcome = "¡Bienvenido a la %s! Tu armería empieza de nuevo con armas más valiosas." % era["nombre"]
	save_game()
	if reload:
		get_tree().reload_current_scene()
	return true


func _reset_values() -> void:
	coins = 0.0
	total_earned = 0.0
	levels = []
	levels.resize(station_count())
	levels.fill(0)
	levels[0] = 1
	purchased = {}
	claimed = {}
	earn_rate = 0.0


func _process(delta: float) -> void:
	_window_time += delta
	if _window_time >= 5.0:
		var current := _window_earned / _window_time
		earn_rate = current if earn_rate == 0.0 else lerpf(earn_rate, current, 0.3)
		_window_earned = 0.0
		_window_time = 0.0
	_save_timer += delta
	if _save_timer >= SAVE_EVERY:
		_save_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()


# --- Estaciones ---------------------------------------------------------------

func station_count() -> int:
	return era["estaciones"].size()


func station(i: int) -> Dictionary:
	return era["estaciones"][i]


func station_index(id: String) -> int:
	for i in station_count():
		if station(i)["id"] == id:
			return i
	return -1


func is_unlocked(i: int) -> bool:
	return levels[i] > 0


func can_unlock(i: int) -> bool:
	return not is_unlocked(i) and (i == 0 or is_unlocked(i - 1))


func unlock_cost(i: int) -> float:
	return float(station(i)["costo_desbloqueo"])


func unlock(i: int) -> bool:
	if not can_unlock(i) or coins < unlock_cost(i):
		return false
	coins -= unlock_cost(i)
	levels[i] = 1
	_changed(i)
	return true


func max_level() -> int:
	return int(econ["nivel_max"])


# Costo de subir k niveles desde el nivel actual: C0 * g^(n-1) * (g^k - 1) / (g - 1)
func level_cost(i: int, k: int) -> float:
	var g := float(econ["crecimiento_costo"])
	var first := float(station(i)["costo_base"]) * pow(g, levels[i] - 1)
	return first * (pow(g, k) - 1.0) / (g - 1.0)


func max_affordable(i: int) -> int:
	var g := float(econ["crecimiento_costo"])
	var first := float(station(i)["costo_base"]) * pow(g, levels[i] - 1)
	var k := int(floor(log(coins * (g - 1.0) / first + 1.0) / log(g)))
	return clampi(k, 0, max_level() - levels[i])


func buy_levels(i: int, k: int) -> bool:
	k = mini(k, max_level() - levels[i])
	if k <= 0 or not is_unlocked(i):
		return false
	var cost := level_cost(i, k)
	if coins < cost:
		return false
	coins -= cost
	levels[i] += k
	_changed(i)
	return true


func _count_reached(list: Array, level: int) -> int:
	var n := 0
	for h in list:
		if level >= int(h):
			n += 1
	return n


func next_milestone(i: int) -> int:
	for h in econ["hitos_valor"]:
		if levels[i] < int(h):
			return int(h)
	return -1


func value_multiplier(i: int) -> float:
	var m := 1.0
	for u in era["mejoras"]:
		if not purchased.has(u["id"]):
			continue
		if u["tipo"] == "ganancia" and u["estacion"] == station(i)["id"]:
			m *= float(u["valor"])
		elif u["tipo"] == "ganancia_todas":
			m *= float(u["valor"])
	return m


# Valor por arma: V0 * n * 2^k * bonos
func value(i: int) -> float:
	var n: int = levels[i]
	var k := _count_reached(econ["hitos_valor"], n)
	return float(station(i)["valor_base"]) * n * pow(2.0, k) * value_multiplier(i)


func is_armero_milestone(level: int) -> bool:
	for h in econ["hitos_armero"]:
		if int(h) == level:
			return true
	return false


func armeros(i: int) -> int:
	return 1 + _count_reached(econ["hitos_armero"], levels[i])


func craft_time(i: int) -> float:
	return float(station(i)["tiempo"])


# --- Mejoras ------------------------------------------------------------------

func _sum_upgrades(tipo: String) -> float:
	var s := 0.0
	for u in era["mejoras"]:
		if purchased.has(u["id"]) and u["tipo"] == tipo:
			s += float(u["valor"])
	return s


func _product_upgrades(tipo: String) -> float:
	var p := 1.0
	for u in era["mejoras"]:
		if purchased.has(u["id"]) and u["tipo"] == tipo:
			p *= float(u["valor"])
	return p


func dependientes() -> int:
	return int(econ["dependientes_base"]) + int(_sum_upgrades("dependiente"))


func queue_size() -> int:
	return int(econ["fila_base"]) + int(_sum_upgrades("fila"))


func customer_interval() -> float:
	return float(econ["intervalo_clientes"]) * _product_upgrades("clientes")


func worker_speed() -> float:
	return float(econ["velocidad_dependiente"]) * _product_upgrades("velocidad")


func available_upgrades() -> Array:
	var list := []
	for u in era["mejoras"]:
		if not purchased.has(u["id"]):
			list.append(u)
	list.sort_custom(func(a, b): return float(a["costo"]) < float(b["costo"]))
	return list


func buy_upgrade(id: String) -> bool:
	for u in era["mejoras"]:
		if u["id"] == id and not purchased.has(id) and coins >= float(u["costo"]):
			coins -= float(u["costo"])
			purchased[id] = true
			coins_changed.emit()
			upgrades_changed.emit()
			missions_changed.emit()
			return true
	return false


# --- Monedas ------------------------------------------------------------------

func add_coins(v: float) -> void:
	coins += v
	total_earned += v
	_window_earned += v
	coins_changed.emit()


func _changed(i: int) -> void:
	coins_changed.emit()
	station_changed.emit(i)
	missions_changed.emit()


# --- Misiones -----------------------------------------------------------------

func mission_progress(m: Dictionary) -> Array:
	var goal := float(m["meta"])
	var current := 0.0
	match m["tipo"]:
		"nivel":
			current = levels[station_index(m["estacion"])]
		"mejoras":
			current = purchased.size()
		"ganado":
			current = total_earned
		"todas_nivel":
			current = levels.min()
	return [minf(current, goal), goal]


func mission_done(m: Dictionary) -> bool:
	var p := mission_progress(m)
	return p[0] >= p[1]


func active_missions(count := 3) -> Array:
	var list := []
	for m in era["misiones"]:
		if not claimed.has(m["id"]):
			list.append(m)
			if list.size() == count:
				break
	return list


func claim_mission(id: String) -> void:
	for m in era["misiones"]:
		if m["id"] == id and mission_done(m):
			claimed[id] = true
			missions_changed.emit()


func stars() -> int:
	return claimed.size()


func total_missions() -> int:
	return era["misiones"].size()


# --- Guardado -----------------------------------------------------------------

func save_game() -> void:
	var data := {
		"version": 2,
		"epoca": era_ids[era_index],
		"monedas": coins,
		"ganado": total_earned,
		"niveles": levels,
		"mejoras": purchased.keys(),
		"misiones": claimed.keys(),
		"ritmo": earn_rate,
		"hora": Time.get_unix_time_from_system(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	var saved_era := era_ids.find(data.get("epoca", era_ids[0]))
	if saved_era > 0:
		_load_era(saved_era)
		_reset_values()
	coins = float(data.get("monedas", 0.0))
	total_earned = float(data.get("ganado", 0.0))
	var saved: Array = data.get("niveles", [])
	for i in mini(saved.size(), levels.size()):
		levels[i] = int(saved[i])
	levels[0] = maxi(levels[0], 1)
	for id in data.get("mejoras", []):
		purchased[id] = true
	for id in data.get("misiones", []):
		claimed[id] = true
	earn_rate = float(data.get("ritmo", 0.0))
	# Ganancias fuera de línea: ritmo * tiempo ausente (con tope) * factor
	var away := Time.get_unix_time_from_system() - float(data.get("hora", 0.0))
	if away > 60.0 and earn_rate > 0.0:
		var cap := float(econ["tope_offline_horas"]) * 3600.0
		offline_reward = earn_rate * minf(away, cap) * float(econ["factor_offline"])


func claim_offline() -> void:
	if offline_reward > 0.0:
		add_coins(offline_reward)
		offline_reward = 0.0


func reset_game() -> void:
	_load_era(0)
	_reset_values()
	save_game()
	get_tree().reload_current_scene()
