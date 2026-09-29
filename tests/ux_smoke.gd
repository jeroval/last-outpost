extends SceneTree

const Catalog = preload("res://game/core/content_catalog.gd")
const State = preload("res://game/core/station_state.gd")
const Saves = preload("res://game/save/save_service.gd")

# The production settings hooks are replaced before _ready can read or write
# personal settings. Replacing saves here also precedes the first menu exists().
class IsolatedGame:

	extends "res://game/station_game.gd"
	var test_save_path := ""
	var settings_writes := 0

	func _load_settings() -> void:
		saves = SaveScript.new(test_save_path)
		volume = 0.45
		big_text = false
		hud.large_text(false)
		sounds.sync(false, volume)

	func _save_settings() -> void:
		settings_writes += 1


var game: IsolatedGame
var fixture_paths: Array[String] = []
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var prefix := "user://last_outpost_ux_test_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var game_path := prefix + "_game.json"
	var service_path := prefix + "_service.json"
	var missing_path := prefix + "_missing.json"
	fixture_paths.assign([game_path, service_path, missing_path])
	game = IsolatedGame.new()
	game.test_save_path = game_path
	root.add_child(game)
	await process_frame
	_check(game.saves.path == game_path and not game.saves.exists(), "Les sauvegardes du test sont isolées avant le premier accueil")
	_check(game.hud.current_screen == "menu" and not game.player.controls_enabled, "L'accueil bloque les déplacements")
	game.state.pack = {"food": 1, "water": 1}
	game.state.hunger = 20
	game.state.thirst = 20
	var menu_snapshot: Dictionary = game.state.snapshot()
	for key in [KEY_N, KEY_1, KEY_2]:
		game._unhandled_input(_key_event(key))
	_check(game.hud.current_screen == "menu" and game.state.snapshot() == menu_snapshot, "N, 1 et 2 n'agissent pas derrière l'accueil")

	game._start_new("relaxed")
	_check(game.state.difficulty == "relaxed" and game.hud.current_screen == "welcome", "Une partie Découverte ouvre le guide de départ")
	_check(not game.player.controls_enabled and game.saves.exists(), "Le guide bloque le mouvement et la nouvelle partie est sauvegardée")
	var before_welcome: Vector3 = game.player.position
	await _hold_key(KEY_Z, 4)
	_check(game.player.position.is_equal_approx(before_welcome), "Une touche de déplacement ne bouge pas le joueur derrière le guide")
	game.hud.action.emit("close", "")
	_check(game.player.controls_enabled and game.hud.current_screen == "game", "Fermer le guide rend les commandes du joueur")
	var before_movement: Vector3 = game.player.position
	await _hold_key(KEY_Z, 5)
	_check(Vector2(game.player.position.x, game.player.position.z).distance_to(Vector2(before_movement.x, before_movement.z)) > 0.01, "Le déplacement fonctionne une fois le guide fermé")

	game.hud.action.emit("pause", "")
	var pause_snapshot: Dictionary = game.state.snapshot()
	game._unhandled_input(_key_event(KEY_N))
	_check(game.hud.current_screen == "pause" and game.state.snapshot() == pause_snapshot and not game.player.controls_enabled, "N ne prépare pas la nuit derrière la pause")
	game.hud.action.emit("close", "")
	game._input(_key_event(KEY_TAB))
	_check(game.hud.current_screen == "inventory" and not game.player.controls_enabled, "Tab ouvre le sac avant la navigation clavier des boutons")
	game.hud.action.emit("close", "")

	game.state.pack = {"water": 1}
	game.hud.action.emit("menu", "")
	var saved_at_menu: Variant = JSON.parse_string(FileAccess.get_file_as_string(game_path))
	_check(game.at_main_menu and saved_at_menu is Dictionary and saved_at_menu["pack"].size() == 1 and int(saved_at_menu["pack"].get("water", 0)) == 1, "Retourner à l'accueil conserve les ressources récentes")
	game.hud.action.emit("settings", "")
	var saw_mute := false
	for i in range(5):
		game.hud.action.emit("volume", "")
		_check(game.volume >= 0 and game.volume <= 1, "Le volume reste borné (palier %d)" % i)
		saw_mute = saw_mute or is_zero_approx(game.volume)
	_check(saw_mute and game.settings_writes == 5, "Le réglage parcourt un mode muet sans écrire les réglages personnels")
	game.hud.action.emit("close", "")
	_check(game.at_main_menu and game.hud.current_screen == "menu" and not game.player.controls_enabled, "Fermer les réglages ouverts depuis l'accueil retourne à l'accueil")
	game.hud.action.emit("continue", "")
	_check(not game.at_main_menu and game.player.controls_enabled, "Continuer reprend une partie vivante")
	game.saves = Saves.new(missing_path)
	_check(not game._load_game() and game.hud.modal_open and not game.player.controls_enabled, "Un chargement introuvable bloque les déplacements derrière son message")
	game.saves = Saves.new(game_path)
	_check(game._load_game(), "La partie isolée reste chargeable après un échec")
	var living_save := FileAccess.get_file_as_string(game_path)
	game.state.health = 0
	game._save_game(true)
	_check(FileAccess.get_file_as_string(game_path) == living_save, "Une mort ne remplace pas automatiquement la dernière sauvegarde vivante")
	game.state.health = 100
	await _test_stock_and_guidance()
	await _test_player_physics()

	_test_save_service(service_path)
	game.sounds.set_active(false)
	game.sounds.feedback.stop()
	# Audio playback releases its stream on the mixing thread after stop().
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	_cleanup()
	if not failures.is_empty():
		for reason in failures:
			push_error("UX FAIL: " + reason)
		quit(1)
		return
	print("UX OK: %d contrôles — accueil, clavier, pause, stock, guidage, confort, reprise et sauvegardes isolées" % checks)
	quit()


