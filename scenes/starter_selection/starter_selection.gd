extends Control
## Starter dragon selection screen. Pick 1 of 3 dragons.

const STARTER_PATHS := [
	"res://data/dragons/fire_drake.tres",
	"res://data/dragons/storm_wyvern.tres",
	"res://data/dragons/stone_wyrm.tres",
]

var starter_data: Array = []
var selected_index: int = -1

@onready var cards_container: HBoxContainer = $VBoxContainer/CardsContainer
@onready var confirm_btn: Button = $VBoxContainer/ConfirmButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

func _ready() -> void:
	GameManager.change_state(GameManager.GameState.STARTER_SELECTION)
	confirm_btn.disabled = true
	confirm_btn.pressed.connect(_on_confirm)

	# Load starter data
	for path in STARTER_PATHS:
		var data: DragonData = load(path)
		starter_data.append(data)

	_create_dragon_cards()

func _create_dragon_cards() -> void:
	for i in starter_data.size():
		var data: DragonData = starter_data[i]
		var card := _build_card(data, i)
		cards_container.add_child(card)

func _build_card(data: DragonData, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 400)
	card.name = "Card_%d" % index

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.14, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.25, 0.4, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.theme_override_constants = {}
	vbox.add_theme_constant_override("separation", 8)

	# Dragon name
	var name_label := Label.new()
	name_label.text = data.dragon_name
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", data.color_primary)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Element tag
	var element_label := Label.new()
	element_label.text = "[%s]" % data.element.to_upper()
	element_label.add_theme_font_size_override("font_size", 14)
	element_label.add_theme_color_override("font_color", TypeChart.get_element_color(data.element))
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(element_label)

	# 3D preview area (colored rect placeholder)
	var preview := ColorRect.new()
	preview.custom_minimum_size = Vector2(260, 150)
	preview.color = Color(data.color_primary, 0.15)

	# CSG dragon preview via SubViewport
	var sub_viewport_container := SubViewportContainer.new()
	sub_viewport_container.custom_minimum_size = Vector2(260, 150)
	sub_viewport_container.stretch = true

	var sub_viewport := SubViewport.new()
	sub_viewport.size = Vector2i(260, 150)
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Simple dragon model in viewport
	var dragon_model := _create_dragon_preview(data)
	sub_viewport.add_child(dragon_model)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 4.0
	cam.transform = Transform3D(Basis.IDENTITY, Vector3(0, 1.5, 3))
	cam.look_at(Vector3(0, 0.8, 0))
	sub_viewport.add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	sub_viewport.add_child(light)

	sub_viewport_container.add_child(sub_viewport)
	vbox.add_child(sub_viewport_container)

	# Stats
	var stats_text := "HP: %d  ATK: %d  DEF: %d\nMP: %d  AGI: %d" % [
		data.get_stat_at_level("hp", 5),
		data.get_stat_at_level("atk", 5),
		data.get_stat_at_level("def", 5),
		data.get_stat_at_level("mp", 5),
		data.get_stat_at_level("agi", 5),
	]
	var stats_label := Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 15)
	stats_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.85))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = data.description
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.55, 0.52, 0.65))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Select button
	var select_btn := Button.new()
	select_btn.text = "Choose %s" % data.dragon_name
	select_btn.pressed.connect(_on_card_selected.bind(index))
	vbox.add_child(select_btn)

	card.add_child(vbox)
	return card

func _create_dragon_preview(data: DragonData) -> Node3D:
	var root := ModelFactory.build_dragon_model(data)
	ModelFactory.add_dragon_aura(root, data.color_primary, data.model_scale)

	# Rotate slowly
	var rotate_script := GDScript.new()
	rotate_script.source_code = 'extends Node3D\nfunc _process(delta):\n\trotate_y(delta * 0.8)\n'
	rotate_script.reload()
	root.set_script(rotate_script)

	return root

func _on_card_selected(index: int) -> void:
	selected_index = index
	confirm_btn.disabled = false
	confirm_btn.text = "Confirm: %s" % starter_data[index].dragon_name

	# Highlight selected card
	for i in cards_container.get_child_count():
		var card: PanelContainer = cards_container.get_child(i)
		var style: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
		if i == index:
			style.border_color = Color(0.8, 0.65, 1.0, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
		else:
			style.border_color = Color(0.3, 0.25, 0.4, 0.6)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		card.add_theme_stylebox_override("panel", style)

	if description_label:
		description_label.text = starter_data[index].description

func _on_confirm() -> void:
	if selected_index < 0:
		return

	var data: DragonData = starter_data[selected_index]
	var instance := DragonInstance.new()
	instance.base_data = data
	instance.nickname = data.dragon_name
	instance.level = 5
	instance.initialize_from_base()

	PartyManager.add_dragon(instance)
	PartyManager.set_active_dragon(0)

	# Give starting soul gems (3 common, 1 rare)
	for i in 3:
		var gem := SoulGemData.new()
		gem.gem_id = "soul_gem_common_%d" % i
		gem.gem_name = "Soul Gem"
		gem.tier = 1
		gem.capture_bonus = 1.0
		gem.color = Color(0.6, 0.6, 0.7)
		PartyManager.equip_gem(i, gem)

	var rare_gem := SoulGemData.new()
	rare_gem.gem_id = "soul_gem_rare_0"
	rare_gem.gem_name = "Soul Gem"
	rare_gem.tier = 3
	rare_gem.capture_bonus = 1.5
	rare_gem.color = Color(0.3, 0.5, 1.0)
	PartyManager.equip_gem(3, rare_gem)

	print("[StarterSelection] Chose: %s, Party size: %d" % [data.dragon_name, PartyManager.party.size()])
	GameManager.change_state(GameManager.GameState.OVERWORLD)
	EventBus.scene_transition_requested.emit("overworld")
