class_name State
extends Node
## Base state class for the state machine.

var state_machine: StateMachine = null

func enter(_params: Dictionary) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
