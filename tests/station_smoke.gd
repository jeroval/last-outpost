extends SceneTree

const CatalogScript = preload("res://game/core/content_catalog.gd")
const StateScript = preload("res://game/core/station_state.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = CatalogScript.new()
	if catalog.items.size() != 6 or catalog.sites.size() != 5:
		_fail("Catalogue incomplet")
		return
	var state = StateScript.new(catalog)
	var garage: Dictionary = state.scavenge("garage")
	if int(garage.get("scrap", 0)) < 3 or int(garage.get("wire", 0)) < 1 or state.carried_weight() > state.PACK_CAPACITY:
		_fail("Butin du garage ou capacité du sac incorrects")
		return
	state.deposit()
	state.scavenge("warehouse")
	state.deposit()
	if not state.can_afford("shelf") or not state.build_shelf() or state.storage_capacity() != 48:
		_fail("Le transport et l'étagère ne fonctionnent pas")
		return
	state.deposit()
	state.scavenge("pump")
	state.deposit()
	if not state.repair_generator() or not state.toggle_generator() or state.stage_name() != "AVANT-POSTE":
		_fail("La réparation et l'alimentation du générateur ne fonctionnent pas")
		return
	state.storage["fuel"] = 1
	state.advance_day()
	if state.generator_on or state.storage.has("fuel") or state.day != 2:
		_fail("Le générateur doit s'arrêter quand le carburant est épuisé")
		return
	state.scavenge("grove")
	state.deposit()
	if not state.build_barricade(Vector3(5, 0, 10), 0.0) or state.build_barricade(Vector3(5.5, 0, 10), 0.0):
		_fail("Construction ou contrôle de placement de barricade incorrect")
		return
	state.storage["fuel"] = 1
	if not state.toggle_generator() or not state.station_restored():
		_fail("La restauration complète de la station n'est pas reconnue")
		return
	state.scavenge("house")
	if not state.consume("food") or not state.consume("water"):
		_fail("La consommation de nourriture et d'eau ne fonctionne pas")
		return
	var restored = StateScript.new(catalog)
	if not restored.restore(state.snapshot()) or restored.snapshot() != state.snapshot():
		_fail("La sauvegarde versionnée ne restaure pas l'état")
		return
	if restored.restore({"version": 999}):
		_fail("Une sauvegarde incompatible a été acceptée")
		return
	var corrupt: Dictionary = state.snapshot()
	corrupt["site_loot"]["garage"] = "incorrect"
	if restored.restore(corrupt):
		_fail("Une sauvegarde avec butin invalide a été acceptée")
		return
	var game = load("res://scenes/station.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if game.world.interactables.size() != 8 or game.player.camera == null or game.state.stage_name() != "RUINE":
		_fail("La scène station ne démarre pas avec les systèmes attendus")
		return
	for target in game.world.interactables:
		if target["id"] == "garage":
			game.player.position = target["node"].position + Vector3(0, 1, 1.5)
			game._update_target()
			game._interact()
			break
	if not game.state.pack.has("scrap"):
		_fail("L'interaction avec un lieu ne transfère pas son butin")
		return
	for target in game.world.interactables:
		if target["id"] == "stash":
			game.player.position = target["node"].position + Vector3(0, 1, 1.5)
			game._update_target()
			game._interact()
			break
	if not game.state.storage.has("scrap") or not game.state.pack.is_empty():
		_fail("L'interaction avec le stock ne dépose pas le sac")
		return
	game.queue_free()
	await process_frame
	print("STATION OK: loot, transport, stockage, craft, énergie, survie, sauvegarde, scène")
	quit()


func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
