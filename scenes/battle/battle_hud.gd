extends CanvasLayer
## Battle HUD: HP bars, action menu, turn order, damage numbers, battle log.

# UI references (built in code)
var root_control: Control
var player_hp_bar: ProgressBar
var player_hp_label: Label
var player_mp_bar: ProgressBar
var player_mp_label: Label
var player_name_label: Label
var player_level_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_label: Label
var enemy_name_label: Label
var turn_order_label: Label
var action_menu: VBoxContainer
var ability_menu: VBoxContainer
var swap_menu: VBoxContainer
var battle_log: RichTextLabel
var state_label: Label
var damage_container: Control

# Action buttons
var btn_attack: Button
var btn_abilities: Button
var btn_capture: Button
var btn_swap: Button
var btn_flee: Button
var btn_back: Button
var btn_back_swap: Button

var _current_menu := "action"  # "action", "ability", "swap"

func _ready() -> void:
	_build_ui()
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.action_executed.connect(_on_action_executed)
	EventBus.capture_result.connect(_on_capture_result)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.level_up.connect(_on_level_up)

func initialize() -> void:
	_update_hp_bars()
	_update_turn_order()
	_show_action_menu()
	if battle_log:
		battle_log.clear()
		_log_message("Battle start!")

func update_state(new_state: StringName) -> void:
	if state_label:
		state_label.text = new_state
	match new_state:
		"AWAITING_INPUT":
			_show_action_menu()
			_update_hp_bars()
		"ENEMY_TURN":
			_hide_all_menus()
			_update_hp_bars()
		"EXECUTING_ACTION":
			_hide_all_menus()
		"VICTORY":
			_hide_all_menus()
			_show_result("VICTORY!", Color(1.0, 0.85, 0.2))
		"DEFEAT":
			_hide_all_menus()
			_show_result("DEFEAT", Color(0.8, 0.2, 0.2))
		"FLED":
			_hide_all_menus()
			_show_result("Escaped!", Color(0.6, 0.6, 0.8))
		_:
			_hide_all_menus()
	_update_hp_bars()

func show_damage_number(amount: int, is_enemy_target: bool) -> void:
	if not damage_container:
		return
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 32)

	if is_enemy_target:
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		label.position = Vector2(1200, 200)
	else:
		label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		label.position = Vector2(700, 200)

	damage_container.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 60, 0.8).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.tween_callback(label.queue_free)

func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	_build_player_info()
	_build_enemy_info()
	_build_action_menu()
	_build_ability_menu()
	_build_swap_menu()
	_build_battle_log()
	_build_turn_order()
	_build_damage_container()

func _build_player_info() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 700)
	panel.custom_minimum_size = Vector2(350, 140)
	var style := _make_panel_style(Color(0.05, 0.08, 0.15, 0.9))
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var hbox_name := HBoxContainer.new()
	player_name_label = Label.new()
	player_name_label.text = "Dragon"
	player_name_label.add_theme_font_size_override("font_size", 20)
	player_name_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	hbox_name.add_child(player_name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_name.add_child(spacer)

	player_level_label = Label.new()
	player_level_label.text = "Lv.5"
	player_level_label.add_theme_font_size_override("font_size", 16)
	player_level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	hbox_name.add_child(player_level_label)
	vbox.add_child(hbox_name)

	# HP bar
	var hp_label := Label.new()
	hp_label.text = "HP"
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	vbox.add_child(hp_label)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(300, 20)
	player_hp_bar.max_value = 100
	player_hp_bar.value = 100
	player_hp_bar.show_percentage = false
	_style_hp_bar(player_hp_bar, Color(0.2, 0.7, 0.3))
	vbox.add_child(player_hp_bar)

	player_hp_label = Label.new()
	player_hp_label.text = "100/100"
	player_hp_label.add_theme_font_size_override("font_size", 14)
	player_hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(player_hp_label)

	# MP bar
	player_mp_bar = ProgressBar.new()
	player_mp_bar.custom_minimum_size = Vector2(300, 12)
	player_mp_bar.max_value = 50
	player_mp_bar.value = 50
	player_mp_bar.show_percentage = false
	_style_hp_bar(player_mp_bar, Color(0.3, 0.4, 0.9))
	vbox.add_child(player_mp_bar)

	player_mp_label = Label.new()
	player_mp_label.text = "MP: 50/50"
	player_mp_label.add_theme_font_size_override("font_size", 12)
	player_mp_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.9))
	player_mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(player_mp_label)

	panel.add_child(vbox)
	root_control.add_child(panel)

