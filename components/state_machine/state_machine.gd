class_name StateMachine
extends Node
## Generic state machine. Children should extend State.

signal state_changed(old_state: StringName, new_state: StringName)

@export var initial_state: State = null
var current_state: State = null
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
	if initial_state:
		current_state = initial_state
		current_state.enter({})

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(state_name: StringName, params: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("[StateMachine] No state: %s" % state_name)
		return
	var old_name := current_state.name if current_state else &""
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter(params)
	state_changed.emit(old_name, state_name)
