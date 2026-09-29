extends RefCounted

const SAVE_VERSION := 2
const PACK_CAPACITY := 18
const BASE_STORAGE_CAPACITY := 24
const SHELF_STORAGE_CAPACITY := 48
const DEFAULT_SEED := 260929
const MAX_COUNT := 100000

var catalog
var pack: Dictionary = {}
var storage: Dictionary = {}
var site_loot: Dictionary = {}
var generator_repaired := false
var generator_on := false
var shelf_built := false
var barricades: Array = []
var structures: Dictionary = {"collector": false, "garden": false, "market": false}
var day := 1
var hunger := 80
var thirst := 80
var health := 100
var player_position := Vector3(-7, 1, 12)
var world_seed := DEFAULT_SEED
var difficulty := "standard"
var noise := 0
var weather := "Clair"
var watch_active := false
var trade_used: Dictionary = {}
var last_event: Dictionary = {}


func _init(content: RefCounted, seed_value: int = DEFAULT_SEED) -> void:
	catalog = content
	world_seed = clampi(seed_value, 0, 2147483647)
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	for site_id in catalog.sites:
		var available: Dictionary = {}
		for drop in catalog.sites[site_id]["loot"]:
			available[drop["item"]] = rng.randi_range(int(drop["min"]), int(drop["max"]))
		site_loot[site_id] = available
	weather = weather_for_day(day)


func carried_weight() -> int:
	return _weight(pack)


func stored_weight() -> int:
	return _weight(storage)


func _weight(container: Dictionary) -> int:
	var total := 0
	for item_id in container:
		total += int(container[item_id]) * catalog.item_weight(item_id)
	return total


func storage_capacity() -> int:
	return SHELF_STORAGE_CAPACITY if shelf_built else BASE_STORAGE_CAPACITY


func _room(container: Dictionary, capacity: int, item_id: String) -> int:
	return maxi(0, int(float(capacity - _weight(container)) / catalog.item_weight(item_id)))


func _take(container: Dictionary, item_id: String, amount: int) -> void:
	container[item_id] = int(container.get(item_id, 0)) - amount
	if int(container[item_id]) <= 0:
		container.erase(item_id)


func _add(container: Dictionary, item_id: String, amount: int) -> void:
	container[item_id] = int(container.get(item_id, 0)) + amount


func scavenge(site_id: String) -> Dictionary:
	var acquired: Dictionary = {}
	if not site_loot.has(site_id):
		return acquired
	var available: Dictionary = site_loot[site_id]
	for item_id in available.keys():
		var taken := mini(int(available[item_id]), _room(pack, PACK_CAPACITY, item_id))
		if taken > 0:
			_add(pack, item_id, taken)
			available[item_id] = int(available[item_id]) - taken
			acquired[item_id] = taken
	return acquired


func deposit() -> Dictionary:
	var moved: Dictionary = {}
	for item_id in pack.keys():
		var count := mini(int(pack[item_id]), _room(storage, storage_capacity(), item_id))
		if count > 0:
			_add(storage, item_id, count)
			_take(pack, item_id, count)
			moved[item_id] = count
	return moved


func withdraw(item_id: String, amount: int = 1) -> int:
	if not catalog.items.has(item_id) or amount <= 0:
		return 0
	var moved := mini(mini(amount, int(storage.get(item_id, 0))), _room(pack, PACK_CAPACITY, item_id))
	if moved > 0:
		_take(storage, item_id, moved)
		_add(pack, item_id, moved)
	if int(storage.get("fuel", 0)) == 0:
		generator_on = false
	return moved


func can_afford(recipe_id: String) -> bool:
	return catalog.recipes.has(recipe_id) and _has_items(storage, catalog.recipes[recipe_id]["inputs"])


func _has_items(container: Dictionary, inputs: Dictionary) -> bool:
	for item_id in inputs:
		if int(container.get(item_id, 0)) < int(inputs[item_id]):
			return false
	return true


func _spend(recipe_id: String) -> bool:
	if not can_afford(recipe_id):
		return false
	for item_id in catalog.recipes[recipe_id]["inputs"]:
		_take(storage, item_id, int(catalog.recipes[recipe_id]["inputs"][item_id]))
	return true