func _build_enemy_info() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(1530, 40)
	panel.custom_minimum_size = Vector2(350, 100)
	var style := _make_panel_style(Color(0.15, 0.05, 0.08, 0.9))
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	enemy_name_label = Label.new()
	enemy_name_label.text = "Enemy"
	enemy_name_label.add_theme_font_size_override("font_size", 20)
	enemy_name_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	vbox.add_child(enemy_name_label)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(300, 20)
	enemy_hp_bar.max_value = 100
	enemy_hp_bar.value = 100
	enemy_hp_bar.show_percentage = false
	_style_hp_bar(enemy_hp_bar, Color(0.8, 0.2, 0.2))
	vbox.add_child(enemy_hp_bar)

	enemy_hp_label = Label.new()
	enemy_hp_label.text = "100/100"
	enemy_hp_label.add_theme_font_size_override("font_size", 14)
	enemy_hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(enemy_hp_label)

	panel.add_child(vbox)
	root_control.add_child(panel)

func _build_action_menu() -> void:
	var panel := PanelContainer.new()
	panel.name = "ActionPanel"
	panel.position = Vector2(700, 750)
	panel.custom_minimum_size = Vector2(520, 240)
	var style := _make_panel_style(Color(0.06, 0.05, 0.12, 0.95))
	panel.add_theme_stylebox_override("panel", style)

	action_menu = VBoxContainer.new()
	action_menu.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "COMMAND"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.5, 0.45, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_menu.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var col1 := VBoxContainer.new()
	col1.add_theme_constant_override("separation", 6)
	btn_attack = _make_menu_button("Attack", _on_attack)
	col1.add_child(btn_attack)
	btn_abilities = _make_menu_button("Abilities", _on_abilities_menu)
	col1.add_child(btn_abilities)
	btn_capture = _make_menu_button("Capture", _on_capture)
	col1.add_child(btn_capture)
	hbox.add_child(col1)

	var col2 := VBoxContainer.new()
	col2.add_theme_constant_override("separation", 6)
	btn_swap = _make_menu_button("Swap", _on_swap_menu)
	col2.add_child(btn_swap)
	btn_flee = _make_menu_button("Flee", _on_flee)
	col2.add_child(btn_flee)
	hbox.add_child(col2)

	action_menu.add_child(hbox)
	panel.add_child(action_menu)
	root_control.add_child(panel)

func _build_ability_menu() -> void:
	var panel := PanelContainer.new()
	panel.name = "AbilityPanel"
	panel.position = Vector2(700, 750)
	panel.custom_minimum_size = Vector2(520, 240)
	var style := _make_panel_style(Color(0.06, 0.05, 0.12, 0.95))
	panel.add_theme_stylebox_override("panel", style)
	panel.visible = false

	ability_menu = VBoxContainer.new()
	ability_menu.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "ABILITIES"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.5, 0.45, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_menu.add_child(title)

	btn_back = _make_menu_button("Back", _on_back_to_action)
	ability_menu.add_child(btn_back)

	panel.add_child(ability_menu)
	root_control.add_child(panel)

func _build_swap_menu() -> void:
	var panel := PanelContainer.new()
	panel.name = "SwapPanel"
	panel.position = Vector2(700, 750)
	panel.custom_minimum_size = Vector2(520, 240)
	var style := _make_panel_style(Color(0.06, 0.05, 0.12, 0.95))
	panel.add_theme_stylebox_override("panel", style)
	panel.visible = false

	swap_menu = VBoxContainer.new()
	swap_menu.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "SWAP DRAGON"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.5, 0.45, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	swap_menu.add_child(title)

	btn_back_swap = _make_menu_button("Back", _on_back_to_action)
	swap_menu.add_child(btn_back_swap)

	panel.add_child(swap_menu)
	root_control.add_child(panel)

func _build_battle_log() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 880)
	panel.custom_minimum_size = Vector2(600, 120)
	var style := _make_panel_style(Color(0.04, 0.03, 0.08, 0.85))
	panel.add_theme_stylebox_override("panel", style)

	battle_log = RichTextLabel.new()
	battle_log.bbcode_enabled = true
	battle_log.scroll_following = true
	battle_log.add_theme_font_size_override("normal_font_size", 14)
	battle_log.add_theme_color_override("default_color", Color(0.7, 0.68, 0.8))

	panel.add_child(battle_log)
	root_control.add_child(panel)

