extends Node3D

const DAY_SECONDS := 60.0
const HALF := 8
const WOOD_COST := 5
const LAST_NIGHT := 5
const FIRE_CELL := Vector2i(0, 1)
const NIGHT_WEATHER := ["calme", "vent froid", "gel", "vent fort", "blizzard"]
const WEATHER_SHRINK := [0.0, 1.0, 0.5, 1.3, 1.6]
const WEATHER_PENALTY := [12, 17, 19, 22, 25]
const INK := Color("172e32")
const CREAM := Color("f3efdf")
const MUTED := Color("afc3bc")
const TEAL := Color("73c3ad")
const CORAL := Color("eb967b")
const TREE_SCENES: Array[PackedScene] = [
	preload("res://assets/third_party/polybuild_trees/tree1.glb"),
	preload("res://assets/third_party/polybuild_trees/tree2.glb"),
	preload("res://assets/third_party/polybuild_trees/tree3.glb"),
	preload("res://assets/third_party/polybuild_trees/tree4.glb"),
]
const TREE_SCALES := [0.82, 0.38, 0.40, 0.40]
const TREE_OFFSETS := [Vector2(7.168, -1.877), Vector2(2.651, -1.647), Vector2(-2.206, -1.632), Vector2(-7.138, -1.877)]
const TREE_COLORS := [Color("5d9b83"), Color("386e67"), Color("73a78c"), Color("4d8774")]

var rng := RandomNumberGenerator.new()
var camera: Camera3D
var sun: DirectionalLight3D
var terrain: Node3D
var props: Array[Dictionary] = []
var shelters: Array[Vector2i] = []
var survivors: Array[Dictionary] = []
var wood := 4
var food := 6
var cohesion := 100
var day := 1
var clock := 0.0
var paused := false
var finished := false
var mode := "wood"
var fire_mode := 0 # 0: braise, 1: flamme
var focus := Vector3.ZERO
var zoom := 26.0
var dragging := false
var message := "Première nuit : un survivant reste exposé. Le bois sert aux abris et au feu."

var day_label: Label
var stock_label: Label
var status_label: Label
var message_label: Label
var forecast_label: Label
var forecast_detail_label: Label
var fire_button: Button
var night_button: Button
var heat_disk: MeshInstance3D
var heat_ring: MeshInstance3D
var flame_mesh: MeshInstance3D
var fire_light: OmniLight3D
var buttons: Dictionary = {}


func _ready() -> void:
	rng.seed = 481516
	_make_environment()
	_make_terrain()
	_make_props()
	_make_shelter(Vector2i.ZERO)
	_make_fire()
	_make_survivors()
	_make_camera()
	_make_hud()
	_update_hud()


func _process(delta: float) -> void:
	if paused or finished:
		return
	clock += delta
	_move_survivors(delta)
	var daylight := clampf(sin(clock / DAY_SECONDS * PI), 0.0, 1.0)
	sun.light_energy = lerpf(0.35, 1.25, daylight)
	sun.light_color = Color("e9ad91").lerp(Color("fff0d9"), daylight)
	if clock >= DAY_SECONDS:
		clock -= DAY_SECONDS
		_end_day()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = maxf(17.0, zoom - 1.5)
			_place_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = minf(34.0, zoom + 1.5)
			_place_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not finished:
			_click_world(event.position)
	elif event is InputEventMouseMotion and dragging:
		focus.x = clampf(focus.x - event.relative.x * 0.026, -5.0, 5.0)
		focus.z = clampf(focus.z - event.relative.y * 0.026, -5.0, 5.0)
		_place_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and not finished:
			paused = not paused
			message = "Simulation en pause." if paused else "La vie reprend."
			_update_hud()
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()


func _make_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d7dfd3")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e3e9db")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-54, -34, 0)
	sun.light_color = Color("ffecd3")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)


