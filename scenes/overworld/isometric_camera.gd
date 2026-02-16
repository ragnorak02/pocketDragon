extends Camera3D
## Orthogonal isometric camera with smooth follow.

@export var target: Node3D = null
@export var follow_speed: float = 5.0
@export var offset := Vector3(0, 12, 12)  # Camera offset from target

var _target_position := Vector3.ZERO

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = 14.0
	# Isometric rotation: -30 pitch, 45 yaw
	rotation_degrees = Vector3(-30, -45, 0)
	near = 0.1
	far = 100.0

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		_target_position = target.global_position + offset
		global_position = global_position.lerp(_target_position, follow_speed * delta)

func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		global_position = target.global_position + offset
