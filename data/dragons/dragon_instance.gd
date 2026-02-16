class_name DragonInstance
extends Resource
## A specific dragon owned by the player. Mutable state.

@export var base_data: DragonData = null
@export var nickname: String = ""
@export var level: int = 1
@export var xp: int = 0
@export var current_hp: int = 0
@export var current_mp: int = 0

# XP thresholds: xp_to_next = 50 * level^1.5
func get_xp_to_next_level() -> int:
	return int(50.0 * pow(level, 1.5))

func get_max_hp() -> int:
	if base_data == null:
		return 1
	return base_data.get_stat_at_level("hp", level)

func get_max_mp() -> int:
	if base_data == null:
		return 0
	return base_data.get_stat_at_level("mp", level)

func get_stat(stat_name: String) -> int:
	if base_data == null:
		return 1
	return base_data.get_stat_at_level(stat_name, level)

func initialize_from_base() -> void:
	if base_data == null:
		return
	if nickname.is_empty():
		nickname = base_data.dragon_name
	current_hp = get_max_hp()
	current_mp = get_max_mp()

func add_xp(amount: int) -> bool:
	## Returns true if leveled up.
	xp += amount
	var leveled := false
	while xp >= get_xp_to_next_level() and level < 100:
		xp -= get_xp_to_next_level()
		level += 1
		current_hp = get_max_hp()
		current_mp = get_max_mp()
		EventBus.level_up.emit(nickname, level)
		leveled = true
	return leveled

func serialize() -> Dictionary:
	return {
		"base_data_path": base_data.resource_path if base_data else "",
		"nickname": nickname,
		"level": level,
		"xp": xp,
		"current_hp": current_hp,
		"current_mp": current_mp,
	}

static func deserialize(data: Dictionary) -> DragonInstance:
	var instance := DragonInstance.new()
	if data.has("base_data_path") and not data["base_data_path"].is_empty():
		instance.base_data = load(data["base_data_path"])
	instance.nickname = data.get("nickname", "")
	instance.level = data.get("level", 1)
	instance.xp = data.get("xp", 0)
	instance.current_hp = data.get("current_hp", instance.get_max_hp())
	instance.current_mp = data.get("current_mp", instance.get_max_mp())
	return instance
