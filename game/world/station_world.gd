extends Node3D

const TREE_SCENES := [
	preload("res://assets/third_party/polybuild_trees/tree1.glb"),
	preload("res://assets/third_party/polybuild_trees/tree2.glb"),
]
const INK := Color("172e32")
const TEAL := Color("315f59")
const CORAL := Color("d99274")
const CREAM := Color("e8dfc6")

var catalog
var interactables: Array[Dictionary] = []
var generator_light: OmniLight3D
var sign_label: Label3D
var shelf_visual: Node3D
var power_lamps: Array[MeshInstance3D] = []
var barriers_node: Node3D
var collector_visual: Node3D
var garden_visual: Node3D
var market_visual: Node3D
var trader_visual: Node3D
var ruins_visual: Node3D
var guide: Node3D
var atmosphere: Environment
var sky_material: ShaderMaterial
var daylight: DirectionalLight3D
var rain_node: Node3D
var rain_drops: Array[MeshInstance3D] = []
var elapsed := 0.0


func _init(content: RefCounted) -> void:
	catalog = content


func _ready() -> void:
	_make_environment()
	_make_ground()
	_make_station()
	_make_sites()
	_make_trees()
	_make_details()
	_make_upgrades()
	_make_guidance()
	barriers_node = Node3D.new()
	barriers_node.name = "Barricades"
	add_child(barriers_node)


func _process(delta: float) -> void:
	elapsed += delta
	if guide != null:
		guide.rotation.y = elapsed * 0.35
	if trader_visual != null and trader_visual.visible:
		trader_visual.rotation.y = sin(elapsed * 0.6) * 0.08
	if rain_node != null and rain_node.visible:
		for i in range(rain_drops.size()):
			rain_drops[i].position.y -= delta * 13.0
			if rain_drops[i].position.y < 0:
				rain_drops[i].position.y = 13.0


func _make_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://game/world/outpost_sky.gdshader")
	sky_material.set_shader_parameter("cloud_noise", preload("res://game/world/cloud_noise.tres"))
	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce5dd")
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_density = 0.003
	env.fog_light_color = Color("b5c7bc")
	atmosphere = env
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("ffe7c8")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	daylight = sun
	add_child(sun)
	sky_material.set_shader_parameter("sun_direction", sun.global_basis.z.normalized())


func _make_ground() -> void:
	_box(self, Vector3(0, -0.55, 0), Vector3(90, 1, 90), Color("69765b"), true)
	_box(self, Vector3(0, -0.035, 20), Vector3(90, 0.08, 9), Color("354c50"))
	for x in range(-42, 45, 8):
		_box(self, Vector3(x, 0.015, 20), Vector3(3.8, 0.015, 0.12), CREAM)
	_box(self, Vector3(0, -0.015, 3), Vector3(30, 0.07, 25), Color("667678"))
	_box(self, Vector3(0, 0.02, 14), Vector3(28, 0.015, 0.16), Color("d5d1b3"))
	for x in [-13, -8, 8, 13]:
		_box(self, Vector3(x, 0.02, 8), Vector3(0.12, 0.015, 6), Color("d5d1b3"))
	_box(self, Vector3(-30, -0.01, -15), Vector3(12, 0.04, 12), Color("889b82"))
	_box(self, Vector3(30, -0.01, -15), Vector3(12, 0.04, 12), Color("889b82"))


