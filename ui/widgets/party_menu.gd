extends Control
## Pause menu with party management, gauntlet view, and game options.

signal closed()

var panel: PanelContainer
var party_list: VBoxContainer
var gauntlet_display: HBoxContainer
var stats_panel: VBoxContainer
var close_btn: Button
var save_btn: Button
var selected_dragon_index: int = -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("menu"):
		hide_menu()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	visible = true
	_refresh_party_list()
	_refresh_gauntlet()
	if close_btn:
		close_btn.grab_focus()

func hide_menu() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	# Dim background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	add_child(bg)

	# Main container
	var main_hbox := HBoxContainer.new()
	main_hbox.set_anchors_preset(Control.PRESET_CENTER)
	main_hbox.position = Vector2(-600, -350)
	main_hbox.size = Vector2(1200, 700)
	main_hbox.add_theme_constant_override("separation", 16)
	add_child(main_hbox)

	# Left panel: Party list
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(400, 700)
	left_panel.add_theme_stylebox_override("panel", _make_style(Color(0.06, 0.04, 0.12, 0.95)))

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)

	var party_title := Label.new()
	party_title.text = "PARTY"
	party_title.add_theme_font_size_override("font_size", 24)
	party_title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	party_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(party_title)

	party_list = VBoxContainer.new()
	party_list.add_theme_constant_override("separation", 4)
	left_vbox.add_child(party_list)

	left_panel.add_child(left_vbox)
	main_hbox.add_child(left_panel)

	# Right panel: Stats + Gauntlet
	var right_vbox := VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(500, 700)
	right_vbox.add_theme_constant_override("separation", 12)

	# Stats panel
	var stats_container := PanelContainer.new()
	stats_container.custom_minimum_size = Vector2(500, 350)
	stats_container.add_theme_stylebox_override("panel", _make_style(Color(0.06, 0.04, 0.12, 0.95)))
	stats_panel = VBoxContainer.new()
	stats_panel.add_theme_constant_override("separation", 6)
	var stats_title := Label.new()
	stats_title.text = "Select a dragon to view stats"
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_title.add_theme_color_override("font_color", Color(0.5, 0.48, 0.6))
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(stats_title)
	stats_container.add_child(stats_panel)
	right_vbox.add_child(stats_container)

	# Gauntlet display
	var gauntlet_panel := PanelContainer.new()
	gauntlet_panel.custom_minimum_size = Vector2(500, 120)
	gauntlet_panel.add_theme_stylebox_override("panel", _make_style(Color(0.08, 0.05, 0.14, 0.95)))

	var gauntlet_vbox := VBoxContainer.new()
	gauntlet_vbox.add_theme_constant_override("separation", 6)
	var gauntlet_title := Label.new()
	gauntlet_title.text = "DRAGON GAUNTLET"
	gauntlet_title.add_theme_font_size_override("font_size", 18)
	gauntlet_title.add_theme_color_override("font_color", Color(0.8, 0.65, 0.4))
	gauntlet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gauntlet_vbox.add_child(gauntlet_title)

	gauntlet_display = HBoxContainer.new()
	gauntlet_display.alignment = BoxContainer.ALIGNMENT_CENTER
	gauntlet_display.add_theme_constant_override("separation", 16)
	gauntlet_vbox.add_child(gauntlet_display)

	gauntlet_panel.add_child(gauntlet_vbox)
	right_vbox.add_child(gauntlet_panel)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)

	save_btn = Button.new()
	save_btn.text = "Save Game"
	save_btn.custom_minimum_size = Vector2(180, 40)
	save_btn.pressed.connect(_on_save)
	btn_row.add_child(save_btn)

	close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(180, 40)
	close_btn.pressed.connect(hide_menu)
	btn_row.add_child(close_btn)

	right_vbox.add_child(btn_row)
	main_hbox.add_child(right_vbox)

	# Collection bonus label
	var bonus_label := Label.new()
	bonus_label.name = "BonusLabel"
	bonus_label.add_theme_font_size_override("font_size", 14)
	bonus_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(bonus_label)

func _refresh_party_list() -> void:
	for child in party_list.get_children():
		child.queue_free()

	for i in PartyManager.party.size():
		var dragon = PartyManager.party[i]
		var btn := Button.new()
		var active_marker := ">> " if i == PartyManager.active_dragon_index else "   "
		var hp_ratio := float(dragon.current_hp) / max(float(dragon.get_max_hp()), 1.0)
		btn.text = "%s%s  Lv.%d  HP:%d/%d" % [active_marker, dragon.nickname, dragon.level, dragon.current_hp, dragon.get_max_hp()]
		btn.custom_minimum_size = Vector2(380, 40)
		btn.pressed.connect(_on_dragon_selected.bind(i))

		if hp_ratio <= 0:
			btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		elif hp_ratio < 0.25:
			btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		elif hp_ratio < 0.5:
			btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))

		party_list.add_child(btn)

	# Update collection bonus
	var bonus_label = get_node_or_null("BonusLabel")
	if bonus_label == null:
		# Find it in tree
		for child in get_children():
			var found = child.find_child("BonusLabel", true, false)
			if found:
				bonus_label = found
				break
	if bonus_label:
		var bonus := PartyManager.get_collection_bonus() * 100.0
		bonus_label.text = "Collection Bonus: +%.0f%% all stats (%d species)" % [bonus, PartyManager.collection.size()]

