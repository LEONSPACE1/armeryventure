extends Node
# Simulación con jugador automático para revisar el ritmo de la economía.
var main
var t := 0.0
var next_check := 0.0
var log_times := {}

func _ready():
	GameState._reset_values()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)

func _process(delta):
	t += delta
	# toca la estación seleccionada 3 veces por segundo como un jugador activo
	if fmod(t, 0.33) < delta:
		for s in main.stations:
			if GameState.is_unlocked(s.idx): s.boost(0.2 / GameState.station_count())
	if t < next_check: return
	next_check = t + 1.0
	for m in GameState.active_missions():
		if GameState.mission_done(m):
			GameState.claim_mission(m["id"])
			log_times[m["id"]] = int(t)
	# compra lo más barato entre: desbloqueo, mejora, nivel
	var best_cost := INF
	var action := Callable()
	for i in GameState.station_count():
		if GameState.can_unlock(i) and GameState.unlock_cost(i) < best_cost * 3:
			best_cost = GameState.unlock_cost(i); action = GameState.unlock.bind(i)
		elif GameState.is_unlocked(i) and GameState.levels[i] < GameState.max_level():
			var c := GameState.level_cost(i, 1)
			if c < best_cost: best_cost = c; action = GameState.buy_levels.bind(i, 1)
	for u in GameState.available_upgrades():
		if float(u["costo"]) < best_cost:
			best_cost = float(u["costo"]); action = GameState.buy_upgrade.bind(u["id"])
	if action.is_valid() and GameState.coins >= best_cost:
		action.call()
	if int(t) % 300 == 0:
		print("t=%dmin coins=%s rate=%s lv=%s stars=%d" % [int(t/60), Fmt.num(GameState.coins), Fmt.num(GameState.earn_rate), str(GameState.levels), GameState.stars()])
	if GameState.stars() >= GameState.total_missions() or t > 3*3600:
		print("FIN t=%dmin stars=%d misiones=%s" % [int(t/60), GameState.stars(), str(log_times)])
		get_tree().quit()