func _make_station() -> void:
	var shop := Node3D.new()
	shop.name = "Boutique"
	add_child(shop)
	_building_shell(shop, Vector3(0, 0, -8), 13, 8, 3.3, 2.4, CREAM)
	_box(shop, Vector3(0, 3.45, -8), Vector3(13.8, 0.35, 8.6), TEAL)
	_box(shop, Vector3(1.3, 1.3, -4.7), Vector3(0.15, 2.6, 1.8), Color("506f70"))
	_box(shop, Vector3(-4, 0.55, -8), Vector3(2.8, 1.1, 1.0), Color("927759"))
	_box(shop, Vector3(4, 0.35, -10), Vector3(1.5, 0.7, 2.6), Color("526a60"))
	for x in [-4.0, 4.0]:
		_box(shop, Vector3(x, 1.9, -3.89), Vector3(2.8, 1.45, 0.12), Color("789b9a"))
		_box(shop, Vector3(x, 2.6, -3.82), Vector3(2.9, 0.08, 0.14), INK)
	_box(shop, Vector3(0, 4.15, -7.8), Vector3(7.2, 1.0, 0.3), INK)
	sign_label = _label(shop, "LAST OUTPOST", Vector3(0, 4.05, -7.56), 54, CREAM)
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var garage := Node3D.new()
	garage.name = "Garage de la station"
	add_child(garage)
	_box(garage, Vector3(11, 1.65, -8), Vector3(8, 3.3, 8), Color("b4bbae"), true)
	_box(garage, Vector3(11, 3.45, -8), Vector3(8.5, 0.3, 8.5), INK)
	_box(garage, Vector3(11, 1.55, -3.89), Vector3(5.5, 2.7, 0.12), Color("617f7c"))
	for y in [0.7, 1.4, 2.1]:
		_box(garage, Vector3(11, y, -3.79), Vector3(5.5, 0.06, 0.08), INK)
	var canopy := Node3D.new()
	canopy.name = "Auvent"
	add_child(canopy)
	_box(canopy, Vector3(0, 3.4, 3.8), Vector3(16, 0.32, 7.5), TEAL)
	_box(canopy, Vector3(0, 3.18, 7.5), Vector3(16, 0.24, 0.24), CORAL)
	for x in [-6.5, 6.5]:
		_box(canopy, Vector3(x, 1.6, 6.6), Vector3(0.23, 3.2, 0.23), INK)
		var lamp := _box(canopy, Vector3(x, 3.17, 3.4), Vector3(0.85, 0.06, 0.85), Color("758c86"))
		power_lamps.append(lamp)
	for x in [-3.5, 3.5]:
		var pump := Node3D.new()
		pump.position = Vector3(x, 0, 4)
		add_child(pump)
		_box(pump, Vector3(0, 0.8, 0), Vector3(0.9, 1.6, 0.65), Color("c0c4b5"), true)
		_box(pump, Vector3(0, 1.25, 0.37), Vector3(0.53, 0.37, 0.05), INK)
		_box(pump, Vector3(0, 1.9, 0), Vector3(1.1, 0.24, 0.8), CORAL)
	var stash := Node3D.new()
	stash.position = Vector3(-5, 0, 1)
	stash.name = "Stock de la station"
	add_child(stash)
	_box(stash, Vector3(0, 0.6, 0), Vector3(1.6, 1.2, 1.2), Color("8e775c"))
	_box(stash, Vector3(0, 1.25, 0), Vector3(1.8, 0.15, 1.4), INK)
	_add_interactable("stash", "stash", "Stock & atelier", stash.position + Vector3(0, 0, 1.2))
	shelf_visual = Node3D.new()
	shelf_visual.position = Vector3(-6.7, 0, -1.3)
	add_child(shelf_visual)
	for y in [0.55, 1.15, 1.75]:
		_box(shelf_visual, Vector3(0, y, 0), Vector3(1.7, 0.14, 0.7), Color("8e775c"))
	for x in [-0.75, 0.75]:
		_box(shelf_visual, Vector3(x, 0.9, 0), Vector3(0.12, 1.8, 0.7), INK)
	shelf_visual.visible = false
	var generator := Node3D.new()
	generator.name = "Générateur"
	generator.position = Vector3(-10, 0, -4)
	add_child(generator)
	_box(generator, Vector3(0, 0.55, 0), Vector3(1.7, 1.1, 1.2), Color("68817c"), true)
	_box(generator, Vector3(0, 1.1, 0), Vector3(1.9, 0.16, 1.35), INK)
	_box(generator, Vector3(0, 0.7, 0.62), Vector3(0.58, 0.35, 0.06), CORAL)
	generator_light = OmniLight3D.new()
	generator_light.light_color = Color("fff0bd")
	generator_light.omni_range = 16.0
	generator_light.light_energy = 1.5
	generator_light.position = Vector3(-2, 4, 2)
	add_child(generator_light)
	_add_interactable("generator", "generator", "Générateur", generator.position + Vector3(0, 0, 1.6))
	_label(self, "ATELIER", Vector3(11, 4.2, -3.3), 46, INK).billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _make_sites() -> void:
	for site_id in catalog.sites:
		var site: Dictionary = catalog.sites[site_id]
		var p := Vector3(float(site["position"][0]), 0, float(site["position"][1]))
		match str(site["kind"]):
			"garage":
				_building_shell(self, p + Vector3(0, 0, -2), 8, 5, 2.7, 4.4, Color("9aa99d"))
				_box(self, p + Vector3(0, 2.85, -2), Vector3(8.5, 0.25, 5.5), INK)
				_box(self, p + Vector3(0, 2.5, 0.55), Vector3(5, 0.4, 0.1), Color("607d7a"))
				_box(self, p + Vector3(2.5, 0.5, -3), Vector3(1.2, 1, 0.9), Color("927759"))
			"warehouse":
				_building_shell(self, p + Vector3(0, 0, -2), 10, 6, 3.4, 5.5, Color("b1aea0"))
				_box(self, p + Vector3(0, 3.55, -2), Vector3(10.6, 0.25, 6.6), INK)
				for x in [-2.2, 2.2]:
					_box(self, p + Vector3(x, 0.5, 1.5), Vector3(1.5, 1.0, 1.1), Color("90785d"))
			"house":
				_building_shell(self, p + Vector3(0, 0, -2), 7, 6, 3, 2.2, CREAM)
				_box(self, p + Vector3(0, 3.1, -2), Vector3(7.6, 0.35, 6.5), Color("846e63"))
				_box(self, p + Vector3(2, 1.75, 1.05), Vector3(1.5, 1.4, 0.1), Color("7a9b98"))
				_box(self, p + Vector3(-2, 0.4, -3), Vector3(1.6, 0.8, 2.4), Color("77816b"))
			"pump":
				_box(self, p + Vector3(0, 0.45, 0), Vector3(1.7, 0.9, 1.8), Color("747e72"))
				_box(self, p + Vector3(0, 1.0, 0), Vector3(1.1, 0.25, 1.3), INK)
			"grove":
				for offset in [Vector3(-2, 0, -2), Vector3(2, 0, -2), Vector3(0, 0, 2)]:
					_tree(p + offset, 0)
		_add_interactable("site", site_id, str(site["name"]), p)