func build_shelf() -> bool:
	if shelf_built or not _spend("shelf"):
		return false
	shelf_built = true
	return true


func repair_generator() -> bool:
	if generator_repaired or not _spend("generator"):
		return false
	generator_repaired = true
	return true


func toggle_generator() -> bool:
	if not generator_repaired:
		return false
	if generator_on:
		generator_on = false
		return true
	if int(storage.get("fuel", 0)) <= 0:
		return false
	generator_on = true
	return true


func upgrade_status(recipe_id: String) -> Dictionary:
	var result := {"built": false, "affordable": false, "missing": {}, "requirements": []}
	if not catalog.recipes.has(recipe_id):
		return result
	result["built"] = _built(recipe_id)
	for required in catalog.recipes[recipe_id].get("requires", []):
		if not _built(required):
			result["requirements"].append(required)
	for item_id in catalog.recipes[recipe_id]["inputs"]:
		var missing := int(catalog.recipes[recipe_id]["inputs"][item_id]) - int(storage.get(item_id, 0))
		if missing > 0:
			result["missing"][item_id] = missing
	result["affordable"] = result["missing"].is_empty() and result["requirements"].is_empty() and not result["built"]
	return result


func _built(recipe_id: String) -> bool:
	if recipe_id == "shelf":
		return shelf_built
	if recipe_id == "generator":
		return generator_repaired
	return bool(structures.get(recipe_id, false))


func upgrade_station(recipe_id: String) -> Dictionary:
	if not structures.has(recipe_id):
		return {"ok": false, "message": "Équipement inconnu."}
	var status := upgrade_status(recipe_id)
	if status["built"]:
		return {"ok": false, "message": "Cet équipement est déjà installé."}
	if not status["requirements"].is_empty():
		var required: String = str(status["requirements"][0])
		return {"ok": false, "message": "À faire d'abord : " + str(catalog.recipes[required]["name"]) + "."}
	if not status["missing"].is_empty():
		return {"ok": false, "message": "Matériaux manquants dans le stock : " + _item_text(status["missing"]) + "."}
	_spend(recipe_id)
	structures[recipe_id] = true
	return {"ok": true, "message": str(catalog.recipes[recipe_id]["name"]) + " : terminé. " + str(catalog.recipes[recipe_id]["description"])}


func build_barricade(position: Vector3, rotation: float) -> bool:
	if not position.is_finite() or not is_finite(rotation) or position.length() > 19.0 or position.length() < 3.0:
		return false
	var snapped := Vector3(snappedf(position.x, 0.5), 0, snappedf(position.z, 0.5))
	if snapped.length() < 3.0 or snapped.length() > 19.0:
		return false
	for barrier in barricades:
		if Vector3(float(barrier["x"]), 0, float(barrier["z"])).distance_to(snapped) < 2.0:
			return false
	if barricades.size() >= 64 or not _spend("barricade"):
		return false
	barricades.append({"x": snapped.x, "z": snapped.z, "rotation": rotation, "durability": 3})
	return true


func repair_barricades() -> Dictionary:
	var repaired := 0
	for barrier in barricades:
		var amount := mini(3 - int(barrier.get("durability", 3)), int(storage.get("wood", 0)))
		if amount > 0:
			_take(storage, "wood", amount)
			barrier["durability"] = int(barrier.get("durability", 3)) + amount
			repaired += amount
	return {"ok": repaired > 0, "message": "%d point(s) de défense réparé(s), %d bois utilisé(s)." % [repaired, repaired] if repaired > 0 else "Aucune réparation possible : défenses intactes ou bois manquant."}


func consume(item_id: String) -> bool:
	if item_id != "food" and item_id != "water":
		return false
	if int(pack.get(item_id, 0)) <= 0:
		return false
	_take(pack, item_id, 1)
	if item_id == "food":
		hunger = mini(100, hunger + 30)
	else:
		thirst = mini(100, thirst + 35)
	return true