func _test_stock_and_guidance() -> void:
	# LO-001: exercise actual E interaction and connected inventory button signals.
	game.state = State.new(game.catalog, 319)
	game.state.pack = {"food": 2, "water": 2}
	game.state.hunger = 20
	game.state.thirst = 20
	game.chosen_destination = ""
	game.world.sync_state(game.state)
	game.hud.action.emit("close", "")
	if not _stand_near("stash"):
		return
	game._unhandled_input(_key_event(KEY_E))
	_check(game.hud.current_screen == "station" and game.state.pack.is_empty() and game.state.storage == {"food": 2, "water": 2}, "LO-001 E au stock dépose le sac et ouvre l'atelier")
	if not _press_button("Ouvrir le sac et reprendre des provisions"):
		return
	_check(game.hud.current_screen == "inventory", "LO-001 le bouton de l'atelier ouvre les réserves")
	if not _press_button("Eau  ·") or not _press_button("Nourriture  ·"):
		return
	_check(game.state.pack == {"water": 1, "food": 1} and game.state.storage == {"food": 1, "water": 1}, "LO-001 les boutons reprendre transfèrent une unité chacun sans duplication")
	if not _press_button("Manger une ration") or not _press_button("Boire une bouteille"):
		return
	_check(game.state.pack.is_empty() and game.state.storage == {"food": 1, "water": 1}, "LO-001 les boutons consommer utilisent exactement les provisions reprises")
	_check(game.state.hunger == 50 and game.state.thirst == 55 and game.hud.status.text.contains("Faim 50") and game.hud.status.text.contains("Soif 55"), "LO-001 la consommation met à jour les besoins et leur affichage")
	var eat_button := _find_button("Manger une ration")
	var drink_button := _find_button("Boire une bouteille")
	_check(eat_button != null and drink_button != null and eat_button.disabled and drink_button.disabled, "LO-001 les actions de consommation deviennent indisponibles quand le sac est vide")

	# LO-006: the displayed destination must change after the real scavenge action.
	game.state = State.new(game.catalog, 319)
	game.chosen_destination = ""
	game.world.sync_state(game.state)
	game.hud.action.emit("close", "")
	_check(game.hud.route.text.contains("Entrepôt"), "LO-006 le HUD guide initialement vers l'entrepôt")
	if not _stand_near("warehouse"):
		return
	game._unhandled_input(_key_event(KEY_E))
	await process_frame
	await process_frame
	_check(not game.state.pack.is_empty() and game.state.can_afford("shelf") == false, "LO-006 la fouille remplit le sac avant tout dépôt")
	_check(game._destination_id() == "stash" and game.hud.route.text.contains("Stock & atelier") and game.hud.goal_hint.text.contains("Déposez votre sac"), "LO-006 après fouille le HUD indique Stock et la consigne de dépôt")


