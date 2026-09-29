extends Control

signal destination_selected(id: String)

var destinations: Array[Dictionary] = []
var player_position := Vector3.ZERO
var selected := ""


func _ready() -> void:
	custom_minimum_size = Vector2(700, 390)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _map(position: Vector3) -> Vector2:
	return Vector2(size.x * 0.5 + position.x * 6.8, size.y * 0.5 + position.z * 4.3)


func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	for x in range(-40, 41, 10):
		draw_line(_map(Vector3(x, 0, -40)), _map(Vector3(x, 0, 40)), Color("335054"), 1)
	for z in range(-40, 41, 10):
		draw_line(_map(Vector3(-40, 0, z)), _map(Vector3(40, 0, z)), Color("335054"), 1)
	draw_line(_map(Vector3(-40, 0, 20)), _map(Vector3(40, 0, 20)), Color("798b80"), 20)
	draw_rect(Rect2(_map(Vector3(-7, 0, -12)), Vector2(145, 90)), Color("567d6d"))
	for place in destinations:
		var point := _map(place["position"])
		var chosen: bool = place["id"] == selected
		draw_circle(point, 9 if chosen else 6, Color("efc884") if chosen else Color("aad8c2"))
		draw_string(ThemeDB.fallback_font, point + Vector2(12, 5), place["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2eedb"))
	var player_point := _map(player_position)
	draw_circle(player_point, 7, Color.WHITE)
	draw_arc(player_point, 11, 0, TAU, 24, Color.WHITE, 2)
	draw_string(ThemeDB.fallback_font, Vector2(22, 28), "NORD ↑     ·     Point blanc : vous", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2eedb"))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var nearest := 26.0
		var target := ""
		for place in destinations:
			var distance := _map(place["position"]).distance_to(event.position)
			if distance < nearest:
				nearest = distance
				target = place["id"]
		if not target.is_empty():
			destination_selected.emit(target)


func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("203c40")
	style.set_corner_radius_all(10)
	return style
