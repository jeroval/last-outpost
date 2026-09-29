extends SceneTree

const Catalog = preload("res://game/core/content_catalog.gd")
const State = preload("res://game/core/station_state.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = Catalog.new()
	_check(catalog.errors.is_empty() and catalog.trade_offers.size() == 4, "Catalogue de troc valide")
	_test_withdraw(catalog)
	_test_progression(catalog)
	_test_guidance(catalog)
	_test_production(catalog)
	_test_trade(catalog)
	_test_threat(catalog)
	_test_save(catalog)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("PROGRESSION OK: retrait conservatif, 32 graines jouables, production, troc borné, menace annoncée, défense, migration atomique")
	quit(0)


func _check(condition: bool, reason: String) -> void:
	if not condition:
		failures.append(reason)


func _test_withdraw(catalog) -> void:
	var state = State.new(catalog)
	# LO-001: deposited food and water must remain usable through the stock.
	state.pack = {"water": 2, "food": 2}
	state.deposit()
	_check(state.pack.is_empty() and state.storage == {"water": 2, "food": 2}, "LO-001 dépôt initial")
	_check(state.withdraw("water", 1) == 1 and state.withdraw("food", 1) == 1, "LO-001 retrait disponible")
	state.thirst = 20
	state.hunger = 20
	_check(state.consume("water") and state.consume("food"), "LO-001 consommables utilisables après dépôt/retrait")
	_check(state.thirst == 55 and state.hunger == 50 and state.storage == {"water": 1, "food": 1}, "LO-001 quantités et besoins conservés")
	state.pack = {"wood": 17}
	state.storage = {"fuel": 3, "water": 2}
	var before: Dictionary = state.snapshot()
	_check(state.withdraw("fuel", 3) == 0 and state.snapshot() == before, "Retrait pondéré refuse carburant trop lourd sans mutation")
	_check(state.withdraw("water", 99) == 1 and state.carried_weight() == 18 and int(state.storage["water"]) == 1, "Retrait partiel borné par sac")
	before = state.snapshot()
	_check(state.withdraw("wood", -1) == 0 and state.withdraw("unknown", 1) == 0 and state.snapshot() == before, "Retraits invalides atomiques")


func _test_progression(catalog) -> void:
	for seed_value in range(32):
		var state = State.new(catalog, seed_value)
		for site_id in ["warehouse", "garage", "grove", "house", "pump"]:
			for attempt in range(2):
				state.scavenge(site_id)
				state.deposit()
				state.build_shelf()
				state.repair_generator()
				for recipe in ["collector", "garden", "market"]:
					state.upgrade_station(recipe)
				state.deposit()
		_check(state.build_barricade(Vector3(5, 0, 10), 0), "Ressources suffisantes pour défense, graine %d" % seed_value)
		_check(state.refuge_autonomous(), "Tous équipements réalisables sans ressource offerte, graine %d" % seed_value)
		_check(state.carried_weight() <= state.PACK_CAPACITY and state.stored_weight() <= state.storage_capacity(), "Capacités respectées pendant progression")
	var first = State.new(catalog, 12)
	var same = State.new(catalog, 12)
	var other = State.new(catalog, 59)
	_check(first.site_loot == same.site_loot and first.site_loot != other.site_loot, "Butin déterministe mais variable par graine")
	var before: Dictionary = first.snapshot()
	_check(not first.upgrade_station("garden")["ok"] and first.snapshot() == before, "Préconditions et refus upgrade sans mutation")


func _test_guidance(catalog) -> void:
	var state = State.new(catalog)
	_check(state.next_objective()["target"] == "warehouse", "Guidage initial vers entrepôt")
	state.scavenge("warehouse")
	_check(state.next_objective()["target"] == "stash", "Guidage vers dépôt quand le sac suffit pour étagère")
	state.deposit()
	_check(state.next_objective()["target"] == "stash", "Guidage vers atelier une fois les matériaux déposés")
	state.build_shelf()
	_check(state.next_objective()["target"] == "garage", "Guidage générateur vers garage pour câble manquant")
	state.scavenge("garage")
	_check(state.next_objective()["target"] == "stash", "Guidage générateur vers dépôt avec les matériaux dans sac")
	state.deposit()
	_check(state.next_objective()["target"] == "generator", "Guidage générateur vers réparation après dépôt")
	state.repair_generator()
	for recipe_id in ["collector", "garden", "market"]:
		state.pack.clear()
		state.storage.clear()
		for required in ["collector", "garden"]:
			state.structures[required] = required != recipe_id and recipe_id != "collector"
		state.structures["market"] = false
		# Only one remaining location can supply this project's missing resources.
		for site_id in state.site_loot:
			state.site_loot[site_id] = {}
		state.site_loot["grove"] = catalog.recipes[recipe_id]["inputs"].duplicate(true)
		_check(state.next_objective()["target"] == "grove", "Guidage %s choisit lieu contenant ingrédients encore manquants" % recipe_id)
		state.scavenge("grove")
		_check(state.next_objective()["target"] == "stash", "Guidage %s revient au dépôt après récolte" % recipe_id)
	state.structures = {"collector": true, "garden": true, "market": true}
	state.barricades = [{"x": 5.0, "z": 10.0, "rotation": 0.0, "durability": 3}]
	state.day = 2
	_check(state.next_objective()["target"] == "trader", "Objectif final vise identifiant marchand existant")


func _test_production(catalog) -> void:
	var state = State.new(catalog)
	state.shelf_built = true
	state.structures["collector"] = true
	state.structures["garden"] = true
	state.storage = {"water": 4}
	var predicted: String = state.next_day_preview()["weather"]
	var expected_water := 1 if predicted == "Clair" else (3 if predicted == "Pluie" else 4)
	state.advance_day()
	_check(state.weather == predicted and state.storage == {"water": 3 + expected_water, "food": 2}, "Production eau puis jardin conforme météo, sans générateur")
	state.storage = {"wood": 47, "water": 1}
	state.advance_day()
	_check(state.stored_weight() == 48 and state.storage["water"] == 1 and not state.storage.has("food"), "Stock plein ne détruit pas eau de jardin")
	state.structures["collector"] = false
	state.storage.clear()
	state.advance_day()
	_check(state.storage.is_empty(), "Potager à sec ne crée aucune nourriture")
	# A modest initial reserve keeps a quiet base viable through 24 weather days.
	state = State.new(catalog, 19)
	state.shelf_built = true
	state.structures = {"collector": true, "garden": true, "market": true}
	state.storage = {"water": 6, "food": 4}
	for index in range(24):
		if state.thirst <= 65:
			state.withdraw("water", 1)
			state.consume("water")
		if state.hunger <= 70:
			state.withdraw("food", 1)
			state.consume("food")
		if state.trader_present() and int(state.storage.get("food", 0)) >= 8:
			state.trade("fuel")
		state.advance_day()
	_check(state.health == 100 and state.hunger > 0 and state.thirst > 0, "Production renouvelable viable sur24jours avec ravitaillement et excédents")
	_check(int(state.storage.get("fuel", 0)) > 0, "Excédents peuvent financer carburant renouvelable")


func _test_trade(catalog) -> void:
	var state = State.new(catalog)
	state.shelf_built = true
	state.structures["market"] = true
	state.storage = {"food": 12, "water": 8}
	var before: Dictionary = state.snapshot()
	_check(not state.trade("fuel")["ok"] and state.snapshot() == before, "Troc absent refusé sans mutation")
	state.advance_day()
	_check(state.trader_present(), "Marchand jours pairs")
	_check(state.trade("fuel")["ok"] and state.trade("fuel")["ok"], "Deux échanges disponibles")
	_check(state.storage["food"] == 4 and state.storage["fuel"] == 2, "Troc consomme exactement son prix")
	before = state.snapshot()
	_check(not state.trade("fuel")["ok"] and state.snapshot() == before, "Pas de duplication après quota visite")
	var loaded = State.new(catalog)
	_check(loaded.restore(JSON.parse_string(JSON.stringify(state.snapshot()))), "Sauvegarde JSON troc")
	_check(not loaded.trade("fuel")["ok"], "Recharger ne réinitialise pas quota")
	state.advance_day()
	_check(not state.trader_present(), "Marchand repart")
	state.advance_day()
	_check(state.trade("fuel")["ok"], "Marchand suivant renouvelle offre")


func _test_threat(catalog) -> void:
	var state = State.new(catalog)
	state.generator_repaired = true
	state.generator_on = true
	state.shelf_built = true
	state.storage = {"fuel": 8, "wood": 6, "scrap": 2, "food": 3}
	state.build_barricade(Vector3(5, 0, 10), 0)
	state.noise = 4
	# Choose the first deterministic announced raid, without depending on an RNG's exact sample.
	for day_number in range(1, 12):
		state.day = day_number
		if state.next_day_preview()["threat"] > 0:
			break
	var threat: int = state.next_day_preview()["threat"]
	_check(threat > 0 and state.next_day_preview()["summary"].contains("Intrusion"), "Menace annoncée avant nuit")
	var before_fuel: int = state.storage["fuel"]
	state.advance_day()
	_check(state.last_event["threat"] == threat and state.defence_strength() == 3 - threat, "Menace annoncée correspond dégâts défense")
	_check(state.storage["fuel"] == before_fuel - 1 and state.health == 100, "Défense protège stock et santé")
	if not state.barricades.is_empty():
		var before_wood: int = state.storage["wood"]
		_check(state.repair_barricades()["ok"] and state.defence_strength() == 3 and state.storage["wood"] == before_wood - threat, "Réparer consomme bois égal dégâts")
	state = State.new(catalog)
	state.generator_repaired = true
	state.generator_on = true
	state.noise = 3
	state.storage = {"food": 1, "fuel": 5}
	state.set_watch(true)
	for day_number in range(1, 12):
		state.day = day_number
		if state.next_day_preview()["threat"] > 0:
			break
	state.advance_day()
	_check(not state.storage.has("food") and state.storage["fuel"] == 4 and state.health == 100, "Garde coûte nourriture et absorbe intrusion")
	state = State.new(catalog)
	state.generator_repaired = true
	state.generator_on = true
	state.noise = 3
	state.storage = {"fuel": 5}
	for day_number in range(1, 12):
		state.day = day_number
		if state.next_day_preview()["threat"] > 0:
			break
	threat = state.next_day_preview()["threat"]
	state.advance_day()
	_check(int(state.storage.get("fuel", 0)) == 4 - threat, "Sans défense, intrusion retire le butin annoncé après carburant quotidien")
	_check(state.health == 100, "Une intrusion servie par le stock ne double pas la perte en santé")
	state = State.new(catalog)
	state.difficulty = "relaxed"
	state.noise = 10
	_check(state.next_day_preview()["threat"] == 0, "Mode détente sans intrusion")
	state.advance_day()
	_check(state.hunger == 71 and state.thirst == 68, "Mode détente besoins divisés2")


func _test_save(catalog) -> void:
	var state = State.new(catalog, 459)
	state.shelf_built = true
	state.storage = {"wood": 4, "scrap": 1}
	state.build_barricade(Vector3(5, 0, 10), 0.2)
	state.difficulty = "relaxed"
	state.advance_day()
	var saved: Dictionary = state.snapshot()
	var loaded = State.new(catalog)
	var restored: bool = loaded.restore(JSON.parse_string(JSON.stringify(saved)))
	_check(restored and loaded.snapshot() == saved, "Sauvegarde v2 JSON roundtrip")
	_check(loaded.next_day_preview() == state.next_day_preview(), "Graine/jour/météo/menace persistés")
	var legacy: Dictionary = saved.duplicate(true)
	legacy["version"] = 1
	for field in ["world_seed", "difficulty", "structures", "noise", "watch_active", "trade_used", "last_event"]:
		legacy.erase(field)
	for barrier in legacy["barricades"]:
		barrier.erase("durability")
	_check(loaded.restore(legacy) and loaded.SAVE_VERSION == 2 and loaded.barricades[0]["durability"] == 3 and not loaded.structures["collector"], "Migration v1 garde état et initialise nouveautés")
	var before: Dictionary = loaded.snapshot()
	var corruptions: Array = []
	for invalid in [-1, 1.5, NAN, INF, "3"]:
		var corrupt: Dictionary = saved.duplicate(true)
		corrupt["pack"]["water"] = invalid
		corruptions.append(corrupt)
	for field in ["day", "world_seed", "health"]:
		var corrupt: Dictionary = saved.duplicate(true)
		corrupt[field] = "invalid"
		corruptions.append(corrupt)
	var invalid_position: Dictionary = saved.duplicate(true)
	invalid_position["player_position"][0] = INF
	corruptions.append(invalid_position)
	var invalid_barrier: Dictionary = saved.duplicate(true)
	invalid_barrier["barricades"][0]["rotation"] = NAN
	corruptions.append(invalid_barrier)
	var invalid_loot: Dictionary = saved.duplicate(true)
	invalid_loot["site_loot"]["garage"]["fuel"] = 1
	corruptions.append(invalid_loot)
	for corrupt in corruptions:
		_check(not loaded.restore(corrupt) and loaded.snapshot() == before, "Chargement malformé atomiquement refusé")
	var empty_tank: Dictionary = saved.duplicate(true)
	empty_tank["generator_repaired"] = true
	empty_tank["generator_on"] = true
	_check(loaded.restore(empty_tank) and not loaded.generator_on, "Générateur arrêté au chargement sans carburant")
