extends Node
## Core battle logic state machine. Owns all battle math; BattleArena owns visuals.

enum BattleState {
	INACTIVE,
	INITIATING,
	TURN_QUEUE_CALC,
	AWAITING_INPUT,
	ENEMY_TURN,
	EXECUTING_ACTION,
	CAPTURE_ATTEMPT,
	VICTORY,
	DEFEAT,
	FLED,
	CLEANUP
}

var state: BattleState = BattleState.INACTIVE
var turn_queue: Array = []  # Array of combatant dictionaries sorted by AGI
var current_turn_index: int = 0
var round_number: int = 0

# Battle participants
var player_dragon = null  # DragonInstance
var enemy_data = null  # EnemyData or DragonData
var enemy_node: Node3D = null  # Reference to overworld enemy
var enemy_current_hp: int = 0
var enemy_max_hp: int = 0
var enemy_current_mp: int = 0
var is_wild_dragon: bool = false

# Battle result tracking
var xp_reward: int = 0
var captured_dragon = null

func _ready() -> void:
	EventBus.battle_requested.connect(_on_battle_requested)
	EventBus.action_selected.connect(_on_action_selected)

func _on_battle_requested(data, node: Node3D) -> void:
	if state != BattleState.INACTIVE:
		return
	enemy_data = data
	enemy_node = node
	is_wild_dragon = data.has_method("get_class_name") and data.get_class_name() == "DragonData"
	if not is_wild_dragon and data is Resource and data.get("dragon_id") != null:
		is_wild_dragon = true
	start_battle()

func start_battle() -> void:
	_change_state(BattleState.INITIATING)
	player_dragon = PartyManager.get_active_dragon()
	if player_dragon == null:
		push_error("[BattleManager] No active dragon!")
		_change_state(BattleState.INACTIVE)
		return

	# Set up enemy stats
	if is_wild_dragon:
		enemy_max_hp = _calc_dragon_hp(enemy_data)
		enemy_current_hp = enemy_max_hp
		enemy_current_mp = enemy_data.base_mp
		xp_reward = enemy_data.xp_reward if enemy_data.get("xp_reward") else 50
		EventBus.dragon_encountered.emit(enemy_data.dragon_id)
	else:
		enemy_max_hp = enemy_data.max_hp
		enemy_current_hp = enemy_max_hp
		enemy_current_mp = enemy_data.get("max_mp") if enemy_data.get("max_mp") else 0
		xp_reward = enemy_data.xp_reward
		EventBus.enemy_encountered.emit(enemy_data.enemy_id)

	round_number = 0
	GameManager.change_state(GameManager.GameState.BATTLE)
	EventBus.battle_started.emit()
	# Wait for arena transition, then calc turns
	await get_tree().create_timer(1.5).timeout
	_next_round()

func _next_round() -> void:
	round_number += 1
	_change_state(BattleState.TURN_QUEUE_CALC)
	_calculate_turn_queue()
	current_turn_index = 0
	_process_next_turn()

func _calculate_turn_queue() -> void:
	turn_queue.clear()

	var player_agi: int = player_dragon.get_stat("agi")
	var collection_bonus := PartyManager.get_collection_bonus()
	player_agi = int(player_agi * (1.0 + collection_bonus))

	var enemy_agi: int
	if is_wild_dragon:
		enemy_agi = enemy_data.base_agi
	else:
		enemy_agi = enemy_data.agi

	turn_queue.append({
		"name": player_dragon.nickname,
		"is_player": true,
		"agi": player_agi
	})
	turn_queue.append({
		"name": enemy_data.display_name if enemy_data.get("display_name") else enemy_data.dragon_name if enemy_data.get("dragon_name") else "Enemy",
		"is_player": false,
		"agi": enemy_agi
	})

	# Sort by AGI descending (higher AGI goes first)
	turn_queue.sort_custom(func(a, b): return a["agi"] > b["agi"])
	print("[BattleManager] Turn order: %s" % str(turn_queue.map(func(t): return t["name"])))

