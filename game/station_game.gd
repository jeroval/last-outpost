extends Node3D

const CatalogScript = preload("res://game/core/content_catalog.gd")
const StateScript = preload("res://game/core/station_state.gd")
const WorldScript = preload("res://game/world/station_world.gd")
const PlayerScript = preload("res://game/player/third_person_controller.gd")
const HUDScript = preload("res://game/ui/station_hud.gd")
const MapScript = preload("res://game/ui/region_map.gd")
const SoundScript = preload("res://game/audio/soundscape.gd")
const SaveScript = preload("res://game/save/save_service.gd")

var catalog
var state
var world
var player
var hud
var sounds
var saves
var menu_camera: Camera3D
var active_target: Dictionary = {}
var build_mode := false
var build_rotation := 0.0
var build_preview: MeshInstance3D
var session_started := false
var message := "La route mène à un nouveau départ."
var chosen_destination := ""
var defeat_announced := false
var victory_announced := false
var volume := 0.45
var big_text := false
var at_main_menu := true


func _ready() -> void:
	catalog = CatalogScript.new()
	state = StateScript.new(catalog)
	saves = SaveScript.new()
	world = WorldScript.new(catalog)
	add_child(world)
	player = PlayerScript.new()
	player.position = state.player_position
	add_child(player)
	menu_camera = Camera3D.new()
	menu_camera.position = Vector3(32, 24, 37)
	add_child(menu_camera)
	menu_camera.look_at(Vector3(0, 0, 0))
	menu_camera.current = true
	sounds = SoundScript.new()
	add_child(sounds)
	_make_build_preview()
	hud = HUDScript.new()
	add_child(hud)
	hud.action.connect(_on_action)
	_load_settings()
	world.sync_state(state)
	_open_menu()
	_update_hud()


func _process(_delta: float) -> void:
	_update_target()
	_update_build_preview()
	_update_hud()
	if session_started and state.health == 0 and not defeat_announced:
		defeat_announced = true
		_pause_controls()
		hud.show_sheet("Le refuge n'a pas tenu", "La faim et la soif ont épuisé votre santé. Une réserve d'eau et un potager vous aideront à tenir plus longtemps.", [{"label": "Reprendre la sauvegarde", "command": "continue"}, {"label": "Nouvelle partie en Découverte", "command": "new", "value": "relaxed"}, {"label": "Accueil", "command": "menu"}], "defeat")
	if session_started and state.refuge_autonomous() and not victory_announced:
		victory_announced = true
		message = "Un refuge vivant ! Eau, potager et commerce sont prêts. Continuez à organiser vos réserves."
		sounds.play_feedback("build")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if build_mode:
			build_mode = false
		elif hud.modal_open:
			_close_overlay()
		else:
			_pause_controls()
			hud.show_menu(saves.exists(), true)
		get_viewport().set_input_as_handled()
		return
	if hud.modal_open or state.health == 0:
		return
	match event.keycode:
		KEY_E:
			if build_mode:
				_build_barricade()
			else:
				_interact()
		KEY_B: _on_action("build", "")
		KEY_R:
			if build_mode:
				build_rotation += PI / 2
		KEY_TAB: _show_inventory()
		KEY_M: _show_map()
		KEY_H: _show_help()
		KEY_N: _show_rest()
		KEY_1: _consume("food")
		KEY_2: _consume("water")
		KEY_K: _save_game(false)
		KEY_L: _load_game()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB and session_started and not hud.modal_open:
		_show_inventory()
		get_viewport().set_input_as_handled()


