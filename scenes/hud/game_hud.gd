extends CanvasLayer
## In-game HUD showing party info and prompts. Manages pause menu.

var party_display: VBoxContainer
var interaction_label: Label
var party_menu: Control
var zone_toast: Label
var dialog_box: Control
var _zone_toast_tween: Tween

func _ready() -> void:
	_build_ui()
	EventBus.party_changed.connect(_update_party_display)
	EventBus.battle_started.connect(func(): visible = false)
	EventBus.battle_ended.connect(func(_r):
		visible = true
		_update_party_display()
	)
	EventBus.player_entered_area.connect(_show_zone_toast)
	EventBus.npc_in_range.connect(_on_npc_in_range)
	EventBus.dialog_started.connect(_on_dialog_started)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and GameManager.is_gameplay_active():
		if party_menu and not party_menu.visible:
			party_menu.show_menu()
			GameManager.change_state(GameManager.GameState.PAUSED)
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	# Mini party display (top-right)
	party_display = VBoxContainer.new()
	party_display.name = "PartyDisplay"
	party_display.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	party_display.position = Vector2(-220, 8)
	party_display.size = Vector2(200, 200)
	add_child(party_display)

	# Interaction prompt (bottom-center)
	interaction_label = Label.new()
	interaction_label.name = "InteractionLabel"
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_label.position = Vector2(-100, -40)
	interaction_label.add_theme_font_size_override("font_size", 16)
	interaction_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	interaction_label.text = ""
	add_child(interaction_label)

	# Zone name toast (top-center)
	zone_toast = Label.new()
	zone_toast.name = "ZoneToast"
	zone_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	zone_toast.position = Vector2(-200, 30)
	zone_toast.size = Vector2(400, 40)
	zone_toast.add_theme_font_size_override("font_size", 28)
	zone_toast.add_theme_color_override("font_color", Color(1, 1, 0.9, 0))
	zone_toast.text = ""
	add_child(zone_toast)

	# Dialog box
	var DialogBoxScript = load("res://ui/widgets/dialog_box.gd")
	dialog_box = Control.new()
	dialog_box.set_script(DialogBoxScript)
	add_child(dialog_box)

	# Party menu (pause screen)
	var PartyMenuScript = load("res://ui/widgets/party_menu.gd")
	party_menu = Control.new()
	party_menu.set_script(PartyMenuScript)
	party_menu.closed.connect(func():
		GameManager.change_state(GameManager.GameState.OVERWORLD)
	)
	add_child(party_menu)

	_update_party_display()

func _update_party_display() -> void:
	for child in party_display.get_children():
		child.queue_free()

	for i in PartyManager.party.size():
		var dragon = PartyManager.party[i]
		var label := Label.new()
		var active_mark := "> " if i == PartyManager.active_dragon_index else "  "
		var hp_text := "%d/%d" % [dragon.current_hp, dragon.get_max_hp()]
		label.text = "%s%s Lv%d  HP:%s" % [active_mark, dragon.nickname, dragon.level, hp_text]
		label.add_theme_font_size_override("font_size", 14)

		var hp_ratio := float(dragon.current_hp) / max(float(dragon.get_max_hp()), 1.0)
		if hp_ratio > 0.5:
			label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
		elif hp_ratio > 0.25:
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		else:
			label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

		party_display.add_child(label)

func _show_zone_toast(area_name: String) -> void:
	if _zone_toast_tween:
		_zone_toast_tween.kill()
	zone_toast.text = area_name
	zone_toast.add_theme_color_override("font_color", Color(1, 1, 0.9, 0))

	_zone_toast_tween = create_tween()
	# Fade in
	_zone_toast_tween.tween_property(zone_toast, "theme_override_colors/font_color:a", 1.0, 0.5)
	# Hold
	_zone_toast_tween.tween_interval(2.0)
	# Fade out
	_zone_toast_tween.tween_property(zone_toast, "theme_override_colors/font_color:a", 0.0, 1.0)

func _on_npc_in_range(npc_node: Node3D, in_range: bool) -> void:
	if in_range and npc_node.has_method("get_display_name"):
		interaction_label.text = "[E] Talk to %s" % npc_node.get_display_name()
	else:
		interaction_label.text = ""

func _on_dialog_started(speaker: String, lines: PackedStringArray) -> void:
	interaction_label.text = ""
	if dialog_box and dialog_box.has_method("start_dialog"):
		dialog_box.start_dialog(speaker, lines)