func _build_turn_order() -> void:
	turn_order_label = Label.new()
	turn_order_label.position = Vector2(860, 40)
	turn_order_label.add_theme_font_size_override("font_size", 16)
	turn_order_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85))
	turn_order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_control.add_child(turn_order_label)

	state_label = Label.new()
	state_label.position = Vector2(860, 65)
	state_label.add_theme_font_size_override("font_size", 12)
	state_label.add_theme_color_override("font_color", Color(0.45, 0.42, 0.55))
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_control.add_child(state_label)

func _build_damage_container() -> void:
	damage_container = Control.new()
	damage_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(damage_container)

func _update_hp_bars() -> void:
	var dragon = BattleManager.player_dragon
	if dragon:
		player_name_label.text = dragon.nickname
		player_level_label.text = "Lv.%d" % dragon.level
		player_hp_bar.max_value = dragon.get_max_hp()
		player_hp_bar.value = dragon.current_hp
		player_hp_label.text = "%d/%d" % [dragon.current_hp, dragon.get_max_hp()]
		player_mp_bar.max_value = dragon.get_max_mp()
		player_mp_bar.value = dragon.current_mp
		player_mp_label.text = "MP: %d/%d" % [dragon.current_mp, dragon.get_max_mp()]

	enemy_name_label.text = BattleManager._get_enemy_name()
	enemy_hp_bar.max_value = BattleManager.enemy_max_hp
	enemy_hp_bar.value = BattleManager.enemy_current_hp
	enemy_hp_label.text = "%d/%d" % [BattleManager.enemy_current_hp, BattleManager.enemy_max_hp]

	# Update capture button visibility
	if btn_capture:
		btn_capture.visible = BattleManager.is_wild_dragon
		btn_capture.disabled = PartyManager.get_best_available_gem()["gem"] == null or PartyManager.party.size() >= PartyManager.MAX_PARTY_SIZE

func _update_turn_order() -> void:
	if turn_order_label and BattleManager.turn_queue.size() > 0:
		var names: Array = BattleManager.turn_queue.map(func(t): return t["name"])
		turn_order_label.text = "Turn Order: " + " → ".join(names)

func _show_action_menu() -> void:
	_hide_all_menus()
	action_menu.get_parent().visible = true
	_update_hp_bars()
	btn_attack.grab_focus()

func _hide_all_menus() -> void:
	action_menu.get_parent().visible = false
	ability_menu.get_parent().visible = false
	swap_menu.get_parent().visible = false

func _show_result(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-200, -40)
	label.size = Vector2(400, 80)
	root_control.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3).from(Vector2(0.5, 0.5)).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

# Action handlers
func _on_attack() -> void:
	EventBus.action_selected.emit({"type": "attack", "ability": null})
	_log_message("%s attacks!" % BattleManager.player_dragon.nickname)

func _on_abilities_menu() -> void:
	_hide_all_menus()
	ability_menu.get_parent().visible = true
	_populate_abilities()

func _on_capture() -> void:
	EventBus.action_selected.emit({"type": "capture"})
	_log_message("Attempting capture...")
	_hide_all_menus()

func _on_swap_menu() -> void:
	_hide_all_menus()
	swap_menu.get_parent().visible = true
	_populate_swap_list()

func _on_flee() -> void:
	EventBus.action_selected.emit({"type": "flee"})
	_log_message("Attempting to flee...")
	_hide_all_menus()

func _on_back_to_action() -> void:
	_show_action_menu()

func _populate_abilities() -> void:
	# Remove old ability buttons (keep title and back button)
	var children := ability_menu.get_children()
	for i in range(children.size() - 1, 0, -1):
		if children[i] != btn_back and children[i] is Button:
			children[i].queue_free()

	var dragon = BattleManager.player_dragon
	if dragon == null or dragon.base_data == null:
		return

	var abilities: Array = dragon.base_data.abilities
	for i in abilities.size():
		var ability = abilities[i]
		if ability == null:
			continue
		var text := "%s (MP:%d, Pow:%d)" % [ability.ability_name, ability.mp_cost, ability.power]
		var btn := _make_menu_button(text, _on_ability_selected.bind(ability))
		btn.disabled = dragon.current_mp < ability.mp_cost
		# Insert before back button
		ability_menu.add_child(btn)
		ability_menu.move_child(btn, ability_menu.get_child_count() - 2)