func _on_action(command: String, value := "") -> void:
	match command:
		"close": _close_overlay()
		"menu": _open_menu()
		"pause":
			_pause_controls()
			hud.show_menu(saves.exists(), true)
		"quit": get_tree().quit()
		"new":
			if saves.exists() or session_started:
				hud.show_sheet("Un nouveau départ", "Une nouvelle partie remplace la sauvegarde actuelle. Choisissez Continuer depuis l'accueil pour la conserver.", [{"label": "Commencer et remplacer la sauvegarde", "command": "start", "value": value}], "confirm")
			else:
				_start_new(value)
		"start": _start_new(value)
		"continue", "load": _load_game()
		"save":
			_save_game(false)
			hud.show_sheet("Sauvegarde", message, [{"label": "Reprendre", "command": "close"}])
		"help": _show_help()
		"settings": _show_settings()
		"volume":
			volume = float((int(round(volume * 4)) + 1) % 5) / 4.0
			sounds.sync(state.generator_on, volume)
			_save_settings()
			_show_settings()
		"text":
			big_text = not big_text
			hud.large_text(big_text)
			_save_settings()
			_show_settings()
		"inventory": _show_inventory()
		"station": _show_station()
		"deposit":
			if _near_stock():
				message = "Déposé : " + _describe(state.deposit())
			_show_inventory()
		"withdraw":
			if _near_stock():
				var moved: int = state.withdraw(value, 1)
				message = "%s repris dans le sac." % catalog.item_name(value) if moved > 0 else "Le sac est plein."
				world.sync_state(state)
				sounds.sync(state.generator_on, volume)
			_show_inventory()
		"consume":
			_consume(value)
			_show_inventory()
		"upgrade":
			if _near_stock():
				var result: Dictionary
				if value == "shelf":
					var built: bool = state.build_shelf()
					result = {"ok": built, "message": "Étagère installée : le stock peut contenir 48 unités." if built else "Il faut 3 bois et 1 ferraille dans le stock."}
				else:
					result = state.upgrade_station(value)
				message = result["message"]
				world.sync_state(state)
				if result["ok"]:
					sounds.play_feedback("build")
			_show_station()
		"build":
			if not session_started:
				return
			_close_overlay()
			build_mode = not build_mode
			message = "Placez la barricade sur un sol libre. Coût : 2 bois et 1 ferraille du stock."
		"map": _show_map()
		"destination":
			chosen_destination = value
			_close_overlay()
		"rest": _show_rest()
		"watch":
			state.set_watch(not state.watch_active)
			_show_rest()
		"repair":
			if _at_base():
				message = state.repair_barricades()["message"]
				world.sync_state(state)
			_show_rest()
		"rest_commit":
			if not _at_base():
				return
			message = state.advance_day()
			world.sync_state(state)
			sounds.sync(state.generator_on, volume)
			_save_game(true)
			hud.show_sheet("Au matin · jour %d" % state.day, message, [{"label": "Reprendre l'exploration", "command": "close"}, {"label": "Voir la station", "command": "station"}], "report")
		"trade":
			if _at_base():
				message = state.trade(value)["message"]
			_show_trade()
		"trader": _show_trade()
	_update_hud()


func _start_new(difficulty: String) -> void:
	state = StateScript.new(catalog, randi_range(1, 999999))
	state.difficulty = difficulty
	player.position = state.player_position
	player.velocity = Vector3.ZERO
	chosen_destination = ""
	defeat_announced = false
	victory_announced = false
	session_started = true
	at_main_menu = false
	world.sync_state(state)
	player.camera.current = true
	sounds.set_active(true)
	sounds.sync(false, volume)
	message = "Bienvenue. L'entrepôt contient les matériaux de votre première étagère."
	_save_game(true)
	_pause_controls()
	hud.show_sheet("Bienvenue sur la route", "Votre première étape : récupérer du bois et de la ferraille à l'entrepôt, puis les rapporter au stock pour installer une étagère. Le garage vous aidera ensuite à rétablir l'électricité.\n\nSuivez le repère doré, ou ouvrez la carte avec M. Approchez-vous d'un lieu puis appuyez sur E. Le temps avance lorsque vous choisissez de passer la nuit : explorez à votre rythme.", [{"label": "Je pars explorer", "command": "close"}, {"label": "Voir les commandes", "command": "help"}], "welcome")


func _open_menu() -> void:
	if session_started and not at_main_menu and state.health > 0:
		_save_game(true)
	at_main_menu = true
	_pause_controls()
	menu_camera.current = true
	sounds.set_active(false)
	hud.show_menu(saves.exists())


func _pause_controls() -> void:
	player.set_controls(false)
	build_mode = false


func _close_overlay() -> void:
	if not session_started or at_main_menu:
		_open_menu()
		return
	hud.show_game()
	player.camera.current = true
	player.set_controls(state.health > 0)
	sounds.set_active(true)
	sounds.sync(state.generator_on, volume)


func _update_target() -> void:
	active_target = {}
	var best := 3.1
	for candidate in world.interactables:
		if candidate["kind"] == "trader" and not state.trader_present():
			continue
		var marker: Node3D = candidate["node"]
		var distance := Vector2(player.position.x, player.position.z).distance_to(Vector2(marker.position.x, marker.position.z))
		if distance < best:
			best = distance
			active_target = candidate