func _make_terrain() -> void:
	terrain = Node3D.new()
	terrain.name = "Terrain"
	add_child(terrain)
	box(terrain, Vector3(0, -0.52, 0), Vector3(17.5, 0.65, 17.5), Color("30484a"))
	for x in range(-HALF, HALF + 1):
		for z in range(-HALF, HALF + 1):
			var shade: Color = Color("91aa91") if (x + z) % 3 == 0 else Color("9bb49a")
			if abs(x) < 3 and abs(z) < 3:
				shade = Color("b7bd9e")
			box(terrain, Vector3(x, -0.11, z), Vector3(0.96, 0.18, 0.96), shade)
	for edge in [-8.8, 8.8]:
		box(terrain, Vector3(0, -0.4, edge), Vector3(18.5, 0.48, 0.3), INK)
		box(terrain, Vector3(edge, -0.4, 0), Vector3(0.3, 0.48, 18.5), INK)


func _make_props() -> void:
	var cells: Array[Vector2i] = []
	for x in range(-HALF + 1, HALF):
		for z in range(-HALF + 1, HALF):
			if abs(x) > 2 or abs(z) > 2:
				cells.append(Vector2i(x, z))
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := cells[i]
		cells[i] = cells[j]
		cells[j] = held
	for i in range(17):
		_spawn_prop("tree", cells.pop_back())
	for i in range(13):
		_spawn_prop("berry", cells.pop_back())
	for i in range(8):
		_spawn_prop("rock", cells.pop_back())


func _spawn_prop(kind: String, cell: Vector2i) -> void:
	var node := Node3D.new()
	node.position = Vector3(cell.x, 0, cell.y)
	node.name = kind
	terrain.add_child(node)
	if kind == "tree":
		var variant := posmod(cell.x * 7 + cell.y * 11, TREE_SCENES.size())
		var model := TREE_SCENES[variant].instantiate() as Node3D
		var scale_factor: float = TREE_SCALES[variant]
		model.scale = Vector3.ONE * scale_factor
		model.position = Vector3(TREE_OFFSETS[variant].x, 0.0, TREE_OFFSETS[variant].y) * scale_factor
		var bark := StandardMaterial3D.new()
		bark.albedo_color = Color("70594d")
		var leaves := StandardMaterial3D.new()
		leaves.albedo_color = TREE_COLORS[variant]
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			mesh.mesh = mesh.mesh.duplicate()
			mesh.mesh.surface_set_material(0, bark)
			mesh.mesh.surface_set_material(1, leaves)
		node.add_child(model)
	elif kind == "berry":
		sphere(node, Vector3(0, 0.36, 0), Vector3(0.72, 0.56, 0.72), Color("477d69"))
		for offset in [Vector3(-0.31, 0.57, 0.12), Vector3(0.21, 0.57, -0.25), Vector3(0.31, 0.37, 0.27)]:
			sphere(node, offset, Vector3.ONE * 0.16, CORAL)
	else:
		sphere(node, Vector3(0, 0.22, 0), Vector3(0.54, 0.42, 0.48), Color("6f8984"))
	props.append({"kind": kind, "cell": cell, "node": node})


func _make_shelter(cell: Vector2i) -> void:
	shelters.append(cell)
	var node := Node3D.new()
	node.name = "Abri"
	node.position = Vector3(cell.x, 0, cell.y)
	terrain.add_child(node)
	box(node, Vector3(0, 0.43, 0), Vector3(1.65, 0.85, 1.45), Color("e6d9bc"))
	box(node, Vector3(0, 0.96, 0), Vector3(1.9, 0.18, 1.68), Color("31575a"))
	box(node, Vector3(0, 0.27, 0.74), Vector3(0.48, 0.54, 0.08), Color("3f6463"))
	box(node, Vector3(-0.5, 0.58, 0.74), Vector3(0.23, 0.23, 0.08), TEAL)
	box(node, Vector3(0.5, 0.58, 0.74), Vector3(0.23, 0.23, 0.08), TEAL)
	box(node, Vector3(-0.55, 1.22, 0), Vector3(0.15, 0.4, 0.15), CORAL)


