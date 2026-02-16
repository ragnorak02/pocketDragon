class_name AbilityData
extends Resource
## Data for a combat ability.

@export var ability_id: String = ""
@export var ability_name: String = ""
@export var description: String = ""
@export var element: String = "neutral"
@export var power: int = 40
@export var mp_cost: int = 5
@export var accuracy: float = 1.0
@export var is_physical: bool = true  # Physical vs magical for future expansion
@export var target_type: String = "single_enemy"  # single_enemy, all_enemies, self, single_ally

func get_class_name() -> String:
	return "AbilityData"
