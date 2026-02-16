class_name StatsComponent
extends Node
## Holds combat stats for an entity.

@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 10  # AGI
@export var hp: int = 100
@export var mp: int = 50

func get_stat(stat_name: String) -> int:
	match stat_name:
		"atk": return attack
		"def": return defense
		"agi", "spd": return speed
		"hp": return hp
		"mp": return mp
	return 0