func _process_next_turn() -> void:
	if current_turn_index >= turn_queue.size():
		_next_round()
		return

	# Check battle end conditions
	if player_dragon.current_hp <= 0:
		if not PartyManager.has_alive_dragon():
			_change_state(BattleState.DEFEAT)
			_handle_defeat()
			return
		# Auto-swap to next alive dragon
		var next = PartyManager.get_first_alive_dragon()
		var idx = PartyManager.party.find(next)
		PartyManager.set_active_dragon(idx)
		player_dragon = next
		EventBus.dragon_swapped_in_battle.emit(player_dragon)

	if enemy_current_hp <= 0:
		_change_state(BattleState.VICTORY)
		_handle_victory()
		return

	var current_combatant = turn_queue[current_turn_index]
	EventBus.turn_started.emit(current_combatant["name"])

	if current_combatant["is_player"]:
		_change_state(BattleState.AWAITING_INPUT)
	else:
		_change_state(BattleState.ENEMY_TURN)
		await get_tree().create_timer(0.8).timeout
		_execute_enemy_turn()

func _on_action_selected(action: Dictionary) -> void:
	if state != BattleState.AWAITING_INPUT:
		return
	match action["type"]:
		"attack":
			_execute_attack(true, action.get("ability"))
		"ability":
			_execute_attack(true, action["ability"])
		"capture":
			_execute_capture()
		"swap":
			_execute_swap(action["dragon_index"])
		"flee":
			_execute_flee()

func _execute_attack(is_player: bool, ability = null) -> void:
	_change_state(BattleState.EXECUTING_ACTION)
	var result: Dictionary

	if is_player:
		var atk: int = player_dragon.get_stat("atk")
		var collection_bonus := PartyManager.get_collection_bonus()
		atk = int(atk * (1.0 + collection_bonus))

		var def_stat: int
		if is_wild_dragon:
			def_stat = enemy_data.base_def
		else:
			def_stat = enemy_data.defense

		var power := 40  # Default attack power
		var element: String = player_dragon.base_data.element if player_dragon.base_data else "neutral"
		var ability_name := "Attack"

		if ability != null:
			power = ability.power
			element = ability.element
			ability_name = ability.ability_name
			var mp_cost: int = ability.mp_cost
			if player_dragon.current_mp < mp_cost:
				# Not enough MP, use basic attack
				power = 40
				element = "neutral"
				ability_name = "Attack"
			else:
				player_dragon.current_mp -= mp_cost

		var type_mult := _get_type_multiplier(element, _get_enemy_element())
		var damage := _calculate_damage(power, atk, def_stat, type_mult)

		enemy_current_hp = max(0, enemy_current_hp - damage)
		result = {
			"attacker": player_dragon.nickname,
			"target": _get_enemy_name(),
			"ability": ability_name,
			"damage": damage,
			"type_mult": type_mult,
			"is_critical": false,
			"target_hp": enemy_current_hp,
			"target_max_hp": enemy_max_hp
		}
		EventBus.damage_dealt.emit(_get_enemy_name(), damage, false)
	else:
		# Enemy attacks player
		var enemy_atk: int
		if is_wild_dragon:
			enemy_atk = enemy_data.base_atk
		else:
			enemy_atk = enemy_data.attack

		var player_def: int = player_dragon.get_stat("def")
		var collection_bonus := PartyManager.get_collection_bonus()
		player_def = int(player_def * (1.0 + collection_bonus))

		var ability_data = _pick_enemy_ability()
		var power := 40
		var element: String = _get_enemy_element()
		var ability_name := "Attack"

		if ability_data != null:
			power = ability_data.power
			element = ability_data.element
			ability_name = ability_data.ability_name

		var type_mult := _get_type_multiplier(element, player_dragon.base_data.element)
		var damage := _calculate_damage(power, enemy_atk, player_def, type_mult)

		player_dragon.current_hp = max(0, player_dragon.current_hp - damage)
		result = {
			"attacker": _get_enemy_name(),
			"target": player_dragon.nickname,
			"ability": ability_name,
			"damage": damage,
			"type_mult": type_mult,
			"is_critical": false,
			"target_hp": player_dragon.current_hp,
			"target_max_hp": player_dragon.get_max_hp()
		}
		EventBus.damage_dealt.emit(player_dragon.nickname, damage, false)

	var action: Dictionary = {"type": "attack", "ability_name": result["ability"]}
	EventBus.action_executed.emit(action, result)
	await get_tree().create_timer(1.0).timeout

	current_turn_index += 1
	_process_next_turn()