func _stand_near(target_id: String) -> bool:
	for target in game.world.interactables:
		if target["id"] == target_id:
			game.player.position = target["node"].position + Vector3(0, 1, 0.5)
			game.player.velocity = Vector3.ZERO
			game._update_target()
			var found: bool = game.active_target.get("id", "") == target_id
			_check(found, "Interaction ciblée à proximité : " + target_id)
			return found
	_check(false, "Repère introuvable dans la scène : " + target_id)
	return false


func _find_button(text_prefix: String) -> Button:
	for candidate in game.hud.overlay.find_children("*", "Button", true, false):
		if candidate.text.begins_with(text_prefix):
			return candidate as Button
	return null


func _press_button(text_prefix: String) -> bool:
	var button := _find_button(text_prefix)
	var usable := button != null and button.is_visible_in_tree() and not button.disabled
	_check(usable, "Bouton visible et actif : " + text_prefix)
	if usable:
		button.pressed.emit()
	return usable


func _test_player_physics() -> void:
	game.player.set_controls(true)
	game.player.position = Vector3(70, 1, 70)
	for i in range(3):
		await physics_frame
	_check(absf(game.player.position.x) <= 40 and absf(game.player.position.z) <= 40, "Le joueur reste dans les limites du monde")
	game.player.position = Vector3(-30, 4, 25)
	game.player.velocity = Vector3.ZERO
	game.player.set_controls(false)
	var focus: Vector3 = game.player.global_position + Vector3(0, 1.25, 0)
	var offset: Vector3 = Basis(Vector3.UP, game.player.orbit_yaw) * Vector3(0, sin(game.player.orbit_pitch) * game.player.camera_distance, cos(game.player.orbit_pitch) * game.player.camera_distance)
	var obstacle := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.3)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	obstacle.add_child(collision)
	game.add_child(obstacle)
	obstacle.global_position = focus + offset * 0.5
	for i in range(2):
		await physics_frame
	var ray := PhysicsRayQueryParameters3D.create(focus, focus + offset)
	ray.exclude = [game.player.get_rid()]
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
	_check(not hit.is_empty() and hit.get("rid") == obstacle.get_rid(), "La fixture de caméra intercepte réellement le rayon physique")
	game.player._place_camera()
	_check(game.player.camera.global_position.distance_to(focus) < game.player.camera_distance - 1.0, "La caméra se rapproche pour ne pas traverser un obstacle")
	obstacle.queue_free()
	await physics_frame


