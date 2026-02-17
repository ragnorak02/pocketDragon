extends CanvasLayer
## Debug overlay showing engine info and FPS. Toggle with F3.

var label: Label
var visible_overlay := true

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	var panel := PanelContainer.new()
	panel.name = "DebugPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(8, 8)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	label = Label.new()
	label.name = "DebugLabel"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	panel.add_child(label)
	add_child(panel)

func _process(_delta: float) -> void:
	if not visible_overlay:
		return
	var fps := Engine.get_frames_per_second()
	var renderer: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")
	var engine_ver: Dictionary = Engine.get_version_info()
	var ver_str: String = "%s.%s.%s" % [engine_ver["major"], engine_ver["minor"], engine_ver["patch"]]
	var state_name: String = GameManager.GameState.keys()[GameManager.current_state]
	var battle_state: String = BattleManager.BattleState.keys()[BattleManager.state] if BattleManager.state != BattleManager.BattleState.INACTIVE else "---"
	var party_count := PartyManager.party.size()

	var zone_name := "---"
	var overworld := get_tree().get_first_node_in_group("overworld") if get_tree() else null
	if overworld == null:
		# Try finding by node path in scene tree
		var scene_container = get_tree().root.get_node_or_null("Main/SceneContainer")
		if scene_container and scene_container.get_child_count() > 0:
			var child = scene_container.get_child(0)
			if child.has_method("_load_zone") and child.get("current_zone"):
				overworld = child
	if overworld and overworld.get("current_zone") and overworld.current_zone:
		zone_name = overworld.current_zone.zone_name

	label.text = "Dragon League v0.1\n"
	label.text += "Godot %s | %s | %s\n" % [ver_str, renderer, OS.get_name()]
	label.text += "FPS: %d\n" % fps
	label.text += "State: %s\n" % state_name
	label.text += "Battle: %s\n" % battle_state
	label.text += "Party: %d/5\n" % party_count
	label.text += "Zone: %s" % zone_name

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible_overlay = not visible_overlay
		get_child(0).visible = visible_overlay
