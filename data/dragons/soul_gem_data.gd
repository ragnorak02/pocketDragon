class_name SoulGemData
extends Resource
## Data for a soul gem used in the gauntlet for dragon capture.

@export var gem_id: String = ""
@export var gem_name: String = ""
@export var tier: int = 1  # 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary
@export var capture_bonus: float = 1.0  # Multiplier for capture probability
@export var color: Color = Color(0.5, 0.5, 0.5)

# State (mutable)
@export var is_occupied: bool = false
@export var bound_dragon_id: String = ""
@export var bound_dragon_element: String = ""

static func get_tier_name(t: int) -> String:
	match t:
		1: return "Common"
		2: return "Uncommon"
		3: return "Rare"
		4: return "Epic"
		5: return "Legendary"
	return "Unknown"

func get_display_name() -> String:
	return "%s %s" % [SoulGemData.get_tier_name(tier), gem_name]

func serialize() -> Dictionary:
	return {
		"gem_id": gem_id,
		"gem_name": gem_name,
		"tier": tier,
		"capture_bonus": capture_bonus,
		"is_occupied": is_occupied,
		"bound_dragon_id": bound_dragon_id,
		"bound_dragon_element": bound_dragon_element,
	}
