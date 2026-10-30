# Prueba de gemas, cofres, maestros y equipo (sin pantalla).
# Uso: godot --headless res://tests/meta.tscn
extends Node

var ok := true


func check(cond: bool, what: String) -> void:
	print(("  ok    " if cond else "  FALLO ") + what)
	ok = ok and cond


func _ready() -> void:
	Meta.reset_game()
	GameState._load_era(0)
	GameState._reset_values()
	check(Meta.chests.get("madera", 0) == 1 and Meta.gems == 0, "empieza con un cofre de madera y 0 gemas")
	var v0 := GameState.value(0)
	var t0 := GameState.craft_time(0)

	# Misiones: gemas y un cofre de madera cada 6
	GameState.levels = [100, 100, 100, 100, 100]
	GameState.total_earned = 1e30
	for u in GameState.era["mejoras"]:
		GameState.purchased[u["id"]] = true
	var claimed := 0
	for m in GameState.era["misiones"]:
		if GameState.mission_done(m):
			GameState.claim_mission(m["id"])
			claimed += 1
		if claimed == 6:
			break
	check(claimed == 6 and Meta.gems == 30 and Meta.chests["madera"] == 2, "6 misiones dan 30 gemas y un cofre más (gemas=%d)" % Meta.gems)
	GameState.claim_mission(GameState.era["misiones"][0]["id"])
	check(Meta.gems == 30, "reclamar dos veces la misma misión no da gemas de nuevo")

	# Cofres con semilla fija
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var r1 := Meta.open_chest("madera", rng)
	check(r1.size() == 3 and Meta.chests["madera"] == 1, "el cofre de madera da 2 cartas + gemas y se descuenta")
	Meta.gems = 300
	var r2 := Meta.open_chest("oro", rng)
	var best := 0
	for rw in r2:
		if rw.has("rareza"):
			best = maxi(best, Meta.RARITIES.find(rw["rareza"]))
	check(r2.size() == 8 and best >= 2, "el cofre de oro da 7 cartas y al menos una épica")
	check(Meta.gems >= 15 and Meta.gems <= 40, "el cofre de oro cuesta 300 gemas y devuelve 15-40 (quedan %d)" % Meta.gems)
	Meta.gems = 0
	Meta.chests["plata"] = 0
	check(not Meta.can_open("plata") and Meta.open_chest("plata", rng).is_empty(), "sin gemas ni cofres no se abre")

	# Probabilidades en muchas aperturas
	var counts := {"comun": 0, "raro": 0, "epico": 0, "legendario": 0}
	for k in 2000:
		Meta.chests["madera"] = 1
		for rw in Meta.open_chest("madera", rng):
			if rw.has("rareza"):
				counts[rw["rareza"]] += 1
	var common_share := float(counts["comun"]) / 4000.0
	check(absf(common_share - 0.8) < 0.03 and counts["legendario"] == 0, "rarezas del cofre de madera cerca de lo esperado %s" % str(counts))

	# Bonos: activos y equipo cambian la economía
	check(Meta.active.size() == Meta.master_slots(), "se llenan las ranuras de maestros (%d)" % Meta.active.size())
	check(Meta.equipped.size() == 4, "hay una pieza puesta en cada ranura")
	var expect_v: float = v0 * Meta.bonus("ganancia")
	check(GameState.craft_time(0) < t0 or Meta.bonus("velocidad") == 1.0, "la velocidad de fabricación usa el bono (%.2f s antes, %.2f s ahora)" % [t0, GameState.craft_time(0)])
	GameState.levels = [1, 0, 0, 0, 0]
	GameState.purchased = {}
	check(is_equal_approx(GameState.value(0), expect_v * GameState.value_multiplier(0)), "el valor por arma usa el bono de ganancias (x%.2f)" % Meta.bonus("ganancia"))

	# Subir de nivel un maestro con copias y fichas
	var id: String = Meta.masters.keys()[0]
	Meta.masters[id]["copias"] = 2
	Meta.tokens = 10
	var before := Meta.master_bonus(id)
	check(Meta.level_master(id) and Meta.masters[id]["nivel"] == 2 and Meta.tokens == 0, "sube de nivel con 2 copias y 10 fichas")
	check(Meta.master_bonus(id) > before, "el bono crece con el nivel")
	check(not Meta.level_master(id), "no sube sin copias ni fichas")

	# Viajar de época da gemas, fichas y cofre de oro, y se conserva
	for m in GameState.era["misiones"]:
		GameState.claimed[m["id"]] = true
	var gems_before := Meta.gems
	var gold_before := int(Meta.chests.get("oro", 0))
	GameState.travel(false)
	check(Meta.gems == gems_before + 50 and Meta.tokens == 20 and Meta.chests["oro"] == gold_before + 1, "completar la época da 50 gemas, 20 fichas y un cofre de oro")

	# Guardado y carga
	var snap := [Meta.gems, Meta.tokens, Meta.masters.duplicate(true), Meta.active.duplicate(), Meta.gear.duplicate(), Meta.equipped.duplicate()]
	Meta._reset_values()
	Meta.load_game()
	check([Meta.gems, Meta.tokens, Meta.masters, Meta.active, Meta.gear, Meta.equipped] == snap, "el guardado conserva todo")

	Meta.reset_game()
	GameState._load_era(0)
	GameState._reset_values()
	GameState.save_game()
	print("RESULTADO: " + ("OK" if ok else "FALLO"))
	get_tree().quit()
