extends Node
## Root scene manager. Handles scene loading and fade transitions.

@onready var scene_container: Node = $SceneContainer
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var current_scene: Node = null
var _fade_tween: Tween = null

const SCENES := {
	"main_menu": "res://scenes/main_menu/main_menu.tscn",
	"starter_selection": "res://scenes/starter_selection/starter_selection.tscn",
	"overworld": "res://scenes/overworld/overworld.tscn",
}

func _ready() -> void:
	GameManager.main_node = self
	EventBus.scene_transition_requested.connect(_on_scene_transition)
	EventBus.fade_requested.connect(_on_fade_requested)

	# Start fully black, then load main menu
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.show()
	await get_tree().create_timer(0.1).timeout
	_load_scene("main_menu")
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	_fade_out(1.0)

func _on_scene_transition(scene_name: StringName) -> void:
	await _fade_in(0.5)
	_load_scene(scene_name)
	await _fade_out(0.5)

func _load_scene(scene_name: String) -> void:
	if not SCENES.has(scene_name):
		push_error("[Main] Unknown scene: %s" % scene_name)
		return

	# Remove current scene
	if current_scene:
		scene_container.remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null

	# Load new scene
	var packed: PackedScene = load(SCENES[scene_name])
	current_scene = packed.instantiate()
	scene_container.add_child(current_scene)
	print("[Main] Loaded scene: %s" % scene_name)

func _fade_in(duration: float) -> void:
	## Fade to black
	if _fade_tween:
		_fade_tween.kill()
	fade_rect.show()
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await _fade_tween.finished
	EventBus.fade_completed.emit()

func _fade_out(duration: float) -> void:
	## Fade from black to transparent
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await _fade_tween.finished
	fade_rect.hide()
	EventBus.fade_completed.emit()

func _on_fade_requested(fade_in_flag: bool, duration: float) -> void:
	if fade_in_flag:
		await _fade_in(duration)
	else:
		await _fade_out(duration)
