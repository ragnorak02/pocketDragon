# Test Plan — Pocket Dragon

## Status: 116/116 Tests Passing

Custom headless test runner (`tests/run_tests.gd`) — no external framework needed.

## Running Tests

```bash
# Via batch script (recommended):
tests\run-tests.bat

# Direct Godot:
godot --headless --path . --script res://tests/run_tests.gd
```

Output: JSON to `tests/test-results.json` + stdout markers.

## Covered Test Areas

### P0 — Core Battle Math (Done)
- [x] `TypeChart.get_multiplier()` — all element combinations (super-effective, not-effective, neutral, invalid)
- [x] `TypeChart.get_effectiveness_text()` — display strings for 2.0/0.5/1.0
- [x] `TypeChart.get_element_color()` — color lookups + invalid fallback
- [x] XP curve formula — `50 * level^1.5` verified at levels 1, 10, 50, 100
- [x] DragonData stat scaling — `base + growth * (level-1)` at multiple levels

### P0 — Data Integrity (Done)
- [x] All 3 dragon species load and have correct id/element
- [x] All 8 abilities load with valid id/power/mp_cost
- [x] All 2 enemy types load with valid stats
- [x] Both soul gem tiers load with correct tier/capture_bonus
- [x] Soul gem tier names (Common, Rare, Legendary, Unknown)
- [x] Soul gem serialization round-trip

### P1 — Serialization (Done)
- [x] `DragonInstance.serialize()` produces expected 6 keys
- [x] `DragonInstance.deserialize()` reads level, xp, nickname, defaults current_hp

### P1 — Scene & Asset Loading (Done)
- [x] All 10 scenes load as PackedScene (main, menu, starter, battle, overworld, player, enemy, dragon, portal, npc)
- [x] All 3 zone data resources exist (meadow, forest, cave)
- [x] All 4 NPC data resources exist (old_ranger, herbalist, forest_scout, cave_hermit)
- [x] All 12 core scripts load without error

### P2 — Performance (Done)
- [x] 1000 TypeChart lookups < 50ms
- [x] 10 resource loads < 500ms
- [x] 100 SoulGemData creates < 50ms

## Not Yet Covered

### P1 — Party & State Management
- [ ] `PartyManager.add_dragon()` — respects MAX_PARTY_SIZE (5)
- [ ] `PartyManager.remove_dragon()` — adjusts active_dragon_index correctly
- [ ] `PartyManager.get_collection_bonus()` — scales with unique species count
- [ ] `PartyManager.get_best_available_gem()` — returns highest tier unoccupied gem
- [ ] `GameManager.change_state()` — emits signal, updates previous_state
- [ ] `PartyManager.heal_all_dragons()` — restores HP and MP to max

### P2 — Battle Flow
- [ ] Turn order: higher AGI goes first
- [ ] Player defeat — auto-swap to alive dragon (or defeat if none)
- [ ] Flee: 60% chance, correct behavior on success/failure
- [ ] Capture: wild dragons only, gem consumed on success
- [ ] MP deduction on ability use, fallback to basic attack if insufficient
- [ ] `BattleManager._calculate_damage()` — power/atk/def/type_mult formula

### P3 — Integration / Smoke Tests
- [ ] Main menu -> starter selection -> overworld scene flow
- [ ] Battle start -> action -> victory -> return to overworld
- [ ] Pause menu open/close restores game state

### P3 — Save System
- [ ] `PartyManager.get_save_data()` / `load_save_data()` round-trip
- [ ] Edge case: empty party, full party, null gems
- [ ] File I/O write and read back

## Notes
- Tests run headless via `extends SceneTree` — no editor needed
- DragonInstance can't be instantiated headless (EventBus autoload dependency) — tested indirectly via formulas and DragonData
- Last run: 2026-02-18 — 116/116 pass, 81ms
