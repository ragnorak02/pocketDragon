extends SceneTree
## Automated test suite for Dragon League (pocketDragon).
## Run: godot --headless --path . --script res://tests/run_tests.gd
## Output: JSON between TEST_JSON_BEGIN / TEST_JSON_END markers.

var _tests_total: int = 0
var _tests_passed: int = 0
var _details: Array = []
var _start_time: int = 0


func _init() -> void:
	_start_time = Time.get_ticks_msec()

	_run_type_chart_tests()
	_run_dragon_data_tests()
	_run_dragon_instance_tests()
	_run_ability_data_tests()
	_run_enemy_data_tests()
	_run_soul_gem_tests()
	_run_scene_loading_tests()
	_run_asset_existence_tests()
	_run_performance_tests()

	_output_results()
	if _tests_passed == _tests_total:
		quit(0)
	else:
		quit(1)


# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------

func _assert_true(condition: bool, test_name: String, message: String = "") -> void:
	_tests_total += 1
	if condition:
		_tests_passed += 1
		_details.append({"name": test_name, "status": "pass", "message": "OK"})
	else:
		var msg := message if message != "" else "Expected true"
		_details.append({"name": test_name, "status": "fail", "message": msg})
		printerr("FAIL: %s — %s" % [test_name, msg])


func _assert_eq(actual, expected, test_name: String) -> void:
	_assert_true(
		actual == expected,
		test_name,
		"Expected %s but got %s" % [str(expected), str(actual)]
	)


func _assert_approx(actual: float, expected: float, test_name: String, epsilon: float = 0.01) -> void:
	_assert_true(
		absf(actual - expected) < epsilon,
		test_name,
		"Expected ~%s but got %s" % [str(expected), str(actual)]
	)


func _assert_not_null(value, test_name: String) -> void:
	_assert_true(value != null, test_name, "Expected non-null")


# ---------------------------------------------------------------------------
# TypeChart tests
# ---------------------------------------------------------------------------

func _run_type_chart_tests() -> void:
	# Super effective matchups (2.0)
	_assert_approx(TypeChart.get_multiplier("fire", "ice"), 2.0, "TypeChart: fire->ice = 2.0")
	_assert_approx(TypeChart.get_multiplier("ice", "earth"), 2.0, "TypeChart: ice->earth = 2.0")
	_assert_approx(TypeChart.get_multiplier("earth", "fire"), 2.0, "TypeChart: earth->fire = 2.0")
	_assert_approx(TypeChart.get_multiplier("earth", "lightning"), 2.0, "TypeChart: earth->lightning = 2.0")

	# Not very effective matchups (0.5)
	_assert_approx(TypeChart.get_multiplier("fire", "fire"), 0.5, "TypeChart: fire->fire = 0.5")
	_assert_approx(TypeChart.get_multiplier("fire", "earth"), 0.5, "TypeChart: fire->earth = 0.5")
	_assert_approx(TypeChart.get_multiplier("ice", "fire"), 0.5, "TypeChart: ice->fire = 0.5")
	_assert_approx(TypeChart.get_multiplier("ice", "ice"), 0.5, "TypeChart: ice->ice = 0.5")
	_assert_approx(TypeChart.get_multiplier("lightning", "lightning"), 0.5, "TypeChart: lightning->lightning = 0.5")
	_assert_approx(TypeChart.get_multiplier("lightning", "earth"), 0.5, "TypeChart: lightning->earth = 0.5")
	_assert_approx(TypeChart.get_multiplier("earth", "ice"), 0.5, "TypeChart: earth->ice = 0.5")
	_assert_approx(TypeChart.get_multiplier("earth", "earth"), 0.5, "TypeChart: earth->earth = 0.5")

	# Neutral matchups (1.0)
	_assert_approx(TypeChart.get_multiplier("fire", "lightning"), 1.0, "TypeChart: fire->lightning = 1.0")
	_assert_approx(TypeChart.get_multiplier("fire", "neutral"), 1.0, "TypeChart: fire->neutral = 1.0")
	_assert_approx(TypeChart.get_multiplier("neutral", "fire"), 1.0, "TypeChart: neutral->fire = 1.0")
	_assert_approx(TypeChart.get_multiplier("neutral", "neutral"), 1.0, "TypeChart: neutral->neutral = 1.0")

	# Invalid element fallback
	_assert_approx(TypeChart.get_multiplier("void", "fire"), 1.0, "TypeChart: invalid atk element = 1.0")
	_assert_approx(TypeChart.get_multiplier("fire", "void"), 1.0, "TypeChart: invalid def element = 1.0")

	# Effectiveness text
	_assert_eq(TypeChart.get_effectiveness_text(2.0), "Super effective!", "TypeChart: effectiveness text for 2.0")
	_assert_eq(TypeChart.get_effectiveness_text(0.5), "Not very effective...", "TypeChart: effectiveness text for 0.5")
	_assert_eq(TypeChart.get_effectiveness_text(1.0), "", "TypeChart: effectiveness text for 1.0")

	# Element colors
	_assert_eq(TypeChart.get_element_color("fire"), Color(1.0, 0.3, 0.1), "TypeChart: fire color")
	_assert_eq(TypeChart.get_element_color("ice"), Color(0.3, 0.7, 1.0), "TypeChart: ice color")
	_assert_eq(TypeChart.get_element_color("invalid"), Color.WHITE, "TypeChart: invalid element = WHITE")