func _test_save_service(path: String) -> void:
	var catalog = Catalog.new()
	var state = State.new(catalog, 319)
	var service = Saves.new(path)
	var original: Dictionary = state.snapshot()
	_check(service.save(state)["ok"], "La première sauvegarde est écrite")
	_check(not FileAccess.file_exists(path + ".tmp"), "Le fichier temporaire est installé par renommage")
	state.day = 4
	state.pack = {"food": 1, "water": 1}
	var latest: Dictionary = state.snapshot()
	_check(service.save(state)["ok"], "La sauvegarde suivante remplace la première")
	var backup_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + ".bak"))
	var backup_state = State.new(catalog)
	_check(backup_json is Dictionary and backup_state.restore(backup_json) and backup_state.snapshot() == original, "La copie de secours contient la précédente partie")
	var restored = State.new(catalog)
	_check(service.load_into(restored)["ok"] and restored.snapshot() == latest, "Le JSON écrit restaure le dernier état complet")

	var before_failure := FileAccess.get_file_as_string(path)
	var temporary_directory := ProjectSettings.globalize_path(path + ".tmp")
	_check(DirAccess.make_dir_absolute(temporary_directory) == OK, "Une destination temporaire non écrivable est simulée")
	_check(not service.save(state)["ok"] and FileAccess.get_file_as_string(path) == before_failure, "Un échec d'écriture conserve la sauvegarde installée")
	_check(DirAccess.remove_absolute(temporary_directory) == OK, "La fixture d'échec d'écriture est retirée")

	_write_fixture(path, "{corrompu")
	var recovered: Dictionary = service.load_into(restored)
	_check(recovered["ok"] and restored.snapshot() == original and str(recovered["message"]).contains("secours"), "Un JSON corrompu est récupéré depuis la copie de secours")
	var valid_backup := FileAccess.get_file_as_string(path + ".bak")
	restored.day = 5
	var recovered_progress: Dictionary = restored.snapshot()
	_check(service.save(restored)["ok"], "La partie récupérée peut être sauvegardée à nouveau")
	_check(FileAccess.get_file_as_string(path + ".bak") == valid_backup, "Après récupération, sauvegarder préserve la copie valide au lieu du primaire corrompu")
	restored.day = 6
	_check(service.save(restored)["ok"], "La sauvegarde suivant une récupération réussie reste possible")
	var rotated: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + ".bak"))
	var rotated_state = State.new(catalog)
	_check(rotated is Dictionary and rotated_state.restore(rotated) and rotated_state.snapshot() == recovered_progress, "Après une sauvegarde réparée, la rotation du backup reprend avec le primaire valide")
	for invalid_health in [{}, []]:
		_write_fixture(path + ".bak", valid_backup)
		var malformed: Dictionary = latest.duplicate(true)
		malformed["health"] = invalid_health
		_write_fixture(path, JSON.stringify(malformed))
		var fallback: Dictionary = service.load_into(restored, true)
		_check(fallback["ok"] and restored.snapshot() == original and str(fallback["message"]).contains("secours"), "Une santé de type %s permet la reprise depuis la copie de secours" % type_string(typeof(invalid_health)))
	var dead: Dictionary = latest.duplicate(true)
	dead["health"] = 0
	_write_fixture(path, JSON.stringify(dead))
	_check(service.load_into(restored, true)["ok"] and restored.health > 0 and restored.snapshot() == original, "La reprise vivante ignore une ancienne sauvegarde de défaite")
	_write_fixture(path + ".bak", "{corrompu")
	_write_fixture(path, "{corrompu")
	var unchanged: Dictionary = restored.snapshot()
	_check(not service.load_into(restored)["ok"] and restored.snapshot() == unchanged, "Deux sauvegardes corrompues échouent sans altérer la partie")


func _key_event(code: int, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event


func _hold_key(code: int, frames: int) -> void:
	Input.parse_input_event(_key_event(code))
	for i in range(frames):
		await physics_frame
	Input.parse_input_event(_key_event(code, false))
	await physics_frame


func _write_fixture(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "Écriture de la fixture impossible : " + path)
		return
	file.store_string(content)
	file.close()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)


func _cleanup() -> void:
	for path in fixture_paths:
		if not path.begins_with("user://last_outpost_ux_test_"):
			_check(false, "Nettoyage refusé hors du périmètre de test")
			continue
		for suffix in ["", ".bak", ".tmp"]:
			var absolute := ProjectSettings.globalize_path(path + suffix)
			if FileAccess.file_exists(path + suffix) or DirAccess.dir_exists_absolute(absolute):
				_check(DirAccess.remove_absolute(absolute) == OK, "Nettoyage de " + path + suffix)