func _populate_swap_list() -> void:
	var children := swap_menu.get_children()
	for i in range(children.size() - 1, 0, -1):
		if children[i] != btn_back_swap and children[i] is Button:
			children[i].queue_free()

	for i in PartyManager.party.size():
		var dragon = PartyManager.party[i]
		if i == PartyManager.active_dragon_index:
			continue
		if dragon.current_hp <= 0:
			continue
		var text := "%s Lv%d HP:%d/%d" % [dragon.nickname, dragon.level, dragon.current_hp, dragon.get_max_hp()]
		var btn := _make_menu_button(text, _on_swap_selected.bind(i))
		swap_menu.add_child(btn)
		swap_menu.move_child(btn, swap_menu.get_child_count() - 2)

func _on_ability_selected(ability) -> void:
	EventBus.action_selected.emit({"type": "ability", "ability": ability})
	_log_message("%s uses %s!" % [BattleManager.player_dragon.nickname, ability.ability_name])
	_hide_all_menus()

func _on_swap_selected(index: int) -> void:
	EventBus.action_selected.emit({"type": "swap", "dragon_index": index})
	_log_message("Swapping to %s!" % PartyManager.party[index].nickname)
	_hide_all_menus()

func _on_turn_started(combatant_name: String) -> void:
	_update_turn_order()
	_update_hp_bars()

func _on_action_executed(action: Dictionary, result: Dictionary) -> void:
	_update_hp_bars()
	if action.get("type") == "attack":
		var damage: int = result.get("damage", 0)
		var attacker: String = result.get("attacker", "???")
		var target: String = result.get("target", "???")
		var ability_name: String = result.get("ability", "Attack")
		var type_mult: float = result.get("type_mult", 1.0)
		_log_message("%s used %s on %s for [color=yellow]%d[/color] damage!" % [attacker, ability_name, target, damage])
		if type_mult >= 2.0:
			_log_message("[color=lime]Super effective![/color]")
		elif type_mult <= 0.5:
			_log_message("[color=gray]Not very effective...[/color]")
	elif action.get("type") == "swap":
		_log_message("Swapped to %s!" % result.get("swapped_to", "???"))
	elif action.get("type") == "flee":
		if not result.get("success", false):
			_log_message("[color=gray]Couldn't escape![/color]")

func _on_capture_result(success: bool, dragon_name: String) -> void:
	if success:
		_log_message("[color=gold]Captured %s![/color]" % dragon_name)
	else:
		_log_message("[color=red]%s broke free![/color]" % dragon_name)

func _on_battle_ended(result: StringName) -> void:
	match result:
		"victory":
			var xp := BattleManager.xp_reward
			_log_message("[color=gold]Victory! Gained %d XP![/color]" % xp)
		"defeat":
			_log_message("[color=red]Defeat...[/color]")
		"fled":
			_log_message("Got away safely!")

func _on_level_up(dragon_name: String, new_level: int) -> void:
	_log_message("[color=gold]%s leveled up to Lv.%d![/color]" % [dragon_name, new_level])

func _log_message(text: String) -> void:
	if battle_log:
		battle_log.append_text(text + "\n")

func _make_menu_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 36)
	btn.pressed.connect(callback)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.08, 0.18, 0.9)
	style_normal.border_width_left = 1
	style_normal.border_width_bottom = 1
	style_normal.border_color = Color(0.35, 0.3, 0.5, 0.6)
	style_normal.corner_radius_top_left = 2
	style_normal.corner_radius_top_right = 2
	style_normal.corner_radius_bottom_left = 2
	style_normal.corner_radius_bottom_right = 2
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12

	var style_hover := style_normal.duplicate()
	style_hover.bg_color = Color(0.15, 0.12, 0.25, 0.95)
	style_hover.border_color = Color(0.6, 0.5, 0.8, 0.9)

	var style_focus := style_normal.duplicate()
	style_focus.bg_color = Color(0.13, 0.1, 0.22, 0.95)
	style_focus.border_color = Color(0.7, 0.55, 0.9, 1.0)
	style_focus.border_width_left = 2
	style_focus.border_width_bottom = 2

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_focus)
	btn.add_theme_color_override("font_color", Color(0.8, 0.78, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 1))
	btn.add_theme_font_size_override("font_size", 18)

	return btn

func _style_hp_bar(bar: ProgressBar, color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	bg.corner_radius_top_left = 2
	bg.corner_radius_top_right = 2
	bg.corner_radius_bottom_left = 2
	bg.corner_radius_bottom_right = 2

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

func _make_panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.3, 0.5, 0.6)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style