func _make_fire() -> void:
	var fire := Node3D.new()
	fire.name = "Foyer"
	fire.position = Vector3(FIRE_CELL.x, 0, FIRE_CELL.y)
	terrain.add_child(fire)
	for offset in [Vector3(-0.38, 0.07, 0), Vector3(0.38, 0.07, 0), Vector3(0, 0.07, -0.38), Vector3(0, 0.07, 0.38)]:
		sphere(fire, offset, Vector3(0.32, 0.20, 0.25), Color("697875"))
	box(fire, Vector3(0, 0.15, 0), Vector3(0.65, 0.16, 0.18), Color("70594d"))
	box(fire, Vector3(0, 0.15, 0), Vector3(0.18, 0.16, 0.65), Color("70594d"))
	var flame_shape := CylinderMesh.new()
	flame_shape.top_radius = 0.0
	flame_shape.bottom_radius = 0.23
	flame_shape.height = 0.65
	flame_shape.radial_segments = 7
	flame_mesh = _mesh(fire, flame_shape, Vector3(0, 0.46, 0), Color("f2ad68"))
	fire_light = OmniLight3D.new()
	fire_light.light_color = Color("ffd0a0")
	fire_light.omni_range = 5.5
	fire_light.position.y = 0.7
	fire.add_child(fire_light)
	var disk_shape := CylinderMesh.new()
	disk_shape.top_radius = 1.0
	disk_shape.bottom_radius = 1.0
	disk_shape.height = 0.015
	var disk_material := StandardMaterial3D.new()
	disk_material.albedo_color = Color(1.0, 0.63, 0.36, 0.16)
	disk_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disk_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disk_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	disk_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	heat_disk = MeshInstance3D.new()
	heat_disk.mesh = disk_shape
	heat_disk.material_override = disk_material
	heat_disk.position.y = 0.025
	fire.add_child(heat_disk)
	var ring_shape := TorusMesh.new()
	ring_shape.inner_radius = 0.985
	ring_shape.outer_radius = 1.0
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color("d99470")
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	heat_ring = MeshInstance3D.new()
	heat_ring.mesh = ring_shape
	heat_ring.material_override = ring_material
	heat_ring.position.y = 0.065
	fire.add_child(heat_ring)


func _make_survivors() -> void:
	for i in range(3):
		var node := Node3D.new()
		node.name = "Survivant_%d" % (i + 1)
		node.position = Vector3(-1.5 + i * 0.8, 0, 1.8)
		terrain.add_child(node)
		cylinder(node, Vector3(0, 0.5, 0), 0.24, 0.65, [CORAL, TEAL, Color("e5c37d")][i])
		sphere(node, Vector3(0, 1.02, 0), Vector3.ONE * 0.27, Color("f4d9b4"))
		box(node, Vector3(0, 1.27, 0), Vector3(0.54, 0.13, 0.54), INK)
		survivors.append({"node": node, "task": "", "target": Vector3.ZERO, "prop": {}, "cell": Vector2i.ZERO})


func _make_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	add_child(camera)
	_place_camera()


func _place_camera() -> void:
	camera.size = zoom
	camera.position = focus + Vector3(17, 21, 17)
	camera.look_at(focus, Vector3.UP)


func _click_world(screen_pos: Vector2) -> void:
	if mode != "build":
		var wanted := "tree" if mode == "wood" else "berry"
		var closest: Dictionary = {}
		var distance := 58.0 if mode == "wood" else 35.0
		for prop in props:
			if prop["kind"] != wanted:
				continue
			var node: Node3D = prop["node"]
			var height := 1.35 if mode == "wood" else 0.35
			var on_screen := camera.unproject_position(node.global_position + Vector3.UP * height)
			var candidate := screen_pos.distance_to(on_screen)
			if candidate < distance:
				closest = prop
				distance = candidate
		if not closest.is_empty():
			_assign_task(mode, closest["cell"], closest)
			_update_hud()
			return
	var origin := camera.project_ray_origin(screen_pos)
	var ray := camera.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(origin, ray)
	if hit == null:
		return
	var point: Vector3 = hit
	var cell := Vector2i(roundi(point.x), roundi(point.z))
	if abs(cell.x) > HALF or abs(cell.y) > HALF:
		return
	if mode == "build":
		_queue_build(cell)
		return
	for prop in props:
		if prop["kind"] == ("tree" if mode == "wood" else "berry") and prop["cell"] == cell:
			_assign_task(mode, cell, prop)
			return
	message = "Choisissez un pin." if mode == "wood" else "Choisissez un buisson à baies."
	_update_hud()