func _refresh_gauntlet() -> void:
	for child in gauntlet_display.get_children():
		child.queue_free()

	for i in PartyManager.MAX_GEM_SLOTS:
		var gem = PartyManager.soul_gems[i]
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(70, 70)

		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 35
		style.corner_radius_top_right = 35
		style.corner_radius_bottom_left = 35
		style.corner_radius_bottom_right = 35
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2

		if gem != null:
			if gem.is_occupied:
				var elem_color := TypeChart.get_element_color(gem.bound_dragon_element)
				style.bg_color = Color(elem_color, 0.4)
				style.border_color = elem_color
			else:
				style.bg_color = Color(gem.color, 0.3)
				style.border_color = gem.color
		else:
			style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
			style.border_color = Color(0.25, 0.22, 0.3, 0.4)

		slot.add_theme_stylebox_override("panel", style)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if gem != null:
			if gem.is_occupied:
				label.text = gem.bound_dragon_id.substr(0, 3).to_upper()
			else:
				label.text = "T%d" % gem.tier
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		else:
			label.text = "---"
			label.add_theme_font_size_override("font_size", 10)
			label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))

		slot.add_child(label)
		gauntlet_display.add_child(slot)

func _on_dragon_selected(index: int) -> void:
	selected_dragon_index = index
	_show_dragon_stats(index)

func _show_dragon_stats(index: int) -> void:
	for child in stats_panel.get_children():
		child.queue_free()

	var dragon = PartyManager.party[index]
	var data = dragon.base_data

	var name_label := Label.new()
	name_label.text = dragon.nickname
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", data.color_primary if data else Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(name_label)

	var elem_label := Label.new()
	elem_label.text = "[%s] Lv.%d" % [(data.element if data else "???").to_upper(), dragon.level]
	elem_label.add_theme_font_size_override("font_size", 16)
	elem_label.add_theme_color_override("font_color", TypeChart.get_element_color(data.element) if data else Color.WHITE)
	elem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(elem_label)

	var stat_names := ["HP", "MP", "ATK", "DEF", "AGI"]
	var stat_keys := ["hp", "mp", "atk", "def", "agi"]
	for i in stat_names.size():
		var val: int = dragon.get_stat(stat_keys[i])
		var label := Label.new()
		label.text = "%s: %d" % [stat_names[i], val]
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.85))
		stats_panel.add_child(label)

	var xp_label := Label.new()
	xp_label.text = "XP: %d / %d" % [dragon.xp, dragon.get_xp_to_next_level()]
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
	stats_panel.add_child(xp_label)

	# Set active button
	if index != PartyManager.active_dragon_index and dragon.current_hp > 0:
		var set_active_btn := Button.new()
		set_active_btn.text = "Set as Active"
		set_active_btn.custom_minimum_size = Vector2(200, 36)
		set_active_btn.pressed.connect(func():
			PartyManager.set_active_dragon(index)
			_refresh_party_list()
			_show_dragon_stats(index)
		)
		stats_panel.add_child(set_active_btn)

	# Abilities list
	if data and data.abilities.size() > 0:
		var ab_title := Label.new()
		ab_title.text = "Abilities:"
		ab_title.add_theme_font_size_override("font_size", 16)
		ab_title.add_theme_color_override("font_color", Color(0.6, 0.55, 0.75))
		stats_panel.add_child(ab_title)
		for ability in data.abilities:
			if ability == null:
				continue
			var ab_label := Label.new()
			ab_label.text = "  %s (%s, Pow:%d, MP:%d)" % [ability.ability_name, ability.element.to_upper(), ability.power, ability.mp_cost]
			ab_label.add_theme_font_size_override("font_size", 14)
			ab_label.add_theme_color_override("font_color", TypeChart.get_element_color(ability.element))
			stats_panel.add_child(ab_label)

func _on_save() -> void:
	var save_data := {
		"party": PartyManager.get_save_data(),
		"game_state": "overworld",
	}
	var file := FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[PartyMenu] Game saved!")
		save_btn.text = "Saved!"
		await get_tree().create_timer(1.0).timeout
		save_btn.text = "Save Game"

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
