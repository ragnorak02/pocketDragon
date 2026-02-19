# Game Direction — Pocket Dragon (Dragon League)

## Concept

3D isometric dragon-battling RPG. Players explore an overworld, encounter wild dragons and enemies, engage in turn-based combat, and capture dragons using soul gems mounted on a gauntlet.

## Core Pillars

1. **Collect & Bond** — Capture wild dragons with soul gems, build a party of up to 5
2. **Strategic Combat** — Turn-based battles with elemental type advantages (5 elements), abilities, and swapping
3. **Explore & Discover** — Isometric overworld with enemies, wild dragons, and areas to explore

## Element System

| Element | Strong Against | Weak Against |
|---------|---------------|--------------|
| Fire | Ice | Earth, Fire |
| Ice | Earth | Fire, Ice |
| Lightning | — | Lightning, Earth |
| Earth | Fire, Lightning | Ice, Earth |
| Neutral | — | — |

## Capture Mechanics

- Soul gems are equipped in gauntlet slots (max 5)
- Capture probability: `(1 - hp_ratio) * 0.8 / difficulty * gem_bonus`
- Higher tier gems increase capture chance
- Captured dragons join the party (up to max 5)
- Collection bonus: +2% all stats per unique species captured

## Progression

- XP awarded on victory; XP curve: `50 * level^1.5`
- Level cap: 100
- Stats scale from base values per level (defined in DragonData)
- On defeat: heal all and respawn at origin

## Current Dragons

| Name | Element | Role |
|------|---------|------|
| Fire Drake | Fire | Offensive starter |
| Storm Wyvern | Lightning | Speed-based starter |
| Stone Wyrm | Earth | Defensive starter |

## Current Enemies

| Name | Notes |
|------|-------|
| Slime | Basic enemy |
| Goblin | Basic enemy |

## Planned / Open Questions

- Inventory / items beyond soul gems
- Evolution / breeding mechanics
- Multiplayer / trading
- Audio design (no audio assets yet)
- Save file persistence (serialization exists, file I/O does not)
- Cutscene system (state exists, no implementation)

### Graphics Pass V1 — 2026-02-18
- Replaced 19 primitive/placeholder visuals with improved assets
- Added toon shading (rim lighting, cel shading) to all entity models
- Added jelly wobble shader for slime enemies
- Added procedural terrain shader (noise grass/dirt blend) for overworld ground
- Added wind sway shader for tree canopies
- Added procedural rock and cobblestone path shaders
- Added animated arena floor (glowing runes) and rotating arena ring shaders
- Added animated dark fantasy backgrounds for main menu and starter selection
- Added portal energy swirl shader with CPUParticles3D
- Added dragon element aura particles (CPUParticles3D ring)
- Added battle impact burst particles and camera shake
- Added idle bob animations to enemies, NPCs, and battle models
- Extracted shared ModelFactory utility (DRYed 3x dragon model duplication)
- Added horns and mouth details to dragon/slime models
- Animation cycles added for: all entities (idle bob), slime (jelly wobble), trees (wind sway)
- Techniques used: Shader (11 files), Particle (3 systems), Material, Programmatic
- Asset stage: placeholder_v1 (swap-ready for final art)

### Controller Support + Dragon Card Fix — 2026-02-19
- Fixed starter selection dragon cards not rendering (removed stale `class_name ModelFactory` from `utils/model_factory.gd`, removed invalid `theme_override_constants` property)
- Added Xbox controller bindings to all input actions in `project.godot` (D-pad, left stick, A/B/Start)
- Added new `ui_cancel`, `ui_up/down/left/right` input actions with keyboard + joypad events
- Added D-pad left/right card navigation + A button confirm to starter selection screen
- Main menu already works via Godot focus system — just needed the joypad bindings
- Controller support status: partial (menus + starter selection + overworld movement)