func _queue_build(cell: Vector2i) -> void:
	if wood < WOOD_COST:
		message = "Il faut 5 bois pour construire un abri."
	elif _occupied(cell):
		message = "Cette case est occupée."
	else:
		wood -= WOOD_COST
		_assign_task("build", cell, {})
	_update_hud()


func _occupied(cell: Vector2i) -> bool:
	if cell == FIRE_CELL:
		return true
	for shelter in shelters:
		if shelter.distance_to(cell) < 2.0:
			return true
	for prop in props:
		if prop["cell"] == cell:
			return true
	for survivor in survivors:
		if survivor["task"] == "build" and survivor["cell"] == cell:
			return true
	return false


func _assign_task(action: String, cell: Vector2i, prop: Dictionary) -> void:
	for survivor in survivors:
		if action != "build" and survivor["task"] == action and survivor["cell"] == cell:
			message = "Cette récolte est déjà en cours."
			return
	var chosen := -1
	var distance := INF
	for i in range(survivors.size()):
		var survivor: Dictionary = survivors[i]
		if survivor["task"] != "":
			continue
		var node: Node3D = survivor["node"]
		var candidate := node.position.distance_to(Vector3(cell.x, 0, cell.y))
		if candidate < distance:
			chosen = i
			distance = candidate
	if chosen < 0:
		if action == "build":
			wood += WOOD_COST
		message = "Tous les survivants sont occupés."
		return
	survivors[chosen]["task"] = action
	survivors[chosen]["cell"] = cell
	survivors[chosen]["target"] = Vector3(cell.x, 0, cell.y)
	survivors[chosen]["prop"] = prop
	var travel := ceili(distance / 2.7)
	message = "Un survivant part %s : trajet d'environ %d s." % ["construire" if action == "build" else "récolter", travel]
	if travel > DAY_SECONDS - clock:
		message += " Il risque d'être dehors cette nuit."


func _move_survivors(delta: float) -> void:
	for i in range(survivors.size()):
		var survivor: Dictionary = survivors[i]
		if survivor["task"] == "":
			continue
		var node: Node3D = survivor["node"]
		var target: Vector3 = survivor["target"]
		node.position = node.position.move_toward(target, delta * 2.7)
		if node.position.distance_to(target) < 0.05:
			_complete_task(i)


func _complete_task(index: int) -> void:
	var task: String = survivors[index]["task"]
	var cell: Vector2i = survivors[index]["cell"]
	if task == "build":
		_make_shelter(cell)
		message = "Nouvel abri terminé. La colonie gagne en sécurité."
	else:
		var prop: Dictionary = survivors[index]["prop"]
		if props.has(prop):
			props.erase(prop)
			var node: Node3D = prop["node"]
			node.queue_free()
			if task == "wood":
				wood += 3
				message = "+3 bois. De quoi préparer un abri."
			else:
				food += 3
				message = "+3 nourriture. Les réserves remontent."
	survivors[index]["task"] = ""
	survivors[index]["prop"] = {}


func _end_day() -> void:
	var report := _night_forecast()
	wood -= report["wood_spent"]
	food = maxi(0, food - survivors.size())
	var penalty: int = report["missing_food"] * 22 + report["exposed"] * report["exposure_cost"]
	cohesion = clampi(cohesion - penalty + (4 if penalty == 0 else 0), 0, 100)
	var fire_text := "éteint" if report["wood_spent"] == 0 else ("braise" if fire_mode == 0 else "flamme")
	message = "Nuit %d (%s) : feu %s, %d bois. %d dehors, %d sans repas. Cohésion %d%%." % [day, report["weather"], fire_text, report["wood_spent"], report["exposed"], report["missing_food"], cohesion]
	if cohesion <= 0:
		finished = true
		message += " Colonie perdue. R : réessayer."
	elif day >= LAST_NIGHT:
		finished = true
		message += " Cinq nuits traversées ! R : rejouer."
	else:
		day += 1
		_spawn_new_berries()
	_update_hud()


