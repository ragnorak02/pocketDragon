extends Node
## Manages overall game state and scene transitions.

enum GameState {
	NONE,
	MAIN_MENU,
	STARTER_SELECTION,
	OVERWORLD,
	BATTLE,
	PAUSED,
	CUTSCENE
}

var current_state: GameState = GameState.NONE
var previous_state: GameState = GameState.NONE
var main_node: Node = null  # Reference to main.tscn root

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	previous_state = current_state
	var old_name: String = GameState.keys()[current_state]
	current_state = new_state
	var new_name: String = GameState.keys()[new_state]
	EventBus.game_state_changed.emit(old_name, new_name)
	print("[GameManager] State: %s → %s" % [old_name, new_name])

func is_gameplay_active() -> bool:
	return current_state == GameState.OVERWORLD

func is_in_battle() -> bool:
	return current_state == GameState.BATTLE

func request_scene(scene_name: StringName) -> void:
	EventBus.scene_transition_requested.emit(scene_name)