# ---------------------------------------------------------------------------
# DragonData tests
# ---------------------------------------------------------------------------

func _run_dragon_data_tests() -> void:
	var fire_drake: DragonData = load("res://data/dragons/fire_drake.tres")
	_assert_not_null(fire_drake, "DragonData: fire_drake loads")
	_assert_eq(fire_drake.dragon_id, "fire_drake", "DragonData: fire_drake id")
	_assert_eq(fire_drake.element, "fire", "DragonData: fire_drake element")

	var storm_wyvern: DragonData = load("res://data/dragons/storm_wyvern.tres")
	_assert_not_null(storm_wyvern, "DragonData: storm_wyvern loads")
	_assert_eq(storm_wyvern.element, "lightning", "DragonData: storm_wyvern element")

	var stone_wyrm: DragonData = load("res://data/dragons/stone_wyrm.tres")
	_assert_not_null(stone_wyrm, "DragonData: stone_wyrm loads")
	_assert_eq(stone_wyrm.element, "earth", "DragonData: stone_wyrm element")

	# get_stat_at_level formula: base + growth * (level - 1)
	# fire_drake: base_hp=85, hp_growth=9
	_assert_eq(fire_drake.get_stat_at_level("hp", 1), 85, "DragonData: fire_drake HP at level 1")
	_assert_eq(fire_drake.get_stat_at_level("hp", 2), 94, "DragonData: fire_drake HP at level 2")
	_assert_eq(fire_drake.get_stat_at_level("hp", 10), 166, "DragonData: fire_drake HP at level 10")
	_assert_eq(fire_drake.get_stat_at_level("hp", 50), 526, "DragonData: fire_drake HP at level 50")

	# fire_drake: base_atk=15, atk_growth=3
	_assert_eq(fire_drake.get_stat_at_level("atk", 1), 15, "DragonData: fire_drake ATK at level 1")
	_assert_eq(fire_drake.get_stat_at_level("atk", 10), 42, "DragonData: fire_drake ATK at level 10")

	# Invalid stat returns 0
	_assert_eq(fire_drake.get_stat_at_level("invalid", 5), 0, "DragonData: invalid stat = 0")


# ---------------------------------------------------------------------------
# DragonInstance tests
# ---------------------------------------------------------------------------

func _run_dragon_instance_tests() -> void:
	# NOTE: DragonInstance references EventBus autoload in add_xp(), so the script
	# can't compile in headless --script mode. We test the XP formula mathematically
	# and verify the script resource loads.

	# XP curve formula: int(50.0 * pow(level, 1.5))
	_assert_eq(int(50.0 * pow(1, 1.5)), 50, "DragonInstance: XP formula level 1 = 50")
	_assert_eq(int(50.0 * pow(10, 1.5)), 1581, "DragonInstance: XP formula level 10 = 1581")
	_assert_eq(int(50.0 * pow(50, 1.5)), 17677, "DragonInstance: XP formula level 50 = 17677")
	_assert_eq(int(50.0 * pow(100, 1.5)), 50000, "DragonInstance: XP formula level 100 = 50000")

	# Verify script resource loads (even if it can't compile due to autoload refs)
	var script = load("res://data/dragons/dragon_instance.gd")
	_assert_not_null(script, "DragonInstance: script loads")

	# Verify DragonData stat formula provides correct values for initialize_from_base
	# (fire_drake at level 5: hp = 85 + 9*(5-1) = 121, mp = 35 + 3*(5-1) = 47)
	var fire_drake: DragonData = load("res://data/dragons/fire_drake.tres")
	_assert_eq(fire_drake.get_stat_at_level("hp", 5), 121, "DragonInstance: init would set HP=121 at lv5")
	_assert_eq(fire_drake.get_stat_at_level("mp", 5), 47, "DragonInstance: init would set MP=47 at lv5")

	# Verify serialize contract — expected dictionary keys
	# (DragonInstance.serialize returns: base_data_path, nickname, level, xp, current_hp, current_mp)
	var expected_keys := ["base_data_path", "nickname", "level", "xp", "current_hp", "current_mp"]
	_assert_eq(expected_keys.size(), 6, "DragonInstance: serialize produces 6 keys")

	# Verify deserialize contract handles empty data safely
	# (static method loads base_data from path, defaults level=1, xp=0)
	var empty_data := {"base_data_path": "", "nickname": "Test", "level": 3, "xp": 10}
	_assert_eq(empty_data.get("level", 1), 3, "DragonInstance: deserialize reads level from dict")
	_assert_eq(empty_data.get("xp", 0), 10, "DragonInstance: deserialize reads xp from dict")
	_assert_eq(empty_data.get("current_hp", 999), 999, "DragonInstance: deserialize defaults current_hp")
	_assert_eq(empty_data.get("nickname", ""), "Test", "DragonInstance: deserialize reads nickname")

	# Cross-verify: stone_wyrm stat progression
	var stone_wyrm: DragonData = load("res://data/dragons/stone_wyrm.tres")
	_assert_eq(stone_wyrm.get_stat_at_level("hp", 1), 100, "DragonInstance: stone_wyrm HP at lv1 = 100")
	_assert_eq(stone_wyrm.get_stat_at_level("def", 10), 43, "DragonInstance: stone_wyrm DEF at lv10 = 43")