func _night_forecast() -> Dictionary:
	var weather_index := mini(day - 1, NIGHT_WEATHER.size() - 1)
	var wood_needed := 2 if fire_mode == 0 else 4
	var wood_spent := wood_needed if wood >= wood_needed else 0
	var radius := 0.0
	if wood_spent > 0:
		radius = maxf(0.0, (2.8 if fire_mode == 0 else 4.8) - WEATHER_SHRINK[weather_index])
	var heated := 0
	for shelter in shelters:
		if Vector2(shelter).distance_to(Vector2(FIRE_CELL)) <= radius:
			heated += 1
	var away := 0
	for survivor in survivors:
		if survivor["task"] != "":
			away += 1
	var protected := mini(survivors.size() - away, heated * 2)
	return {
		"weather": NIGHT_WEATHER[weather_index],
		"wood_needed": wood_needed,
		"wood_spent": wood_spent,
		"radius": radius,
		"heated": heated,
		"away": away,
		"protected": protected,
		"exposed": survivors.size() - protected,
		"missing_food": maxi(0, survivors.size() - food),
		"exposure_cost": WEATHER_PENALTY[weather_index],
	}


func _toggle_fire_mode() -> void:
	if finished:
		return
	fire_mode = 1 - fire_mode
	message = "Foyer réglé sur %s : %d bois à la prochaine nuit." % ["braise" if fire_mode == 0 else "flamme", 2 if fire_mode == 0 else 4]
	_update_hud()


func _skip_to_night() -> void:
	if finished or paused:
		return
	clock = 0.0
	_end_day()


func _spawn_new_berries() -> void:
	var planted := 0
	for attempt in range(100):
		if planted >= 2:
			break
		var cell := Vector2i(rng.randi_range(-7, 7), rng.randi_range(-7, 7))
		if not _occupied(cell):
			_spawn_prop("berry", cell)
			planted += 1


func _update_hud() -> void:
	day_label.text = "JOUR %02d    ·    NUIT DANS %02ds" % [day, ceili(DAY_SECONDS - clock)]
	if finished:
		day_label.text = "PARTIE TERMINÉE · %s" % ["VICTOIRE" if cohesion > 0 else "DÉFAITE"]
	elif paused:
		day_label.text += "   ·   PAUSE"
	stock_label.text = "BOIS  %02d      NOURRITURE  %02d" % [wood, food]
	status_label.text = "COHÉSION  %d%%      ABRIS  %d      SURVIVANTS  %d" % [cohesion, shelters.size(), survivors.size()]
	message_label.text = message
	var forecast := _night_forecast()
	forecast_label.text = "NUIT %02d · %s · FEU %s" % [day, forecast["weather"].to_upper(), "BRAISE" if fire_mode == 0 else "FLAMME"]
	forecast_detail_label.text = "%d bois requis (%d en stock) · rayon %.1f cases\n%d/3 à l'abri · %d exposés · %d repas manquants" % [forecast["wood_needed"], wood, forecast["radius"], forecast["protected"], forecast["exposed"], forecast["missing_food"]]
	if finished:
		forecast_label.text = "BILAN DE L'EXPÉDITION"
		forecast_detail_label.text = "Cohésion finale : %d%%\nAppuyez sur R pour rejouer la même carte." % cohesion
	fire_button.text = "04   Foyer : %s · %d bois/nuit" % ["braise" if fire_mode == 0 else "flamme", forecast["wood_needed"]]
	fire_button.disabled = finished
	night_button.disabled = finished or paused
	_update_fire_visual(forecast)