func _execute_enemy_turn() -> void:
	_execute_attack(false, _pick_enemy_ability())

func _pick_enemy_ability():
	var abilities: Array
	if is_wild_dragon:
		abilities = enemy_data.abilities if enemy_data.get("abilities") else []
	else:
		abilities = enemy_data.abilities if enemy_data.get("abilities") else []

	if abilities.is_empty():
		return null

	# Weighted random: prefer stronger abilities
	var valid_abilities = abilities.filter(func(a): return a != null)
	if valid_abilities.is_empty():
		return null
	return valid_abilities[randi() % valid_abilities.size()]

func _execute_capture() -> void:
	if not is_wild_dragon:
		# Can't capture non-dragons
		var result := {"type": "capture", "success": false, "reason": "not_dragon"}
		EventBus.action_executed.emit({"type": "capture"}, result)
		current_turn_index += 1
		_process_next_turn()
		return

	_change_state(BattleState.CAPTURE_ATTEMPT)
	var gem_info = PartyManager.get_best_available_gem()
	if gem_info["gem"] == null:
		var result := {"type": "capture", "success": false, "reason": "no_gems"}
		EventBus.action_executed.emit({"type": "capture"}, result)
		EventBus.capture_result.emit(false, _get_enemy_name())
		await get_tree().create_timer(1.0).timeout
		current_turn_index += 1
		_change_state(BattleState.EXECUTING_ACTION)
		_process_next_turn()
		return

	var gem = gem_info["gem"]
	var hp_ratio := float(enemy_current_hp) / float(enemy_max_hp)
	var difficulty: float = enemy_data.capture_difficulty if enemy_data.get("capture_difficulty") else 1.0
	var gem_bonus: float = gem.capture_bonus if gem.get("capture_bonus") else 1.0

	# Capture probability = (1 - hp_ratio) * 0.8 / difficulty * gem_bonus
	var probability := (1.0 - hp_ratio) * 0.8 / difficulty * gem_bonus
	probability = clamp(probability, 0.05, 0.95)

	var roll := randf()
	var success := roll <= probability

	EventBus.capture_attempted.emit(_get_enemy_name(), gem.tier if gem.get("tier") else 1)
	print("[BattleManager] Capture: prob=%.2f, roll=%.2f, success=%s" % [probability, roll, success])

	await get_tree().create_timer(2.0).timeout  # Capture animation time

	if success:
		# Mark gem as occupied
		gem.is_occupied = true
		gem.bound_dragon_id = enemy_data.dragon_id
		gem.bound_dragon_element = enemy_data.element

		# Create DragonInstance for captured dragon
		var DragonInstanceRes = load("res://data/dragons/dragon_instance.gd")
		var new_dragon = DragonInstanceRes.new()
		new_dragon.base_data = enemy_data
		new_dragon.nickname = enemy_data.dragon_name
		new_dragon.level = max(1, int(enemy_data.base_level) if enemy_data.get("base_level") else 5)
		new_dragon.current_hp = enemy_current_hp
		new_dragon.current_mp = enemy_current_mp
		new_dragon.xp = 0
		new_dragon.initialize_from_base()

		PartyManager.add_dragon(new_dragon)
		captured_dragon = new_dragon
		EventBus.capture_result.emit(true, _get_enemy_name())
		EventBus.dragon_captured.emit(enemy_data.dragon_id)

		# Capture ends battle
		_change_state(BattleState.VICTORY)
		_handle_victory()
	else:
		EventBus.capture_result.emit(false, _get_enemy_name())
		await get_tree().create_timer(0.5).timeout
		current_turn_index += 1
		_change_state(BattleState.EXECUTING_ACTION)
		_process_next_turn()