func _interact() -> void:
	if active_target.is_empty():
		message = "Approchez-vous du repère. M ouvre la carte."
		return
	match str(active_target["kind"]):
		"site":
			var found: Dictionary = state.scavenge(str(active_target["id"]))
			message = "Récupéré : " + _describe(found) if not found.is_empty() else "Lieu fouillé ou sac plein. Tab affiche votre inventaire."
			if not found.is_empty():
				sounds.play_feedback()
		"stash":
			var moved: Dictionary = state.deposit()
			message = "Déposé au stock : " + _describe(moved) if not moved.is_empty() else "Stock de la station."
			_show_station()
		"generator":
			if not state.generator_repaired:
				message = "Générateur réparé ! Déposez du carburant au stock pour l'allumer." if state.repair_generator() else "Il faut 3 ferrailles et 1 câble dans le stock."
			elif state.toggle_generator():
				message = "Lumières allumées. Le carburant et le bruit seront comptés à la prochaine nuit." if state.generator_on else "Générateur arrêté. Carburant préservé, bruit réduit."
			else:
				message = "Il manque du carburant dans le stock. La cuve en contient."
			world.sync_state(state)
			sounds.sync(state.generator_on, volume)
			sounds.play_feedback("build")
		"trader": _show_trade()
	world.sync_state(state)


func _near_stock() -> bool:
	return Vector2(player.position.x + 5, player.position.z - 2.2).length() < 4.0


func _at_base() -> bool:
	return Vector2(player.position.x, player.position.z).length() < 19.0


func _show_inventory() -> void:
	_pause_controls()
	var choices: Array = []
	for item_id in catalog.items:
		var carried := int(state.pack.get(item_id, 0))
		var stored := int(state.storage.get(item_id, 0))
		choices.append({"label": "%s  ·  sac %d / stock %d  —  reprendre 1" % [catalog.item_name(item_id), carried, stored], "command": "withdraw", "value": item_id, "disabled": not _near_stock() or stored == 0})
	for item_id in ["food", "water"]:
		choices.append({"label": "Manger une ration" if item_id == "food" else "Boire une bouteille", "command": "consume", "value": item_id, "disabled": int(state.pack.get(item_id, 0)) == 0})
	choices.append({"label": "Déposer tout le sac", "command": "deposit", "disabled": not _near_stock() or state.pack.is_empty()})
	choices.append({"label": "Améliorer la station", "command": "station", "disabled": not _near_stock()})
	hud.show_sheet("Sac & réserves", "%s\nSac %d/%d · Stock %d/%d. Les transferts se font près du stock. Gardez des provisions pour la route." % [message, state.carried_weight(), state.PACK_CAPACITY, state.stored_weight(), state.storage_capacity()], choices, "inventory")


func _show_station() -> void:
	_pause_controls()
	var choices: Array = [{"label": "Ouvrir le sac et reprendre des provisions", "command": "inventory"}]
	for recipe_id in ["shelf", "collector", "garden", "market"]:
		if not catalog.recipes.has(recipe_id):
			continue
		var recipe: Dictionary = catalog.recipes[recipe_id]
		var built: bool = state.shelf_built if recipe_id == "shelf" else bool(state.structures.get(recipe_id, false))
		var upgrade: Dictionary = state.upgrade_status(recipe_id)
		var requirement := ""
		if not upgrade["requirements"].is_empty():
			requirement = " (d'abord : " + str(catalog.recipes[upgrade["requirements"][0]]["name"]) + ")"
		choices.append({"label": ("Installé · " if built else "") + str(recipe["name"]) + "  —  " + _describe(recipe["inputs"]) + requirement, "command": "upgrade", "value": recipe_id, "disabled": built or not _near_stock() or not upgrade["affordable"], "tooltip": str(recipe.get("description", ""))})
	choices.append({"label": "Placer une barricade · 2 bois + 1 ferraille", "command": "build", "disabled": not state.can_afford("barricade")})
	choices.append({"label": "Préparer la prochaine nuit", "command": "rest"})
	choices.append({"label": "Rencontrer le marchand", "command": "trader", "disabled": not state.trader_present()})
	hud.show_sheet("Le refuge · atelier & stock", message + "\nLe récupérateur produit l'eau, le potager la nourriture, le comptoir permet le troc." + ("" if _near_stock() else "\nApprochez-vous du stock pour construire et transférer les ressources."), choices, "station")


