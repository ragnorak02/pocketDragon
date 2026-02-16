extends Node
## Manages the player's dragon party, collection, and soul gems.

const MAX_PARTY_SIZE := 5
const MAX_GEM_SLOTS := 5
const COLLECTION_BONUS_PER_SPECIES := 0.02  # +2% all stats per unique species

var party: Array = []  # Array of DragonInstance resources
var active_dragon_index: int = 0
var collection: Dictionary = {}  # dragon_id -> bool (all dragons ever captured)
var soul_gems: Array = []  # Array of SoulGemData (gauntlet slots)
var gem_slots_used: int = 0

func _ready() -> void:
	# Initialize 5 empty gem slots
	for i in MAX_GEM_SLOTS:
		soul_gems.append(null)

func get_active_dragon():
	if party.is_empty():
		return null
	return party[active_dragon_index]

func add_dragon(dragon_instance) -> bool:
	if party.size() >= MAX_PARTY_SIZE:
		return false
	party.append(dragon_instance)
	collection[dragon_instance.base_data.dragon_id] = true
	EventBus.dragon_added.emit(dragon_instance)
	EventBus.party_changed.emit()
	return true

func remove_dragon(index: int) -> void:
	if index < 0 or index >= party.size():
		return
	var removed = party[index]
	party.remove_at(index)
	if active_dragon_index >= party.size():
		active_dragon_index = max(0, party.size() - 1)
	EventBus.dragon_removed.emit(removed)
	EventBus.party_changed.emit()

func set_active_dragon(index: int) -> void:
	if index < 0 or index >= party.size():
		return
	active_dragon_index = index
	EventBus.active_dragon_changed.emit(party[index])

func get_collection_bonus() -> float:
	return collection.size() * COLLECTION_BONUS_PER_SPECIES

func get_first_alive_dragon():
	for dragon in party:
		if dragon.current_hp > 0:
			return dragon
	return null

func has_alive_dragon() -> bool:
	return get_first_alive_dragon() != null

func equip_gem(slot_index: int, gem_data) -> void:
	if slot_index < 0 or slot_index >= MAX_GEM_SLOTS:
		return
	soul_gems[slot_index] = gem_data
	if gem_data != null:
		gem_slots_used = 0
		for gem in soul_gems:
			if gem != null:
				gem_slots_used += 1

func get_available_gem_slot() -> int:
	for i in soul_gems.size():
		if soul_gems[i] == null:
			return i
	return -1

func get_best_available_gem():
	## Returns the best unused gem for capture attempts.
	var best_gem = null
	var best_index := -1
	for i in soul_gems.size():
		var gem = soul_gems[i]
		if gem != null and not gem.is_occupied:
			if best_gem == null or gem.tier > best_gem.tier:
				best_gem = gem
				best_index = i
	return {"gem": best_gem, "index": best_index}

func heal_all_dragons() -> void:
	for dragon in party:
		dragon.current_hp = dragon.get_max_hp()
		dragon.current_mp = dragon.get_max_mp()

func get_save_data() -> Dictionary:
	var data := {
		"party": [],
		"active_index": active_dragon_index,
		"collection": collection.duplicate(),
		"gems": []
	}
	for dragon in party:
		data["party"].append(dragon.serialize())
	for gem in soul_gems:
		if gem != null:
			data["gems"].append(gem.serialize())
		else:
			data["gems"].append(null)
	return data

func load_save_data(data: Dictionary) -> void:
	if not data.has("party"):
		return
	var party_data: Dictionary = data["party"]

	# Clear current state
	party.clear()
	collection.clear()
	for i in MAX_GEM_SLOTS:
		soul_gems[i] = null

	# Load party dragons
	if party_data.has("party"):
		for dragon_dict in party_data["party"]:
			var dragon := DragonInstance.deserialize(dragon_dict)
			party.append(dragon)

	active_dragon_index = party_data.get("active_index", 0)

	# Load collection
	if party_data.has("collection"):
		collection = party_data["collection"].duplicate()

	# Load gems
	if party_data.has("gems"):
		for i in min(party_data["gems"].size(), MAX_GEM_SLOTS):
			var gem_dict = party_data["gems"][i]
			if gem_dict != null and gem_dict is Dictionary:
				var gem := SoulGemData.new()
				gem.gem_id = gem_dict.get("gem_id", "")
				gem.gem_name = gem_dict.get("gem_name", "Soul Gem")
				gem.tier = int(gem_dict.get("tier", 1))
				gem.capture_bonus = float(gem_dict.get("capture_bonus", 1.0))
				gem.is_occupied = gem_dict.get("is_occupied", false)
				gem.bound_dragon_id = gem_dict.get("bound_dragon_id", "")
				gem.bound_dragon_element = gem_dict.get("bound_dragon_element", "")
				soul_gems[i] = gem

	gem_slots_used = 0
	for gem in soul_gems:
		if gem != null:
			gem_slots_used += 1

	EventBus.party_changed.emit()
	print("[PartyManager] Loaded save: %d dragons, %d gems" % [party.size(), gem_slots_used])
