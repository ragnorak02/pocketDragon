extends CharacterBody3D
## Player controller with 8-directional isometric movement.

@export var move_speed: float = 6.0
@export var rotation_speed: float = 10.0

var input_dir := Vector2.ZERO
var _iso_rotation := deg_to_rad(-45.0)  # 45deg rotation for isometric alignment

@onready var model: Node3D = $Model

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not GameManager.is_gameplay_active():
		velocity = Vector3.ZERO
		return

	# Get raw input
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir.length() > 0.1:
		# Rotate input by 45 degrees for isometric alignment
		var rotated := input_dir.rotated(_iso_rotation)
		var direction := Vector3(rotated.x, 0, rotated.y).normalized()

		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		# Smooth rotation toward movement direction
		var target_angle := atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0, move_speed * delta * 10.0)

	# Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	move_and_slide()