func _update_fire_visual(forecast: Dictionary) -> void:
	var burning: bool = forecast["wood_spent"] > 0
	heat_disk.visible = burning
	heat_ring.visible = burning
	flame_mesh.visible = burning
	fire_light.visible = burning
	if burning:
		var radius: float = forecast["radius"]
		heat_disk.scale = Vector3(radius, 1.0, radius)
		heat_ring.scale = Vector3(radius, 0.25, radius)
		flame_mesh.scale = Vector3.ONE * (1.0 if fire_mode == 0 else 1.5)
		fire_light.light_energy = 0.35 if fire_mode == 0 else 0.65


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	var info := _panel(ui, Vector2(24, 24), Vector2(350, 176))
	_label(info, "LAST OUTPOST", Vector2(20, 15), 21, CREAM)
	_label(info, "UNE PETITE COLONIE, UN GRAND HIVER", Vector2(20, 44), 10, TEAL)
	day_label = _label(info, "", Vector2(20, 76), 17, CREAM)
	stock_label = _label(info, "", Vector2(20, 107), 15, MUTED)
	status_label = _label(info, "", Vector2(20, 137), 13, MUTED)

	var forecast_panel := _panel(ui, Vector2(414, 24), Vector2(466, 112))
	forecast_label = _label(forecast_panel, "", Vector2(18, 15), 14, TEAL)
	forecast_detail_label = _label(forecast_panel, "", Vector2(18, 45), 13, CREAM)

	var actions := _panel(ui, Vector2(-304, 24), Vector2(280, 420), true)
	_label(actions, "COMMANDES", Vector2(18, 15), 13, TEAL)
	_label(actions, "Choisissez puis cliquez sur le terrain", Vector2(18, 42), 11, MUTED)
	buttons["wood"] = _button(actions, "01   Couper un pin", Vector2(18, 79), "wood")
	buttons["food"] = _button(actions, "02   Cueillir des baies", Vector2(18, 135), "food")
	buttons["build"] = _button(actions, "03   Construire · 5 bois", Vector2(18, 191), "build")
	fire_button = _button(actions, "", Vector2(18, 247), "")
	fire_button.pressed.connect(_toggle_fire_mode)
	night_button = _button(actions, "05   Passer à la nuit", Vector2(18, 303), "")
	night_button.pressed.connect(_skip_to_night)
	_label(actions, "Clic droit : déplacer la vue\nMolette : zoom  ·  Espace : pause\nR : recommencer", Vector2(18, 355), 11, MUTED)

	var story := _panel(ui, Vector2(24, -164), Vector2(450, 140), false, true)
	_label(story, "JOURNAL DE BORD", Vector2(18, 14), 11, TEAL)
	message_label = _label(story, "", Vector2(18, 42), 15, CREAM)
	message_label.custom_minimum_size = Vector2(410, 72)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var objective := _panel(ui, Vector2(-304, -164), Vector2(280, 140), true, true)
	_label(objective, "OBJECTIF", Vector2(18, 14), 11, TEAL)
	var objective_text := _label(objective, "Survivez à 5 nuits. Prévoyez 1 repas par survivant, du bois pour le feu et des places d'abri dans sa chaleur.", Vector2(18, 42), 13, CREAM)
	objective_text.custom_minimum_size = Vector2(242, 85)
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_button_styles()


func _panel(parent: Control, offset: Vector2, panel_size: Vector2, right := false, bottom := false) -> Panel:
	var panel := Panel.new()
	panel.anchor_left = 1.0 if right else 0.0
	panel.anchor_right = panel.anchor_left
	panel.anchor_top = 1.0 if bottom else 0.0
	panel.anchor_bottom = panel.anchor_top
	panel.position = offset
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172e32e8")
	style.set_corner_radius_all(15)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _label(parent: Control, value: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Control, value: String, pos: Vector2, action: String) -> Button:
	var button := Button.new()
	button.text = value
	button.position = pos
	button.size = Vector2(244, 45)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("29474a")
	style.set_corner_radius_all(9)
	style.content_margin_left = 14
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", CREAM)
	if action != "":
		button.pressed.connect(_set_mode.bind(action))
	parent.add_child(button)
	return button


func _set_mode(action: String) -> void:
	mode = action
	_update_button_styles()


func _update_button_styles() -> void:
	for action in buttons:
		var button: Button = buttons[action]
		var style := StyleBoxFlat.new()
		style.bg_color = Color("3c7771") if action == mode else Color("29474a")
		style.set_corner_radius_all(9)
		style.content_margin_left = 14
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_color_override("font_color", CREAM if action == mode else MUTED)


func box(parent: Node3D, pos: Vector3, box_size: Vector3, color: Color) -> void:
	var shape := BoxMesh.new()
	shape.size = box_size
	_mesh(parent, shape, pos, color)


func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 7
	_mesh(parent, shape, pos, color)


func cone(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = 0.0
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 7
	_mesh(parent, shape, pos, color)


func sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, color: Color) -> void:
	var shape := SphereMesh.new()
	shape.radial_segments = 8
	shape.rings = 4
	var instance := _mesh(parent, shape, pos, color)
	instance.scale = scale_value


func _mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	parent.add_child(instance)
	return instance
