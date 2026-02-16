# Test Plan — Pocket Dragon

## Status: No Tests Implemented Yet

No test framework (GUT, GdUnit4, etc.) is currently installed. This plan documents what should be tested as the project grows.

## Recommended Framework

**GdUnit4** or **GUT** (Godot Unit Testing) — both integrate with Godot 4.x.

## Priority Test Areas

### P0 — Core Battle Math
- [ ] `TypeChart.get_multiplier()` — all 25 element combinations return correct values
- [ ] `BattleManager._calculate_damage()` — power/atk/def/type_mult formula produces expected ranges
- [ ] Capture probability formula — boundary cases (full HP, 1 HP, various gem tiers)
- [ ] XP curve — `DragonInstance.get_xp_to_next_level()` at key levels (1, 10, 50, 100)
- [ ] Level-up — `DragonInstance.add_xp()` correctly levels up and caps at 100

### P1 — Party & State Management
- [ ] `PartyManager.add_dragon()` — respects MAX_PARTY_SIZE (5)
- [ ] `PartyManager.remove_dragon()` — adjusts active_dragon_index correctly
- [ ] `PartyManager.get_collection_bonus()` — scales with unique species count
- [ ] `PartyManager.get_best_available_gem()` — returns highest tier unoccupied gem
- [ ] `GameManager.change_state()` — emits signal, updates previous_state
- [ ] `PartyManager.heal_all_dragons()` — restores HP and MP to max

### P2 — Serialization
- [ ] `DragonInstance.serialize()` → `DragonInstance.deserialize()` round-trip preserves all fields
- [ ] `PartyManager.get_save_data()` / `load_save_data()` round-trip
- [ ] Edge case: empty party, full party, null gems

### P3 — Battle Flow
- [ ] Turn order: higher AGI goes first
- [ ] Player defeat → auto-swap to alive dragon (or defeat if none)
- [ ] Flee: 60% chance, correct behavior on success/failure
- [ ] Capture: wild dragons only, gem consumed on success
- [ ] MP deduction on ability use, fallback to basic attack if insufficient

### P4 — Integration / Smoke Tests
- [ ] Main menu → starter selection → overworld scene flow
- [ ] Battle start → action → victory → return to overworld
- [ ] Pause menu open/close restores game state

## Running Tests (Future)

```bash
# Once GUT or GdUnit4 is installed:
godot --headless --script addons/gut/gut_cmdln.gd
```
