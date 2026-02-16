extends Control
## Bestiary screen showing encountered and captured creatures.

signal closed()

# Tracking: dragon_id/enemy_id -> "encountered" or "captured"
static var dragon_entries: Dictionary = {}
static var enemy_entries: Dictionary = {}

var list_container: VBoxContainer
var detail_panel: VBoxContainer
var tab_dragons: Button
var tab_enemies: Button
var close_btn: Button
var current_tab := "dragons"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	EventBus.dragon_encountered.connect(func(id): _register_dragon(id, "encountered"))
	EventBus.dragon_captured.connect(func(id): _register_dragon(id, "captured"))
	EventBus.enemy_encountered.connect(func(id): _register_enemy(id))

	_build_ui()

static func _register_dragon(id: String, status: String) -> void:
	if not dragon_entries.has(id) or status == "captured":
		dragon_entries[id] = status

static func _register_enemy(id: String) -> void:
	if not enemy_entries.has(id):
		enemy_entries[id] = "encountered"

func show_bestiary() -> void:
	visible = true
	_refresh_list()

func hide_bestiary() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.08, 0.95)
	add_child(bg)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 60
	main_vbox.offset_top = 40
	main_vbox.offset_right = -60
	main_vbox.offset_bottom = -40
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = "BESTIARY"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.85, 0.65, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# Tabs
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	tab_dragons = Button.new()
	tab_dragons.text = "Dragons"
	tab_dragons.custom_minimum_size = Vector2(200, 40)
	tab_dragons.pressed.connect(func():
		current_tab = "dragons"
		_refresh_list()
	)
	tabs.add_child(tab_dragons)

	tab_enemies = Button.new()
	tab_enemies.text = "Monsters"
	tab_enemies.custom_minimum_size = Vector2(200, 40)
	tab_enemies.pressed.connect(func():
		current_tab = "enemies"
		_refresh_list()
	)
	tabs.add_child(tab_enemies)
	main_vbox.add_child(tabs)

	# Content
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)

	# List
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(400, 0)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list_style := _make_style(Color(0.06, 0.04, 0.1, 0.9))
	list_panel.add_theme_stylebox_override("panel", list_style)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 4)
	scroll.add_child(list_container)
	list_panel.add_child(scroll)
	hbox.add_child(list_panel)

	# Detail
	var detail_outer := PanelContainer.new()
	detail_outer.custom_minimum_size = Vector2(500, 0)
	detail_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_outer.add_theme_stylebox_override("panel", _make_style(Color(0.06, 0.04, 0.1, 0.9)))
	detail_panel = VBoxContainer.new()
	detail_panel.add_theme_constant_override("separation", 8)
	var placeholder := Label.new()
	placeholder.text = "Select an entry to view details."
	placeholder.add_theme_font_size_override("font_size", 16)
	placeholder.add_theme_color_override("font_color", Color(0.45, 0.42, 0.55))
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_panel.add_child(placeholder)
	detail_outer.add_child(detail_panel)
	hbox.add_child(detail_outer)
	main_vbox.add_child(hbox)

	# Close button
	close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(200, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(hide_bestiary)
	main_vbox.add_child(close_btn)

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	if current_tab == "dragons":
		var all_dragons := ["fire_drake", "storm_wyvern", "stone_wyrm"]
		for id in all_dragons:
			var status: String = dragon_entries.get(id, "unknown")
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(380, 36)
			if status == "unknown":
				btn.text = "???"
				btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
			elif status == "encountered":
				btn.text = "%s (Encountered)" % id.replace("_", " ").capitalize()
				btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.7))
			else:
				btn.text = "%s (Captured)" % id.replace("_", " ").capitalize()
				btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
			btn.pressed.connect(_show_dragon_detail.bind(id, status))
			list_container.add_child(btn)
	else:
		var all_enemies := ["slime", "goblin"]
		for id in all_enemies:
			var status: String = enemy_entries.get(id, "unknown")
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(380, 36)
			if status == "unknown":
				btn.text = "???"
				btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
			else:
				btn.text = id.replace("_", " ").capitalize()
				btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.8))
			btn.pressed.connect(_show_enemy_detail.bind(id, status))
			list_container.add_child(btn)

func _show_dragon_detail(id: String, status: String) -> void:
	for child in detail_panel.get_children():
		child.queue_free()

	if status == "unknown":
		var label := Label.new()
		label.text = "Not yet encountered."
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.4, 0.38, 0.5))
		detail_panel.add_child(label)
		return

	var path := "res://data/dragons/%s.tres" % id
	if not ResourceLoader.exists(path):
		return
	var data: DragonData = load(path)

	var name_label := Label.new()
	name_label.text = data.dragon_name
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", data.color_primary)
	detail_panel.add_child(name_label)

	var elem := Label.new()
	elem.text = "Element: %s" % data.element.to_upper()
	elem.add_theme_font_size_override("font_size", 16)
	elem.add_theme_color_override("font_color", TypeChart.get_element_color(data.element))
	detail_panel.add_child(elem)

	if status == "captured":
		var desc := Label.new()
		desc.text = data.description
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_panel.add_child(desc)

		var stats := Label.new()
		stats.text = "Base Stats: HP:%d ATK:%d DEF:%d AGI:%d" % [data.base_hp, data.base_atk, data.base_def, data.base_agi]
		stats.add_theme_font_size_override("font_size", 14)
		stats.add_theme_color_override("font_color", Color(0.65, 0.62, 0.75))
		detail_panel.add_child(stats)
	else:
		var hint := Label.new()
		hint.text = "Capture this dragon to reveal full details."
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6))
		detail_panel.add_child(hint)

func _show_enemy_detail(id: String, status: String) -> void:
	for child in detail_panel.get_children():
		child.queue_free()

	if status == "unknown":
		var label := Label.new()
		label.text = "Not yet encountered."
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.4, 0.38, 0.5))
		detail_panel.add_child(label)
		return

	var path := "res://data/enemies/%s.tres" % id
	if not ResourceLoader.exists(path):
		return
	var data: EnemyData = load(path)

	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", data.color_primary)
	detail_panel.add_child(name_label)

	var desc := Label.new()
	desc.text = data.description
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(desc)

	var stats := Label.new()
	stats.text = "HP:%d ATK:%d DEF:%d AGI:%d XP:%d" % [data.max_hp, data.attack, data.defense, data.agi, data.xp_reward]
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.65, 0.62, 0.75))
	detail_panel.add_child(stats)

func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.3, 0.5, 0.5)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style