func _show_rest() -> void:
	_pause_controls()
	var forecast: Dictionary = state.next_day_preview()
	var choices: Array = [{"label": "Passer la nuit et sauvegarder", "command": "rest_commit", "disabled": not _at_base()}, {"label": "Veille : " + ("activée" if state.watch_active else "désactivée") + " · coûte 1 nourriture", "command": "watch", "disabled": not _at_base()}, {"label": "Réparer les barricades avec le bois du stock", "command": "repair", "disabled": not _at_base()}, {"label": "Vérifier mes provisions", "command": "inventory"}]
	hud.show_sheet("Avant la nuit", str(forecast.get("summary", "")) + "\n\nFaim : %d · Soif : %d. La nourriture et l'eau du sac se consomment avec 1 et 2.\n%s" % [state.hunger, state.thirst, "Vous êtes au refuge." if _at_base() else "Revenez au refuge pour passer la nuit."], choices, "rest")


func _show_trade() -> void:
	_pause_controls()
	var choices: Array = []
	for offer_id in catalog.trade_offers:
		var offer: Dictionary = catalog.trade_offers[offer_id]
		var quota: int = int(offer["limit"]) - int(state.trade_used.get(offer_id, 0))
		choices.append({"label": _describe(offer["give"]) + "  →  " + _describe(offer["receive"]) + "  ·  %d échange(s) restant(s)" % quota, "command": "trade", "value": offer_id, "disabled": not state.trader_present() or not _at_base() or quota <= 0})
	hud.show_sheet("Le marchand de la route", message + "\nLes échanges utilisent le stock de la station. Les offres sont limitées par visite. Le comptoir attire une visite un jour sur deux.", choices, "trade")


func _show_map() -> void:
	_pause_controls()
	var contents = hud.show_sheet("Les environs", "Cliquez sur un repère pour le suivre. Le point blanc indique votre position.", [], "map")
	var map = MapScript.new()
	map.player_position = player.position
	map.selected = _destination_id()
	for destination in world.interactables:
		if destination["id"] == "trader" and not state.trader_present():
			continue
		map.destinations.append({"id": destination["id"], "name": destination["label"], "position": destination["node"].position})
	map.destination_selected.connect(func(id: String): _on_action("destination", id))
	contents.add_child(map)
	for place in world.interactables:
		if place["id"] == "trader" and not state.trader_present():
			continue
		hud._button(contents, "Suivre : " + str(place["label"]), "destination", str(place["id"]))
	hud._button(contents, "Reprendre le guidage de l'objectif", "destination", "")


func _show_help() -> void:
	_pause_controls()
	hud.show_sheet("Vos premiers pas", "1. Suivez le repère doré vers l'entrepôt. E permet de fouiller à proximité.\n2. Rapportez les matériaux au stock. E dépose le sac et ouvre l'atelier.\n3. Installez l'étagère, réparez le générateur, puis produisez eau et nourriture.\n4. Avant la nuit, prévoyez les réserves et la défense.\n\nZQSD / WASD / flèches : déplacement     Maj : courir     Espace : sauter\nClic droit + souris : orienter la caméra     Molette : zoomer\nTab : sac     M : carte     B : barricade     R : rotation     Échap : annuler / pause\n1 : manger     2 : boire     N : préparer la nuit     K : sauvegarder\n\nLe temps avance uniquement en passant la nuit. Les bâtiments et les réserves sont sauvegardés. Les menus se parcourent aussi avec Tab et Entrée.", [{"label": "C'est parti", "command": "close"}], "help")


func _show_settings() -> void:
	_pause_controls()
	hud.show_sheet("Réglages & confort", "Le son, la taille des textes et votre progression sont conservés localement. Le mode Découverte se choisit au début d'une partie.", [{"label": "Volume : %d %% · cliquer pour changer" % int(volume * 100), "command": "volume"}, {"label": "Grands textes : " + ("oui" if big_text else "non"), "command": "text"}], "settings")


func _consume(item_id: String) -> void:
	message = "Provision consommée." if state.consume(item_id) else "Reprenez une provision au stock ou fouillez la maison."
	sounds.play_feedback()


func _save_game(automatic: bool) -> void:
	if state.health <= 0:
		if not automatic:
			message = "La dernière sauvegarde vivante est conservée."
		return
	state.player_position = player.position
	var result: Dictionary = saves.save(state)
	if not automatic or not result["ok"]:
		message = result["message"]


