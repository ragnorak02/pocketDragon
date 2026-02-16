extends Node
## Global event bus for decoupled communication between systems.

# Game flow
signal game_state_changed(old_state: StringName, new_state: StringName)
signal scene_transition_requested(scene_name: StringName)
signal fade_requested(fade_in: bool, duration: float)
signal fade_completed()

# Battle
signal battle_requested(enemy_data, enemy_node: Node3D)
signal battle_started()
signal battle_ended(result: StringName) # "victory", "defeat", "fled"
signal battle_state_changed(old_state: StringName, new_state: StringName)
signal turn_started(combatant_name: String)
signal action_selected(action: Dictionary)
signal action_executed(action: Dictionary, result: Dictionary)
signal damage_dealt(target_name: String, amount: int, is_critical: bool)
signal combatant_defeated(combatant_name: String)
signal xp_gained(dragon_name: String, amount: int)
signal level_up(dragon_name: String, new_level: int)

# Capture
signal capture_attempted(dragon_name: String, gem_tier: int)
signal capture_result(success: bool, dragon_name: String)

# Party
signal party_changed()
signal dragon_added(dragon_instance)
signal dragon_removed(dragon_instance)
signal active_dragon_changed(dragon_instance)
signal dragon_swapped_in_battle(dragon_instance)

# Overworld
signal player_entered_area(area_name: String)
signal enemy_spotted_player(enemy_node: Node3D)

# UI
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal dialog_requested(text: String, speaker: String)

# Bestiary
signal enemy_encountered(enemy_id: String)
signal dragon_encountered(dragon_id: String)
signal dragon_captured(dragon_id: String)
