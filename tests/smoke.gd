extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var first_forecast: Dictionary = game._night_forecast()
	if first_forecast["wood_needed"] != 2 or first_forecast["protected"] != 2 or first_forecast["exposed"] != 1:
		_fail("The opening night forecast is inconsistent")
		return

	var first_tree: Dictionary = {}
	for prop in game.props:
		if prop["kind"] == "tree":
			first_tree = prop
			break
	if first_tree.is_empty():
		_fail("No tree was created")
		return

	var initial_wood: int = game.wood
	var tree_node: Node3D = first_tree["node"]
	var click: Vector2 = game.camera.unproject_position(tree_node.global_position + Vector3.UP * 1.35)
	game._click_world(click)
	game._move_survivors(100.0)
	if game.wood != initial_wood + 3:
		_fail("Clicking a tree did not collect wood")
		return
	var first_bush: Dictionary = {}
	for prop in game.props:
		if prop["kind"] == "berry":
			first_bush = prop
			break
	game._set_mode("food")
	var initial_food: int = game.food
	var bush_node: Node3D = first_bush["node"]
	game._click_world(game.camera.unproject_position(bush_node.global_position + Vector3.UP * 0.35))
	game._move_survivors(100.0)
	if game.food != initial_food + 3:
		_fail("Clicking a bush did not collect food")
		return

	var build_cell := Vector2i(2, 0)
	if game._occupied(build_cell):
		_fail("The nearby shelter cell should be available")
		return
	game._queue_build(build_cell)
	game._move_survivors(100.0)
	if game.shelters.size() != 2 or game.wood != initial_wood - 2:
		_fail("Building did not spend wood and add a shelter")
		return
	if game._night_forecast()["protected"] != 3:
		_fail("The nearby shelter should protect all survivors in calm weather")
		return

	game.food = 0
	game._end_day()
	if game.cohesion != 34 or game.wood != 0 or game.day != 2:
		_fail("The first night did not apply the predicted food and fire costs")
		return
	game.wood = 4
	game.food = 3
	if game._night_forecast()["exposed"] != 1:
		_fail("Wind should leave the distant shelter unheated on embers")
		return
	game.fire_button.pressed.emit()
	if game._night_forecast()["exposed"] != 0 or game._night_forecast()["wood_needed"] != 4:
		_fail("A stronger fire should protect everyone at a higher wood cost")
		return
	game._end_day()
	if game.wood != 0 or game.cohesion != 38 or game.day != 3:
		_fail("The stronger fire did not produce the forecast night outcome")
		return
	if game._night_forecast()["exposed"] != 3:
		_fail("No wood should leave every survivor exposed")
		return
	game.wood = 12
	game.food = 9
	for i in range(3):
		game.night_button.pressed.emit()
	if not game.finished or game.cohesion != 50 or game.day != 5:
		_fail("A well supplied camp did not survive five nights")
		return
	print("PLAYTEST OK: harvest, shelter, forecast, weather, fire, shortage, victory")
	game.queue_free()
	await process_frame
	quit()


func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