func _load_game() -> bool:
	_pause_controls()
	var result: Dictionary = saves.load_into(state, true)
	message = result["message"]
	if not result["ok"]:
		hud.show_sheet("Reprendre une partie", message, [{"label": "Retour à l'accueil", "command": "menu"}])
		return false
	player.position = state.player_position
	player.velocity = Vector3.ZERO
	defeat_announced = false
	victory_announced = false
	session_started = true
	at_main_menu = false
	world.sync_state(state)
	_close_overlay()
	return true


func _destination_id() -> String:
	if not chosen_destination.is_empty() and (chosen_destination != "trader" or state.trader_present()):
		return chosen_destination
	return str(state.next_objective().get("target", "garage"))


func _update_hud() -> void:
	var goal: Dictionary = state.next_objective()
	var destination := "M  Carte des environs"
	for place in world.interactables:
		if place["id"] == _destination_id():
			var delta: Vector3 = place["node"].position - player.position
			var direction := "Nord" if delta.z < -2 else ("Sud" if delta.z > 2 else "")
			direction += ("-" if direction != "" else "") + ("Est" if delta.x > 2 else "Ouest") if absf(delta.x) > 2 else ""
			destination = "%s · %dm\n%s" % [direction, int(Vector2(delta.x, delta.z).length()), place["label"]]
			break
	var interaction := "E  Interagir à proximité   ·   Suivez le repère doré"
	if not active_target.is_empty():
		interaction = "E  " + str(active_target["label"])
	if build_mode:
		interaction = "E  Placer   ·   R  Tourner   ·   Échap  Annuler"
	hud.update_display("JOUR %02d · %s · %s" % [state.day, state.weather, "DÉCOUVERTE" if state.difficulty == "relaxed" else "SURVIE"], "Santé %d   Faim %d   Soif %d" % [state.health, state.hunger, state.thirst], "Sac %d/%d   ·   Stock %d/%d   ·   Énergie %s" % [state.carried_weight(), state.PACK_CAPACITY, state.stored_weight(), state.storage_capacity(), "ON" if state.generator_on else "OFF"], str(goal.get("title", "Restaurer le refuge")), destination, interaction, message)
	hud.goal_hint.text = str(goal.get("hint", ""))
	world.update_guidance(player.position, _destination_id())


func _describe(container: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in container:
		if int(container[item_id]) > 0:
			parts.append("%s ×%d" % [catalog.item_name(item_id), int(container[item_id])])
	return ", ".join(parts) if not parts.is_empty() else "rien"


func _make_build_preview() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 1.2, 0.25)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	build_preview = MeshInstance3D.new()
	build_preview.mesh = mesh
	build_preview.material_override = material
	build_preview.visible = false
	add_child(build_preview)


func _preview_position() -> Vector3:
	var ahead: Vector3 = player.facing_direction() * 3.0
	return Vector3(snappedf(player.position.x + ahead.x, 0.5), 0, snappedf(player.position.z + ahead.z, 0.5))


func _can_build(position: Vector3) -> bool:
	if not state.can_afford("barricade") or not world.can_place_barricade(position):
		return false
	if position.length() > 19.0 or position.length() < 3.0:
		return false
	for barrier in state.barricades:
		if Vector2(float(barrier["x"]), float(barrier["z"])).distance_to(Vector2(position.x, position.z)) < 2.0:
			return false
	return true


func _update_build_preview() -> void:
	build_preview.visible = build_mode
	if not build_mode:
		return
	var position := _preview_position()
	build_preview.position = position + Vector3(0, 0.6, 0)
	build_preview.rotation.y = build_rotation
	var material: StandardMaterial3D = build_preview.material_override
	material.albedo_color = Color(0.45, 0.85, 0.70, 0.45) if _can_build(position) else Color(0.9, 0.35, 0.32, 0.45)


func _build_barricade() -> void:
	var position := _preview_position()
	if not _can_build(position):
		message = "Emplacement bloqué ou matériaux manquants : 2 bois et 1 ferraille."
		return
	if state.build_barricade(position, build_rotation):
		world.sync_state(state)
		message = "Barricade construite. Elle protège le refuge pendant les nuits bruyantes."
		sounds.play_feedback("build")
		build_mode = false


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://last_outpost_settings.cfg") == OK:
		volume = clampf(float(config.get_value("comfort", "volume", 0.45)), 0, 1)
		big_text = bool(config.get_value("comfort", "large_text", false))
	hud.large_text(big_text)
	sounds.sync(false, volume)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("comfort", "volume", volume)
	config.set_value("comfort", "large_text", big_text)
	config.save("user://last_outpost_settings.cfg")
