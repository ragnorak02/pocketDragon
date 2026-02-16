class_name HealthComponent
extends Node
## Manages HP for any entity.

signal health_changed(current: int, maximum: int)
signal died()

@export var max_hp: int = 100
var current_hp: int = 100

func _ready() -> void:
	current_hp = max_hp

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	health_changed.emit(current_hp, max_hp)

func get_hp_ratio() -> float:
	return float(current_hp) / max(float(max_hp), 1.0)