func weather_for_day(day_number: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed + maxi(1, day_number) * 7919
	return ["Clair", "Clair", "Pluie", "Pluie", "Orage"][rng.randi_range(0, 4)]


func defence_strength() -> int:
	var strength := 0
	for barrier in barricades:
		strength += int(barrier.get("durability", 3))
	if watch_active and int(storage.get("food", 0)) > 0:
		strength += 2
	return strength


func set_watch(enabled: bool) -> bool:
	if enabled and int(storage.get("food", 0)) <= 0:
		return false
	watch_active = enabled
	return true


func _tomorrow_threat() -> int:
	if difficulty == "relaxed":
		return 0
	var expected_noise := clampi(noise + (2 if generator_on else -2), 0, 10)
	if expected_noise < 3:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed + (day + 1) * 3571
	if rng.randi_range(0, 3) == 0:
		return 0
	return mini(3, 1 + int(expected_noise / 4.0))


func next_day_preview() -> Dictionary:
	var tomorrow_weather := weather_for_day(day + 1)
	var threat := _tomorrow_threat()
	var merchant := bool(structures["market"]) and (day + 1) % 2 == 0
	var summary := "Demain : %s. " % tomorrow_weather
	if generator_on:
		summary += "Générateur : −1 carburant, bruit en hausse. "
	if threat > 0:
		summary += "Intrusion annoncée : force %d / défense %d. " % [threat, defence_strength()]
	else:
		summary += "Aucune intrusion annoncée. "
	if merchant:
		summary += "Le marchand fera halte. "
	if watch_active:
		summary += "Garde : 1 nourriture du stock."
	return {"weather": tomorrow_weather, "threat": threat, "defence": defence_strength(), "merchant": merchant, "generator_fuel": 1 if generator_on else 0, "summary": summary}


func trader_present() -> bool:
	return bool(structures["market"]) and day % 2 == 0


func trade(offer_id: String) -> Dictionary:
	if not trader_present():
		return {"ok": false, "message": "Le marchand revient les jours pairs. Construisez le comptoir pour l'accueillir."}
	if not catalog.trade_offers.has(offer_id):
		return {"ok": false, "message": "Offre inconnue."}
	var offer: Dictionary = catalog.trade_offers[offer_id]
	if int(trade_used.get(offer_id, 0)) >= int(offer["limit"]):
		return {"ok": false, "message": "Cette offre est épuisée pour cette visite."}
	if not _has_items(storage, offer["give"]):
		return {"ok": false, "message": "Le marchand demande dans le stock : " + _item_text(offer["give"]) + "."}
	var future_weight := stored_weight() - _weight(offer["give"]) + _weight(offer["receive"])
	if future_weight > storage_capacity():
		return {"ok": false, "message": "Libérez de la place dans le stock avant cet échange."}
	for item_id in offer["give"]:
		_take(storage, item_id, int(offer["give"][item_id]))
	for item_id in offer["receive"]:
		_add(storage, item_id, int(offer["receive"][item_id]))
	trade_used[offer_id] = int(trade_used.get(offer_id, 0)) + 1
	return {"ok": true, "message": "Échange : " + _item_text(offer["give"]) + " → " + _item_text(offer["receive"]) + "."}


func advance_day() -> String:
	var preview := next_day_preview()
	day += 1
	weather = str(preview["weather"])
	trade_used.clear()
	noise = clampi(noise + (2 if generator_on else -2), 0, 10)
	hunger = maxi(0, hunger - (9 if difficulty == "relaxed" else 18))
	thirst = maxi(0, thirst - (12 if difficulty == "relaxed" else 24))
	var report := "Jour %d · %s. Faim : %d/100 · Soif : %d/100. " % [day, weather, hunger, thirst]
	if generator_on:
		_take(storage, "fuel", 1)
		if int(storage.get("fuel", 0)) == 0:
			generator_on = false
			report += "Réservoir vide, lumières éteintes. "
		else:
			report += "1 carburant consommé. "
	var guard := 0
	if watch_active:
		if int(storage.get("food", 0)) > 0:
			_take(storage, "food", 1)
			guard = 2
			report += "Garde assurée (−1 nourriture). "
		else:
			watch_active = false
			report += "Garde annulée : nourriture manquante. "
	var threat := int(preview["threat"])
	last_event = {"day": day, "threat": threat, "water": 0, "food": 0, "merchant": trader_present()}
	if threat > 0:
		report += _resolve_raid(threat, guard)
	else:
		report += "La nuit s'est déroulée sans intrusion. "
	if structures["collector"]:
		var yield_amount := 1 if weather == "Clair" else (3 if weather == "Pluie" else 4)
		var collected := mini(yield_amount, _room(storage, storage_capacity(), "water"))
		if collected > 0:
			_add(storage, "water", collected)
			last_event["water"] = collected
			report += "+%d eau. " % collected
		else:
			report += "Récupérateur bloqué : stock plein. "
	if structures["garden"]:
		if int(storage.get("water", 0)) <= 0:
			report += "Potager à sec. "
		elif stored_weight() - catalog.item_weight("water") + 2 * catalog.item_weight("food") > storage_capacity():
			report += "Récolte reportée : stock plein, eau préservée. "
		else:
			_take(storage, "water", 1)
			_add(storage, "food", 2)
			last_event["food"] = 2
			report += "Potager : −1 eau, +2 nourritures. "
	if hunger == 0 or thirst == 0:
		health = maxi(0, health - 15)
		report += "La faim ou la soif vous affaiblit (−15 santé). "
	elif hunger >= 50 and thirst >= 50:
		health = mini(100, health + 3)
	if trader_present():
		report += "Le marchand est au comptoir aujourd'hui. "
	return report.strip_edges()


func _resolve_raid(threat: int, guard: int) -> String:
	var remaining := maxi(0, threat - guard)
	var damaged := 0
	for barrier in barricades:
		var absorbed := mini(int(barrier.get("durability", 3)), remaining)
		barrier["durability"] = int(barrier.get("durability", 3)) - absorbed
		remaining -= absorbed
		damaged += absorbed
	barricades = barricades.filter(func(barrier): return int(barrier["durability"]) > 0)
	if remaining == 0:
		return "Intrusion repoussée ; défense usée de %d point(s). " % damaged
	var lost: Dictionary = {}
	for item_id in ["fuel", "scrap", "food", "water"]:
		var amount := mini(remaining, int(storage.get(item_id, 0)))
		if amount > 0:
			_take(storage, item_id, amount)
			lost[item_id] = amount
			remaining -= amount
	if int(storage.get("fuel", 0)) == 0:
		generator_on = false
	if remaining > 0:
		health = maxi(0, health - remaining * 5)
	return "Intrusion : " + ("stock pillé (" + _item_text(lost) + "). " if not lost.is_empty() else "") + ("−%d santé. " % (remaining * 5) if remaining > 0 else "")


func stage_name() -> String:
	if refuge_autonomous():
		return "REFUGE AUTONOME"
	if generator_repaired and generator_on:
		return "AVANT-POSTE"
	if shelf_built or generator_repaired:
		return "REFUGE"
	return "RUINE"


func station_restored() -> bool:
	return generator_repaired and generator_on and shelf_built and not barricades.is_empty() and health > 0


func refuge_autonomous() -> bool:
	return shelf_built and generator_repaired and structures["collector"] and structures["garden"] and structures["market"] and not barricades.is_empty() and health > 0


func next_objective() -> Dictionary:
	if thirst <= 35:
		return {"title": "Boire avant de repartir", "hint": "Prenez de l'eau dans le stock ou fouillez la maison. La touche 2 permet de boire.", "target": "stash" if int(storage.get("water", 0)) > 0 else "house"}
	if hunger <= 30:
		return {"title": "Reprendre des forces", "hint": "Récupérez une ration dans le stock ou dans la maison. La touche 1 permet de manger.", "target": "stash" if int(storage.get("food", 0)) > 0 else "house"}
	if not shelf_built:
		return _construction_objective("shelf", "Faire de la place", "Installez l'étagère depuis l'atelier pour agrandir le stock.")
	if not generator_repaired:
		return _construction_objective("generator", "Rallumer la station", "Réparez le générateur puis déposez du carburant dans le stock.", "generator")
	if not structures["collector"]:
		return _construction_objective("collector", "Produire votre propre eau", "Installez le récupérateur depuis l'atelier. La météo modifie sa production chaque jour.")
	if not structures["garden"]:
		return _construction_objective("garden", "Planter pour demain", "Installez le potager : 1 eau du stock donnera 2 nourritures chaque jour.")
	if not structures["market"]:
		return _construction_objective("market", "Faire revenir les voyageurs", "Ouvrez le comptoir. Les jours pairs, échangez vos excédents contre du carburant et des matériaux.")
	if barricades.is_empty():
		return {"title": "Protéger votre refuge", "hint": "Construisez une barricade près de la station. Le bruit attire des intrusions annoncées avant la nuit.", "target": "stash"}
	return {"title": "Votre refuge prend vie", "hint": "Entretenez les défenses, surveillez la météo et troquez vos surplus. Gardez de l'eau pour le potager.", "target": "trader" if trader_present() else "stash"}


func _construction_objective(recipe_id: String, title: String, purpose: String, work_target: String = "stash") -> Dictionary:
	if can_afford(recipe_id):
		return {"title": title, "hint": purpose, "target": work_target}
	var missing: Dictionary = {}
	for item_id in catalog.recipes[recipe_id]["inputs"]:
		var amount := int(catalog.recipes[recipe_id]["inputs"][item_id]) - int(storage.get(item_id, 0)) - int(pack.get(item_id, 0))
		if amount > 0:
			missing[item_id] = amount
	if missing.is_empty():
		return {"title": title, "hint": "Matériaux réunis ! Déposez votre sac dans le stock. " + purpose, "target": "stash"}
	# Guide toward remaining loot that covers the most currently missing ingredients.
	var best_site := ""
	var best_amount := 0
	for site_id in catalog.sites:
		var useful_amount := 0
		for item_id in missing:
			useful_amount += mini(int(missing[item_id]), int(site_loot.get(site_id, {}).get(item_id, 0)))
		if useful_amount > best_amount:
			best_amount = useful_amount
			best_site = str(site_id)
	if not best_site.is_empty():
		return {"title": title, "hint": "Il manque " + _item_text(missing) + ". Fouillez : " + str(catalog.sites[best_site]["name"]) + ".", "target": best_site}
	return {"title": title, "hint": "Il manque " + _item_text(missing) + ". Aucun lieu n'en contient encore : préparez un échange au comptoir.", "target": "trader" if trader_present() else "stash"}


func _item_text(container: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in container:
		parts.append("%d %s" % [int(container[item_id]), catalog.item_name(item_id)])
	return ", ".join(parts)


func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION, "world_seed": world_seed, "difficulty": difficulty,
		"pack": pack.duplicate(true), "storage": storage.duplicate(true), "site_loot": site_loot.duplicate(true),
		"generator_repaired": generator_repaired, "generator_on": generator_on,
		"shelf_built": shelf_built, "barricades": barricades.duplicate(true), "structures": structures.duplicate(true),
		"day": day, "hunger": hunger, "thirst": thirst, "health": health,
		"noise": noise, "watch_active": watch_active, "trade_used": trade_used.duplicate(true), "last_event": last_event.duplicate(true),
		"player_position": [player_position.x, player_position.y, player_position.z],
	}


func restore(data: Dictionary) -> bool:
	# Validate a detached candidate completely before assigning any live field.
	if not _whole(data.get("version"), 1, SAVE_VERSION):
		return false
	var candidate := data.duplicate(true)
	if int(candidate["version"]) == 1:
		candidate.merge({"world_seed": DEFAULT_SEED, "difficulty": "standard", "structures": {"collector": false, "garden": false, "market": false}, "noise": 0, "watch_active": false, "trade_used": {}, "last_event": {}}, false)
		if candidate.get("barricades") is Array:
			for barrier in candidate["barricades"]:
				if barrier is Dictionary:
					barrier["durability"] = 3
	for field in ["pack", "storage", "site_loot", "structures", "trade_used", "last_event"]:
		if not candidate.get(field) is Dictionary:
			return false
	for field in ["generator_repaired", "generator_on", "shelf_built", "watch_active"]:
		if not candidate.get(field) is bool:
			return false
	for field in ["day", "world_seed", "hunger", "thirst", "health", "noise"]:
		var maximum := 1000000 if field == "day" else (2147483647 if field == "world_seed" else (10 if field == "noise" else 100))
		if not _whole(candidate.get(field), 1 if field == "day" else 0, maximum):
			return false
	if candidate.get("difficulty") not in ["standard", "relaxed"]:
		return false
	for structure_id in structures:
		if not candidate["structures"].get(structure_id) is bool:
			return false
	if candidate["structures"].size() != structures.size():
		return false
	for container in [candidate["pack"], candidate["storage"]]:
		if not _valid_items(container):
			return false
	if _weight(candidate["pack"]) > PACK_CAPACITY or _weight(candidate["storage"]) > (SHELF_STORAGE_CAPACITY if candidate["shelf_built"] else BASE_STORAGE_CAPACITY):
		return false
	if candidate["site_loot"].size() != catalog.sites.size():
		return false
	for site_id in catalog.sites:
		if not candidate["site_loot"].get(site_id) is Dictionary or not _valid_items(candidate["site_loot"][site_id]):
			return false
		var allowed: Dictionary = {}
		for drop in catalog.sites[site_id]["loot"]:
			allowed[drop["item"]] = int(drop["max"])
		for item_id in candidate["site_loot"][site_id]:
			if not allowed.has(item_id) or int(candidate["site_loot"][site_id][item_id]) > int(allowed[item_id]):
				return false
	if not candidate.get("barricades") is Array or candidate["barricades"].size() > 64:
		return false
	var positions: Array[Vector3] = []
	for barrier in candidate["barricades"]:
		if not barrier is Dictionary or not _whole(barrier.get("durability"), 1, 3):
			return false
		for key in ["x", "z", "rotation"]:
			if not _number(barrier.get(key)):
				return false
		var position := Vector3(float(barrier["x"]), 0, float(barrier["z"]))
		if position.length() < 3.0 or position.length() > 19.0:
			return false
		for existing in positions:
			if existing.distance_to(position) < 2.0:
				return false
		positions.append(position)
	if not candidate.get("player_position") is Array or candidate["player_position"].size() != 3:
		return false
	for coordinate in candidate["player_position"]:
		if not _number(coordinate) or absf(float(coordinate)) > 100000:
			return false
	for offer_id in candidate["trade_used"]:
		if not catalog.trade_offers.has(offer_id) or not _whole(candidate["trade_used"][offer_id], 0, int(catalog.trade_offers[offer_id]["limit"])):
			return false
	var allowed_events := {"day": 1000000, "threat": 3, "water": 4, "food": 2}
	for field in candidate["last_event"]:
		if field == "merchant":
			if not candidate["last_event"][field] is bool:
				return false
		elif not allowed_events.has(field) or not _whole(candidate["last_event"][field], 0, int(allowed_events[field])):
			return false
	# Godot's JSON parser returns numbers as floats. Keep quantities integer in live state.
	for container in [candidate["pack"], candidate["storage"], candidate["trade_used"]]:
		for item_id in container:
			container[item_id] = int(container[item_id])
	for container in candidate["site_loot"].values():
		for item_id in container:
			container[item_id] = int(container[item_id])
	for barrier in candidate["barricades"]:
		barrier["durability"] = int(barrier["durability"])
	for field in candidate["last_event"]:
		if field != "merchant":
			candidate["last_event"][field] = int(candidate["last_event"][field])
	pack = candidate["pack"]
	storage = candidate["storage"]
	site_loot = candidate["site_loot"]
	generator_repaired = candidate["generator_repaired"]
	generator_on = candidate["generator_on"] and generator_repaired and int(storage.get("fuel", 0)) > 0
	shelf_built = candidate["shelf_built"]
	barricades = candidate["barricades"]
	structures = candidate["structures"]
	day = int(candidate["day"])
	hunger = int(candidate["hunger"])
	thirst = int(candidate["thirst"])
	health = int(candidate["health"])
	world_seed = int(candidate["world_seed"])
	difficulty = candidate["difficulty"]
	noise = int(candidate["noise"])
	watch_active = candidate["watch_active"]
	trade_used = candidate["trade_used"]
	last_event = candidate["last_event"]
	weather = weather_for_day(day)
	player_position = Vector3(float(candidate["player_position"][0]), float(candidate["player_position"][1]), float(candidate["player_position"][2]))
	return true


func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _whole(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value) and float(value) >= minimum and float(value) <= maximum and float(value) == floorf(float(value))


func _valid_items(container: Dictionary) -> bool:
	for item_id in container:
		if not catalog.items.has(item_id) or not _whole(container[item_id], 0, MAX_COUNT):
			return false
	return true
