# Pocket Dragon (Dragon League) — Claude Code Project Intelligence

## Project Overview

**Engine:** Godot 4.4 (GDScript, 3D isometric)
**Genre:** Dragon-battling RPG with soul gem capture mechanics
**Viewport:** 1920x1080, forward_plus renderer
**Main Scene:** `res://scenes/main/main.tscn`

## Architecture

### Autoloads (Singletons)
| Name | File | Purpose |
|------|------|---------|
| EventBus | `autoload/event_bus.gd` | Global signal bus for decoupled communication |
| GameManager | `autoload/game_manager.gd` | Game state machine (MAIN_MENU, STARTER_SELECTION, OVERWORLD, BATTLE, PAUSED, CUTSCENE) |
| PartyManager | `autoload/party_manager.gd` | Dragon party (max 5), soul gems (max 5), collection tracking |
| BattleManager | `autoload/battle_manager.gd` | Turn-based battle state machine, damage calc, capture logic |
| DebugOverlay | `autoload/debug_overlay.gd` | FPS/state display, toggle with F3 |

### Data Layer (`data/`)
- `DragonData` — Immutable species template (Resource)
- `DragonInstance` — Mutable owned dragon (Resource with serialize/deserialize)
- `AbilityData` — Ability stats (element, power, MP cost)
- `EnemyData` — Non-dragon enemy stats
- `SoulGemData` — Capture gem tiers
- `TypeChart` — Static 5-element effectiveness matrix (fire, ice, lightning, earth, neutral)

### Scene Structure
```
scenes/
  main/          — Root scene, handles scene transitions
  main_menu/     — Title screen
  starter_selection/ — Pick 1 of 3 starter dragons
  overworld/     — 3D isometric world with player, enemies, wild dragons
  battle/        — Battle arena + HUD (turn-based combat)
  hud/           — Game HUD (party display, interaction prompts, pause menu)
```

### Components
- `HealthComponent`, `StatsComponent` — Reusable node components
- `StateMachine` / `State` — Generic FSM (base class with pass stubs)

### Input Map
- WASD — Movement (isometric-rotated 45 deg)
- E — Interact
- Escape — Menu/Pause
- F3 — Debug overlay toggle

## Coding Conventions
- GDScript with type hints where practical
- Signals routed through EventBus (never direct node references between systems)
- UI built procedurally in GDScript (no .tscn for UI panels)
- All battle logic in BattleManager; BattleArena owns only visuals
- Resources (.tres) for data; scenes (.tscn) for entities and levels
- Print statements use `[SystemName]` prefix format for debug logging

## Current Repo State (Auto-Detected)

- **Placeholder 3D models:** All dragon/enemy visuals are CSG primitives — no real meshes or art assets exist
- **Empty `assets/` directory:** No textures, audio, models, or VFX have been added yet
- **All UI is procedural code:** Battle HUD, menus, and HUD built entirely in GDScript with hardcoded pixel positions (no .tscn UI)
- **State base class is stubs:** `state.gd` has empty `pass` methods for enter/exit/update/physics_update
- **Save system incomplete:** `serialize()`/`deserialize()` methods exist on DragonInstance but no file I/O is wired up
- **CUTSCENE state unused:** Defined in GameManager enum but no scene or logic references it
- **No test suite:** No test directory, no GUT/GdUnit setup, no test files
- **Hardcoded spawns:** Overworld enemy/dragon positions are hardcoded Vector3 arrays, no map data system
- **No audio:** Zero sound effects or music files
- **Prototype stage (v0.1):** Debug overlay self-labels as "Dragon League v0.1"

## Build & Run

```bash
# Open in Godot editor
godot --editor --path .

# Run from CLI
godot --path .
```

## Key File Quick Reference

| What | Where |
|------|-------|
| Game state machine | `autoload/game_manager.gd` |
| Battle logic | `autoload/battle_manager.gd` |
| Party/gems/saves | `autoload/party_manager.gd` |
| Signal definitions | `autoload/event_bus.gd` |
| Type chart | `data/type_chart.gd` |
| Player movement | `entities/player/player.gd` |
| Dragon species data | `data/dragons/*.tres` |
| Ability data | `data/abilities/*.tres` |