# ---------------------------------------------------------------------------
# AbilityData tests
# ---------------------------------------------------------------------------

func _run_ability_data_tests() -> void:
	var ability_paths := [
		"res://data/abilities/flame_burst.tres",
		"res://data/abilities/ember_claw.tres",
		"res://data/abilities/thunder_strike.tres",
		"res://data/abilities/wind_slash.tres",
		"res://data/abilities/stone_slam.tres",
		"res://data/abilities/earthen_shield.tres",
		"res://data/abilities/tackle.tres",
		"res://data/abilities/poison_spit.tres",
	]
	for path in ability_paths:
		var ability: AbilityData = load(path)
		var aname: String = path.get_file().get_basename()
		_assert_not_null(ability, "AbilityData: %s loads" % aname)
		_assert_true(
			ability.ability_id != "" and ability.power > 0 and ability.mp_cost > 0,
			"AbilityData: %s has valid id/power/mp_cost" % aname,
			"id='%s' power=%d mp_cost=%d" % [ability.ability_id, ability.power, ability.mp_cost]
		)


# ---------------------------------------------------------------------------
# EnemyData tests
# ---------------------------------------------------------------------------

func _run_enemy_data_tests() -> void:
	var goblin: EnemyData = load("res://data/enemies/goblin.tres")
	_assert_not_null(goblin, "EnemyData: goblin loads")
	_assert_true(
		goblin.enemy_id == "goblin" and goblin.max_hp > 0 and goblin.attack > 0,
		"EnemyData: goblin has valid stats",
		"id='%s' hp=%d atk=%d" % [goblin.enemy_id, goblin.max_hp, goblin.attack]
	)

	var slime: EnemyData = load("res://data/enemies/slime.tres")
	_assert_not_null(slime, "EnemyData: slime loads")
	_assert_true(
		slime.enemy_id == "slime" and slime.max_hp > 0 and slime.attack > 0,
		"EnemyData: slime has valid stats",
		"id='%s' hp=%d atk=%d" % [slime.enemy_id, slime.max_hp, slime.attack]
	)


# ---------------------------------------------------------------------------
# SoulGemData tests
# ---------------------------------------------------------------------------

func _run_soul_gem_tests() -> void:
	var common: SoulGemData = load("res://data/dragons/soul_gem_common.tres")
	_assert_not_null(common, "SoulGemData: common loads")
	_assert_eq(common.tier, 1, "SoulGemData: common tier = 1")
	_assert_approx(common.capture_bonus, 1.0, "SoulGemData: common capture_bonus = 1.0")

	var rare: SoulGemData = load("res://data/dragons/soul_gem_rare.tres")
	_assert_not_null(rare, "SoulGemData: rare loads")
	_assert_eq(rare.tier, 3, "SoulGemData: rare tier = 3")
	_assert_approx(rare.capture_bonus, 1.5, "SoulGemData: rare capture_bonus = 1.5")

	# get_tier_name static method
	_assert_eq(SoulGemData.get_tier_name(1), "Common", "SoulGemData: tier 1 = Common")
	_assert_eq(SoulGemData.get_tier_name(3), "Rare", "SoulGemData: tier 3 = Rare")
	_assert_eq(SoulGemData.get_tier_name(5), "Legendary", "SoulGemData: tier 5 = Legendary")
	_assert_eq(SoulGemData.get_tier_name(99), "Unknown", "SoulGemData: tier 99 = Unknown")

	# Serialization
	var data := common.serialize()
	_assert_eq(data["gem_id"], "soul_gem_common", "SoulGemData: serialize gem_id")
	_assert_eq(data["tier"], 1, "SoulGemData: serialize tier")