func _execute_swap(dragon_index: int) -> void:
	_change_state(BattleState.EXECUTING_ACTION)
	PartyManager.set_active_dragon(dragon_index)
	player_dragon = PartyManager.get_active_dragon()
	EventBus.dragon_swapped_in_battle.emit(player_dragon)
	var action := {"type": "swap"}
	var result := {"swapped_to": player_dragon.nickname}
	EventBus.action_executed.emit(action, result)
	await get_tree().create_timer(0.5).timeout
	# Swap costs the turn
	current_turn_index += 1
	_process_next_turn()

func _execute_flee() -> void:
	_change_state(BattleState.EXECUTING_ACTION)
	var flee_chance := 0.6
	if randf() <= flee_chance:
		_change_state(BattleState.FLED)
		EventBus.battle_ended.emit("fled")
		await get_tree().create_timer(1.0).timeout
		_cleanup()
	else:
		var action := {"type": "flee"}
		var result := {"success": false}
		EventBus.action_executed.emit(action, result)
		await get_tree().create_timer(0.5).timeout
		current_turn_index += 1
		_process_next_turn()

func _handle_victory() -> void:
	# Award XP to active dragon
	if player_dragon and xp_reward > 0:
		player_dragon.add_xp(xp_reward)
		EventBus.xp_gained.emit(player_dragon.nickname, xp_reward)
	EventBus.battle_ended.emit("victory")
	await get_tree().create_timer(2.0).timeout
	_cleanup()

func _handle_defeat() -> void:
	EventBus.battle_ended.emit("defeat")
	await get_tree().create_timer(2.0).timeout
	_cleanup()

func _cleanup() -> void:
	_change_state(BattleState.CLEANUP)
	# Remove defeated/captured enemy from overworld
	if enemy_node and is_instance_valid(enemy_node) and (enemy_current_hp <= 0 or captured_dragon != null):
		enemy_node.queue_free()

	# Reset battle state
	player_dragon = null
	enemy_data = null
	enemy_node = null
	enemy_current_hp = 0
	enemy_max_hp = 0
	is_wild_dragon = false
	xp_reward = 0
	captured_dragon = null
	turn_queue.clear()
	current_turn_index = 0
	round_number = 0

	GameManager.change_state(GameManager.GameState.OVERWORLD)
	_change_state(BattleState.INACTIVE)

func _calculate_damage(power: int, atk: int, def_stat: int, type_mult: float) -> int:
	var base: float = float(power) * float(atk) / max(float(def_stat), 1.0)
	var random_mod := randf_range(0.85, 1.15)
	return max(1, int(base * type_mult * random_mod))

func _get_type_multiplier(atk_element: String, def_element: String) -> float:
	# Defer to TypeChart
	var TypeChart = load("res://data/type_chart.gd")
	return TypeChart.get_multiplier(atk_element, def_element)

func _get_enemy_element() -> String:
	if is_wild_dragon:
		return enemy_data.element if enemy_data.get("element") else "neutral"
	return enemy_data.element if enemy_data.get("element") else "neutral"

func _get_enemy_name() -> String:
	if is_wild_dragon:
		return enemy_data.dragon_name if enemy_data.get("dragon_name") else "Wild Dragon"
	return enemy_data.display_name if enemy_data.get("display_name") else "Enemy"

func _calc_dragon_hp(dragon_data) -> int:
	return dragon_data.base_hp if dragon_data.get("base_hp") else 100

func _change_state(new_state: BattleState) -> void:
	if new_state == state:
		return
	var old_name: String = BattleState.keys()[state]
	state = new_state
	var new_name: String = BattleState.keys()[new_state]
	EventBus.battle_state_changed.emit(old_name, new_name)
