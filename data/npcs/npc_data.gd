class_name NPCData
extends Resource
## Data for an NPC — name, dialog lines, and visual properties.

@export var npc_id: String = ""
@export var display_name: String = ""

@export_group("Dialog")
@export var dialog_lines: PackedStringArray = []

@export_group("Visual")
@export var color_primary: Color = Color(0.6, 0.4, 0.3, 1)
@export var color_secondary: Color = Color(0.4, 0.3, 0.2, 1)
@export var model_scale: float = 1.0
