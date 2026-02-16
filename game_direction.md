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

- World map / zone system (currently one flat overworld)
- NPC / dialog system (EventBus has `dialog_requested` signal, unused)
- Inventory / items beyond soul gems
- Evolution / breeding mechanics
- Multiplayer / trading
- Audio design (no audio assets yet)
- Save file persistence (serialization exists, file I/O does not)
- Cutscene system (state exists, no implementation)
