extends CanvasLayer

signal action(command: String, value: String)

const INK := Color("142c30")
const PAPER := Color("f2eedb")
const TEAL := Color("9bd4bb")
const GOLD := Color("efc884")

var root_ui: Control
var play_ui: Control
var overlay: Control
var status: Label
var objective: Label
var goal_hint: Label
var route: Label
var prompt: Label
var journal: Label
var supplies: Label
var session_label: Label
var theme_resource: Theme
var modal_open := false
var current_screen := "menu"


func _ready() -> void:
	theme_resource = Theme.new()
	theme_resource.default_font_size = 17
	theme_resource.set_color("font_color", "Label", PAPER)
	theme_resource.set_color("font_color", "Button", PAPER)
	theme_resource.set_color("font_disabled_color", "Button", Color("889c93"))
	theme_resource.set_stylebox("normal", "Button", _style(Color("29484b"), 9))
	theme_resource.set_stylebox("hover", "Button", _style(Color("426760"), 9))
	theme_resource.set_stylebox("pressed", "Button", _style(Color("537b6a"), 9))
	theme_resource.set_stylebox("disabled", "Button", _style(Color("233b3e"), 9))
	theme_resource.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, 9, GOLD))
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.theme = theme_resource
	add_child(root_ui)
	play_ui = Control.new()
	play_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(play_ui)
	var top := _panel_at(play_ui, Vector2(24, 22), Vector2(420, 116))
	session_label = _label(top, "LAST OUTPOST", 18)
	session_label.modulate = TEAL
	status = _label(top, "", 0)
	supplies = _label(top, "", 0)
	var goal := _panel_at(play_ui, Vector2(-366, 22), Vector2(342, 182), true)
	var heading := _label(goal, "VOTRE PROCHAINE ÉTAPE", 13)
	heading.modulate = GOLD
	objective = _label(goal, "", 20)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_hint = _label(goal, "", 0)
	goal_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route = _label(goal, "", 0)
	route.modulate = TEAL
	_button(goal, "M  Carte et destinations", "map")
	var bottom := _panel_at(play_ui, Vector2(-390, -151), Vector2(780, 62), false, true, true)
	prompt = _label(bottom, "", 18)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var toast := _panel_at(play_ui, Vector2(24, -235), Vector2(480, 75), false, true)
	journal = _label(toast, "", 0)
	journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	play_ui.add_child(bar)
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -540
	bar.offset_right = 540
	bar.offset_top = -68
	bar.offset_bottom = -24
	for item in [["Tab  Sac", "inventory"], ["B  Construire", "build"], ["N  Préparer la nuit", "rest"], ["H  Aide", "help"], ["Échap  Pause", "pause"]]:
		var b := _button(bar, item[0], item[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(overlay)


func large_text(enabled: bool) -> void:
	theme_resource.default_font_size = 20 if enabled else 17


func update_display(day_text: String, vitals: String, stock: String, goal: String, destination: String, interaction: String, message: String) -> void:
	session_label.text = day_text
	status.text = vitals
	supplies.text = stock
	objective.text = goal
	route.text = destination
	prompt.text = interaction
	journal.text = message


func show_game() -> void:
	_clear_overlay()
	modal_open = false
	current_screen = "game"
	play_ui.show()
	overlay.hide()


func show_menu(has_save: bool, paused := false) -> void:
	_clear_overlay()
	play_ui.hide()
	overlay.show()
	modal_open = true
	current_screen = "pause" if paused else "menu"
	var tint := ColorRect.new()
	tint.color = Color(0.025, 0.075, 0.075, 0.32)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(tint)
	var column := _panel_at(overlay, Vector2(70, 90), Vector2(500, 700))
	_label(column, "UN REFUGE SUR LA ROUTE", 14).modulate = GOLD
	_label(column, "LAST\nOUTPOST", 66)
	var pitch := _label(column, "Fouillez les environs. Rallumez la station.\nFaites-en un lieu où l'on revient.", 20)
	pitch.modulate = TEAL
	_space(column, 18)
	if paused:
		_button(column, "Reprendre", "close").grab_focus()
		_button(column, "Sauvegarder ma partie", "save")
		_button(column, "Charger la sauvegarde", "load", "", not has_save)
	else:
		var resume := _button(column, "Continuer ma partie", "continue", "", not has_save)
		var fresh := _button(column, "Nouvelle partie · Découverte", "new", "relaxed")
		if has_save:
			resume.grab_focus()
		else:
			fresh.grab_focus()
		_button(column, "Nouvelle partie · Survie", "new", "standard")
		_label(column, "Découverte : besoins plus doux, aucune attaque.\nSurvie : prévoyez les réserves et la défense.", 14)
	_button(column, "Réglages et confort", "settings")
	_button(column, "Comment jouer", "help")
	if paused:
		_button(column, "Accueil", "menu")
	elif not OS.has_feature("web"):
		_button(column, "Quitter", "quit")


func show_sheet(title: String, description: String, choices: Array, screen := "sheet") -> VBoxContainer:
	_clear_overlay()
	overlay.show()
	modal_open = true
	current_screen = screen
	var tint := ColorRect.new()
	tint.color = Color(0.015, 0.045, 0.05, 0.72)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(tint)
	var column := _panel_at(overlay, Vector2(-470, -340), Vector2(940, 680), false, false, true, true)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title_label := _label(header, title, 29)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "Fermer · Échap", "close").grab_focus()
	var intro := _label(column, description, 0)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = TEAL
	_space(column, 8)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 8)
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(contents)
	for choice in choices:
		var button := _button(contents, str(choice.get("label", "")), str(choice.get("command", "")), str(choice.get("value", "")), bool(choice.get("disabled", false)))
		button.tooltip_text = str(choice.get("tooltip", ""))
	return contents


func _clear_overlay() -> void:
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()


func _panel_at(parent: Control, offset: Vector2, panel_size: Vector2, right := false, bottom := false, center_x := false, center_y := false) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	panel.anchor_left = 0.5 if center_x else (1.0 if right else 0.0)
	panel.anchor_right = panel.anchor_left
	panel.anchor_top = 0.5 if center_y else (1.0 if bottom else 0.0)
	panel.anchor_bottom = panel.anchor_top
	panel.offset_left = offset.x
	panel.offset_top = offset.y
	panel.offset_right = offset.x + panel_size.x
	panel.offset_bottom = offset.y + panel_size.y
	panel.add_theme_stylebox_override("panel", _style(Color("142c30ed"), 14))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	return column


func _label(parent: Node, value: String, size := 0) -> Label:
	var label := Label.new()
	label.text = value
	if size > 0:
		label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _button(parent: Node, value: String, command: String, payload := "", disabled := false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.disabled = disabled
	button.pressed.connect(func(): action.emit(command, payload))
	parent.add_child(button)
	return button


func _space(parent: Node, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)


func _style(color: Color, radius: int, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if border.a > 0:
		style.border_color = border
		style.set_border_width_all(2)
	return style