func _make_trees() -> void:
	var coords := [Vector2(-33, -28), Vector2(-26, -32), Vector2(29, -28), Vector2(34, -18), Vector2(-32, 6), Vector2(31, 7), Vector2(-29, 30), Vector2(29, 29), Vector2(-8, 32), Vector2(10, 31), Vector2(-35, -3), Vector2(36, 25)]
	for i in range(coords.size()):
		_tree(Vector3(coords[i].x, 0, coords[i].y), i % 2)


func _tree(position: Vector3, variant: int) -> void:
	var model := TREE_SCENES[variant].instantiate() as Node3D
	var scale_factor := 1.5 if variant == 0 else 0.7
	model.scale = Vector3.ONE * scale_factor
	model.position = position + Vector3(7.168, 0, -1.877) * scale_factor if variant == 0 else position + Vector3(2.651, 0, -1.647) * scale_factor
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color("625247")
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color("718168") if variant == 0 else Color("536d61")
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.mesh = mesh.mesh.duplicate()
		if mesh.mesh.get_surface_count() > 1:
			mesh.mesh.surface_set_material(0, bark)
			mesh.mesh.surface_set_material(1, leaves)
	add_child(model)


func _add_interactable(kind: String, item_id: String, label: String, position: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = label
	marker.position = position
	add_child(marker)
	var tag := _label(marker, label, Vector3(0, 2.5, 0), 38, CREAM)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interactables.append({"kind": kind, "id": item_id, "label": label, "node": marker})
	var tile := _cylinder(marker, Vector3(0, 0.06, 0), 0.52, 0.03, Color("b8c9b0"))
	tile.name = "Repère"


func sync_state(state: RefCounted) -> void:
	generator_light.visible = state.generator_on
	for lamp in power_lamps:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("fbe8ab") if state.generator_on else Color("758c86")
		material.emission_enabled = state.generator_on
		material.emission = Color("fbe8ab")
		lamp.material_override = material
	shelf_visual.visible = state.shelf_built
	sign_label.text = "LAST OUTPOST · " + state.stage_name()
	collector_visual.visible = bool(state.structures.get("collector", false))
	garden_visual.visible = bool(state.structures.get("garden", false))
	market_visual.visible = bool(state.structures.get("market", false))
	trader_visual.visible = state.trader_present()
	ruins_visual.visible = not state.shelf_built
	var wet: bool = str(state.weather).to_lower().contains("pluie") or str(state.weather).to_lower().contains("orage")
	rain_node.visible = wet
	daylight.light_energy = 0.4 if wet else 0.75
	var storm: bool = str(state.weather).to_lower().contains("orage")
	sky_material.set_shader_parameter("coverage", 0.72 if storm else (0.62 if wet else 0.48))
	sky_material.set_shader_parameter("storm_amount", 1.0 if storm else (0.55 if wet else 0.0))
	for child in barriers_node.get_children():
		child.queue_free()
	for barrier in state.barricades:
		add_barricade(Vector3(float(barrier["x"]), 0, float(barrier["z"])), float(barrier["rotation"]), int(barrier.get("durability", 3)))


func add_barricade(position: Vector3, angle: float, durability := 3) -> void:
	var barrier := Node3D.new()
	barrier.position = position
	barrier.rotation.y = angle
	barriers_node.add_child(barrier)
	for index in range(maxi(0, durability)):
		var y := 0.35 * (index + 1)
		_box(barrier, Vector3(0, y, 0), Vector3(2.2, 0.28, 0.18), Color("927759"), true)
	for x in [-0.8, 0.8]:
		_box(barrier, Vector3(x, 0.6, 0), Vector3(0.18, 1.2, 0.26), INK)


func can_place_barricade(position: Vector3) -> bool:
	if absf(position.x) < 7.5 and position.z > -12.5 and position.z < -3.0:
		return false
	if position.x > 6.5 and position.x < 15.5 and position.z > -12.5 and position.z < -3.0:
		return false
	if position.z > 16.0:
		return false
	for destination in interactables:
		if Vector2(position.x, position.z).distance_to(Vector2(destination["node"].position.x, destination["node"].position.z)) < 2.5:
			return false
	if position.x < -8.0 and position.z > 0 and position.z < 12:
		return false
	if position.x > 7.0 and position.z > 7 and position.z < 14:
		return false
	return true


func update_guidance(player_position: Vector3, target_id: String) -> void:
	guide.visible = false
	for destination in interactables:
		var marker: Node3D = destination["node"]
		var is_target: bool = destination["id"] == target_id
		var tag := marker.get_child(0) as Label3D
		tag.visible = is_target or marker.position.distance_to(player_position) < 12.0
		tag.modulate = Color("f7d797") if is_target else CREAM
		if destination["id"] == "trader" and not trader_visual.visible:
			tag.visible = false
		if is_target:
			guide.visible = true
			guide.position = marker.position + Vector3(0, 3.6, 0)


func _make_guidance() -> void:
	guide = Node3D.new()
	add_child(guide)
	var gem := _box(guide, Vector3.ZERO, Vector3(0.38, 0.38, 0.38), Color("efc884"))
	gem.rotation_degrees = Vector3(45, 0, 45)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("efc884")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gem.material_override = material


func _make_upgrades() -> void:
	collector_visual = Node3D.new()
	collector_visual.position = Vector3(-11, 0, 3)
	add_child(collector_visual)
	_cylinder(collector_visual, Vector3(0, 0.72, 0), 0.72, 1.44, TEAL)
	_cylinder(collector_visual, Vector3(0, 1.5, 0), 0.85, 0.13, INK)
	var funnel := _box(collector_visual, Vector3(0, 2.05, 0), Vector3(2.3, 0.12, 1.7), Color("8caaa1"))
	funnel.rotation.z = 0.13
	_box(collector_visual, Vector3(-0.9, 1, 0), Vector3(0.12, 2, 0.12), INK)
	_box(collector_visual, Vector3(0.9, 1, 0), Vector3(0.12, 2, 0.12), INK)
	garden_visual = Node3D.new()
	garden_visual.position = Vector3(-11, 0, 9)
	add_child(garden_visual)
	for z in [-1.1, 1.1]:
		_box(garden_visual, Vector3(0, 0.15, z), Vector3(3.6, 0.3, 1.5), Color("907459"))
		_box(garden_visual, Vector3(0, 0.31, z), Vector3(3.35, 0.03, 1.25), Color("4b4c35"))
		for x in [-1.2, -0.4, 0.4, 1.2]:
			var plant := _cylinder(garden_visual, Vector3(x, 0.52, z), 0.24, 0.4, Color("739b65"))
			plant.mesh.top_radius = 0.05
	market_visual = Node3D.new()
	market_visual.position = Vector3(10, 0, 10)
	add_child(market_visual)
	_box(market_visual, Vector3(0, 0.8, 0), Vector3(3.6, 0.16, 1.3), Color("a48961"))
	for x in [-1.6, 1.6]:
		_box(market_visual, Vector3(x, 1.4, 0), Vector3(0.12, 2.8, 0.12), INK)
	_box(market_visual, Vector3(0, 2.8, 0), Vector3(4.1, 0.14, 2.0), CORAL)
	for x in [-0.9, 0.4]:
		_box(market_visual, Vector3(x, 1.08, 0), Vector3(0.8, 0.42, 0.7), Color("748771"))
	trader_visual = Node3D.new()
	trader_visual.position = Vector3(10, 0, 11.3)
	add_child(trader_visual)
	_box(trader_visual, Vector3(0, 1.08, 0), Vector3(0.7, 0.83, 0.4), Color("778daf"))
	_box(trader_visual, Vector3(0, 1.7, 0), Vector3(0.46, 0.46, 0.46), Color("c89f78"))
	_box(trader_visual, Vector3(0, 1.97, 0), Vector3(0.7, 0.13, 0.65), INK)
	for x in [-0.2, 0.2]:
		_box(trader_visual, Vector3(x, 0.4, 0), Vector3(0.25, 0.8, 0.27), INK)
	_add_interactable("trader", "trader", "Marchand de la route", Vector3(10, 0, 13))
	collector_visual.hide()
	garden_visual.hide()
	market_visual.hide()
	trader_visual.hide()


func _make_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 786
	for i in range(50):
		var x := rng.randf_range(-41, 41)
		var z := rng.randf_range(-40, 40)
		if absf(x) < 25 and absf(z) < 27:
			continue
		var rock := _cylinder(self, Vector3(x, 0.12, z), rng.randf_range(0.3, 0.9), 0.5, Color("8c9986"))
		rock.rotation.z = rng.randf_range(-0.25, 0.25)
	for p in [Vector3(-47, 2, -38), Vector3(-24, 3, -49), Vector3(4, 2, -51), Vector3(31, 3, -47), Vector3(48, 2, -26)]:
		var hill := _cylinder(self, p, 15, 9, Color("68755e"))
		hill.mesh.top_radius = 2
		hill.mesh.radial_segments = 6
	_make_car(Vector3(25, 0, 20), Color("a08c70"), 0.1)
	_make_car(Vector3(-27, 0, 19), Color("536c73"), -0.15)
	ruins_visual = Node3D.new()
	add_child(ruins_visual)
	for x in [-4, 4]:
		var plank := _box(ruins_visual, Vector3(x, 1.9, -3.7), Vector3(3, 0.25, 0.14), Color("84765d"))
		plank.rotation.z = 0.25
	for p in [Vector3(-7.5, 0.12, 0), Vector3(1.5, 0.1, -1.6), Vector3(8.5, 0.15, 6.8)]:
		var scrap := _box(ruins_visual, p, Vector3(1.1, 0.2, 0.6), Color("7d7e67"))
		scrap.rotation.y = rng.randf_range(-1, 1)
	rain_node = Node3D.new()
	add_child(rain_node)
	for i in range(80):
		var drop := _box(rain_node, Vector3(rng.randf_range(-25, 25), rng.randf_range(0, 13), rng.randf_range(-25, 25)), Vector3(0.02, 0.4, 0.02), Color("bbcfd0"))
		drop.rotation.z = 0.12
		rain_drops.append(drop)
	rain_node.hide()


func _make_car(position: Vector3, color: Color, angle: float) -> void:
	var car := Node3D.new()
	car.position = position
	car.rotation.y = angle
	add_child(car)
	_box(car, Vector3(0, 0.65, 0), Vector3(4.2, 0.75, 1.8), color, true)
	_box(car, Vector3(-0.2, 1.27, 0), Vector3(2.2, 0.65, 1.65), Color("5a7577"))
	_box(car, Vector3(-0.25, 1.66, 0), Vector3(2.4, 0.16, 1.8), color)
	for x in [-1.4, 1.4]:
		for z in [-0.95, 0.95]:
			var wheel := _cylinder(car, Vector3(x, 0.4, z), 0.43, 0.22, INK)
			wheel.rotation.x = PI / 2
	for z in [-0.55, 0.55]:
		_box(car, Vector3(2.12, 0.77, z), Vector3(0.04, 0.22, 0.35), CREAM)


func _cylinder(parent: Node3D, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _building_shell(parent: Node3D, center: Vector3, width: float, depth: float, height: float, doorway: float, color: Color) -> void:
	_box(parent, center + Vector3(0, height / 2, -depth / 2), Vector3(width, height, 0.3), color, true)
	for side in [-1, 1]:
		_box(parent, center + Vector3(side * width / 2, height / 2, 0), Vector3(0.3, height, depth), color, true)
		var segment := (width - doorway) / 2
		_box(parent, center + Vector3(side * (doorway / 2 + segment / 2), height / 2, depth / 2), Vector3(segment, height, 0.3), color, true)
	_box(parent, center + Vector3(0, height - 0.2, depth / 2), Vector3(doorway, 0.4, 0.3), color, true)


func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color, collision := false) -> MeshInstance3D:
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	var instance := MeshInstance3D.new()
	instance.mesh = box_mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	if collision:
		var body := StaticBody3D.new()
		body.position = position
		parent.add_child(body)
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
	return instance


func _label(parent: Node3D, value: String, position: Vector3, size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = position
	label.font_size = size
	label.pixel_size = 0.009
	label.modulate = color
	label.outline_size = 6
	parent.add_child(label)
	return label