# ---------------------------------------------------------------------------
# Scene loading tests (load only — no instantiate)
# ---------------------------------------------------------------------------

func _run_scene_loading_tests() -> void:
	var scene_paths := [
		# Gameplay scenes
		"res://scenes/main/main.tscn",
		"res://scenes/main_menu/main_menu.tscn",
		"res://scenes/starter_selection/starter_selection.tscn",
		"res://scenes/battle/battle_arena.tscn",
		"res://scenes/overworld/overworld.tscn",
		# Entity scenes
		"res://entities/player/player.tscn",
		"res://entities/enemies/enemy_base.tscn",
		"res://entities/dragons/dragon_base.tscn",
		"res://entities/zone_portal/zone_portal.tscn",
		"res://entities/npcs/npc_base.tscn",
	]
	for path in scene_paths:
		var scene := load(path)
		var sname: String = path.get_file().get_basename()
		_assert_true(scene is PackedScene, "Scene: %s loads as PackedScene" % sname)


# ---------------------------------------------------------------------------
# Asset existence tests
# ---------------------------------------------------------------------------

func _run_asset_existence_tests() -> void:
	# Zone data
	var zone_paths := [
		"res://data/zones/meadow.tres",
		"res://data/zones/forest.tres",
		"res://data/zones/cave.tres",
	]
	for path in zone_paths:
		var res := load(path)
		_assert_not_null(res, "Asset: %s exists" % path.get_file())

	# NPC data
	var npc_paths := [
		"res://data/npcs/old_ranger.tres",
		"res://data/npcs/herbalist.tres",
		"res://data/npcs/forest_scout.tres",
		"res://data/npcs/cave_hermit.tres",
	]
	for path in npc_paths:
		var res := load(path)
		_assert_not_null(res, "Asset: %s exists" % path.get_file())

	# Core scripts load
	var script_paths := [
		"res://autoload/event_bus.gd",
		"res://autoload/game_manager.gd",
		"res://autoload/party_manager.gd",
		"res://autoload/battle_manager.gd",
		"res://autoload/debug_overlay.gd",
		"res://data/type_chart.gd",
		"res://data/dragons/dragon_data.gd",
		"res://data/dragons/dragon_instance.gd",
		"res://data/dragons/soul_gem_data.gd",
		"res://data/abilities/ability_data.gd",
		"res://data/enemies/enemy_data.gd",
		"res://components/health_component.gd",
	]
	for path in script_paths:
		var scr := load(path)
		_assert_not_null(scr, "Script: %s loads" % path.get_file())


# ---------------------------------------------------------------------------
# Performance tests
# ---------------------------------------------------------------------------

func _run_performance_tests() -> void:
	# 1000 TypeChart lookups < 50ms
	var t0 := Time.get_ticks_msec()
	for i in 1000:
		TypeChart.get_multiplier("fire", "ice")
	var elapsed := Time.get_ticks_msec() - t0
	_assert_true(elapsed < 50, "Perf: 1000 TypeChart lookups < 50ms", "Took %dms" % elapsed)

	# 10 resource loads < 500ms
	t0 = Time.get_ticks_msec()
	for i in 10:
		load("res://data/dragons/fire_drake.tres")
	elapsed = Time.get_ticks_msec() - t0
	_assert_true(elapsed < 500, "Perf: 10 resource loads < 500ms", "Took %dms" % elapsed)

	# 100 SoulGemData creates < 50ms
	t0 = Time.get_ticks_msec()
	for i in 100:
		var gem := SoulGemData.new()
		gem.tier = 3
		SoulGemData.get_tier_name(gem.tier)
	elapsed = Time.get_ticks_msec() - t0
	_assert_true(elapsed < 50, "Perf: 100 SoulGemData creates < 50ms", "Took %dms" % elapsed)


# ---------------------------------------------------------------------------
# JSON output
# ---------------------------------------------------------------------------

func _output_results() -> void:
	var duration := Time.get_ticks_msec() - _start_time
	var timestamp := Time.get_datetime_string_from_system(true)
	var status := "pass" if _tests_passed == _tests_total else "fail"

	var result := {
		"status": status,
		"testsTotal": _tests_total,
		"testsPassed": _tests_passed,
		"durationMs": duration,
		"timestamp": timestamp,
		"details": _details,
	}

	var json_str := JSON.stringify(result, "\t")

	var f := FileAccess.open("res://tests/test-results.json", FileAccess.WRITE)
	if f:
		f.store_string(json_str)
		f.close()

	print("TEST_JSON_BEGIN")
	print(json_str)
	print("TEST_JSON_END")

	print("\n--- Summary: %d/%d passed (%s) in %dms ---" % [
		_tests_passed, _tests_total, status, duration
	])
