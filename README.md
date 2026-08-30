# TCG Battle — 2.5D Turn-Based Card Battle Game

A 2.5D turn-based card battle game built with **Godot 4.7** and **GDScript**. Two sides (Player vs AI) take turns playing cards to a battlefield, with the first to reach **20 PW** (Power) winning.

## Quick Start

```
1. Open in Godot 4.7+
2. Press F5 (run Main scene)
3. Click "與 AI 對戰" to start a battle
4. Drag a card from your hand to the battlefield
5. Click "結束回合" to end your turn
```

## Game Rules

- **Win Condition**: First side to reach **20 total PW** on the battlefield wins
- **Turn Structure**: Player → AI → Player → ... (alternating turns)
- **Card Play**: 1 card per turn, drag from hand to battlefield
- **Draw**: 1 card drawn at the start of each turn
- **Starting Hand**: 3 cards each

## Architecture

```
simple-card-2/
├── project.godot              # Godot project config (1600×900, canvas_items stretch)
├── scenes/
│   ├── Home.tscn              # Main menu scene
│   ├── Main.tscn              # Battle scene
│   └── Settings.tscn          # Resolution/fullscreen settings
├── scripts/
│   ├── Card.gd                # Card data model (class_name Card)
│   ├── CardsData.gd           # All card definitions (static data)
│   ├── DeckBuilder.gd         # Deck construction + filler card generation
│   ├── Battlefield.gd         # Battlefield state + PW calculation + effects
│   ├── HandManager.gd         # Hand/deck management + draw mechanics
│   ├── TurnManager.gd         # Turn flow + win check + AI logic + card effects
│   ├── UIManager.gd           # Visual rendering of cards + UI refresh
│   ├── DragSystem.gd          # Card drag-and-drop + hover tooltip
│   ├── ScaleHelper.gd         # Deferred card scaling (HBoxContainer workaround)
│   ├── GameConfig.gd          # Central configuration (all tunable values)
│   ├── Home.gd                # Home screen logic + dynamic layout
│   ├── Main.gd                # Battle scene orchestration + dynamic layout
│   └── Settings.gd            # Resolution change + fullscreen toggle + save/load
└── resources/
    └── cards_data.gd          # Card database (14 unique cards + filler generator)
```

## Script Responsibilities

### Core Game Logic (RefCounted — no scene nodes)

| Script | Class | Purpose |
|--------|-------|---------|
| `Card.gd` | `Card` | Data model: id, name, base_pw, temp_pw, permanent_pw, keywords, effects, owner_side |
| `CardsData.gd` | `CardsData` | Static card database. `get_all_cards()` returns 14 unique cards. `generate_filler_cards(n)` creates basic 3-PW warriors |
| `DeckBuilder.gd` | `DeckBuilder` | Builds 15-card decks from CardsData. Shuffles and fills if fewer than 15 unique cards |
| `Battlefield.gd` | `Battlefield` | Manages player/ai card arrays. Calculates total PW. Applies Musketeer Link and Aura effects on every recalculate |
| `HandManager.gd` | `HandManager` | Manages hands + decks for both sides. Handles draw, remove, deck-empty signals |
| `TurnManager.gd` | `TurnManager` | Turn flow controller. Manages card play (1/turn), win check (20 PW), AI turn (random card), enter/timer effects |

### UI Layer (Node-based)

| Script | Class | Purpose |
|--------|-------|---------|
| `UIManager.gd` | `UIManager` | Creates card visuals (PanelContainer + StyleBoxFlat), refreshes hand/battlefield containers, updates info label, handles game-over dialog |
| `DragSystem.gd` | `DraggableCard` | Extends PanelContainer. Handles drag (CanvasLayer reparent), hover tooltip (smart quadrant positioning), battlefield drop detection |
| `ScaleHelper.gd` | — | One-shot node: waits 1 frame for HBoxContainer layout, applies 0.5x scale, self-destructs |
| `GameConfig.gd` | `GameConfig` | All tunable constants: card dimensions, scaling, fonts, margins, tooltip, deck size, layout |
| `Main.gd` | — | Battle scene root. Creates all managers, wires signals, applies dynamic proportional layout |
| `Home.gd` | — | Main menu. Applies saved resolution on startup, dynamic centered layout |
| `Settings.gd` | — | Resolution picker (4 options), fullscreen toggle, saves to `user://settings.cfg` |

## Card System

### Card Data Structure

```gdscript
{
    "id": "athos",
    "name": "三劍客-阿多斯",
    "base_pw": 2,
    "keywords": ["三劍客"],
    "effect_type": "musketeer_link",
    "effect_params": {},
    "description": "與相鄰三劍客連接時+1 pw"
}
```

### PW Calculation

```
current_pw = base_pw + temp_pw + permanent_pw
```

- `base_pw`: Fixed value from card data
- `temp_pw`: Reset every recalculation (used for conditional buffs)
- `permanent_pw`: Persists across turns (used for irreversible effects)

### Effect Types

| Type | Trigger | Example Card |
|------|---------|--------------|
| `musketeer_link` | On recalculate — adjacent 三劍客 get +1 temp PW each | 阿多斯, 波爾多斯, 阿拉密斯 |
| `on_enter` | When card is played from hand | 法師刺客, 火球法師, 僱傭兵領隊 |
| `timer` | After N turns on battlefield | 沼澤法師 (3 turns), 時光法師 (5 turns) |
| `aura` | Continuous while on battlefield | 護身武器商人 (allies with 0 PW get +1) |

### Card Keywords & Colors

| Keyword | Color | Card Count |
|---------|-------|------------|
| 三劍客 | Red (0.7, 0.2, 0.2) | 3 |
| 法師 | Blue (0.2, 0.3, 0.7) | 3 |
| 刺客 | Dark (0.3, 0.3, 0.4) | 2 |
| 戰士 | Brown (0.5, 0.4, 0.1) | 2 |
| 商人 | Green (0.2, 0.6, 0.3) | 1 |
| 槍手 | Gold (0.6, 0.5, 0.1) | 1 |
| 巫師 | Purple (0.5, 0.2, 0.6) | 1 |
| 召喚物 | Gray (0.4, 0.4, 0.5) | summoned |

## Configuration (GameConfig.gd)

All tunable values are centralized in `GameConfig.gd`. Change values here → entire game updates.

```gdscript
# Card dimensions
const CARD_WIDTH: int = 200
const CARD_HEIGHT: int = 300

# Card scaling
const HAND_SCALE: float = 0.5      # Cards in hand
const BATTLEFIELD_SCALE: float = 0.5  # Cards on battlefield
const HOVER_SCALE: float = 1.0     # Tooltip (full size)

# Card visual
const CARD_CORNER_RADIUS: int = 8
const CARD_CONTENT_MARGIN: int = 10
const CARD_INNER_SEPARATION: int = 8

# Tooltip
const TOOLTIP_GAP: float = 16.0
const TOOLTIP_SHADOW_OFFSET: float = 4.0
const TOOLTIP_BORDER_WIDTH: int = 3

# Layout
const SCENE_MARGIN: float = 20.0
const LABEL_HEIGHT: float = 25.0
const DECK_SIZE: int = 15
```

## Dynamic Layout

All scenes use **percentage-based positioning** that adapts to any resolution:

- **Home**: Title at 8% from top, buttons at 30% from top, centered horizontally
- **Main**: AI Hand (5-12%), AI Battlefield (14-37%), Player Battlefield (53-76%), Player Hand (78-92%)
- **Settings**: Anchored Controls (full_rect, center, etc.)

Viewport: `1600×900` default, stretch mode `canvas_items`, aspect `keep`.

## Settings Persistence

Settings saved to `user://settings.cfg`:
```ini
[display]
width=1600
height=900
fullscreen=false
```

Loaded on Home screen startup via `_apply_saved_settings()`.

## Drag System

The drag system (`DragSystem.gd`) handles:

1. **Drag Start**: Reparents card to CanvasLayer (layer 100), scales to 1.0x
2. **Drag Update**: Follows mouse via `_last_mouse_pos` (works with synthetic events)
3. **Drop Detection**: Checks if drop position is within Player Battlefield zone
4. **Play Card**: Calls `turn_manager.play_card_from_hand()` — if successful, card is freed
5. **Return**: If drop fails or outside battlefield, returns to original hand position

### Hover Tooltip

- On mouse enter: Shows full-size card (1.0x scale) on CanvasLayer (layer 50)
- Smart positioning: Right/below mouse if space available, otherwise left/above
- On mouse exit: Destroys tooltip

### Known Quirks

- `_gui_input` doesn't fire from MCP synthetic events → fallback to `_input()`
- `get_global_mouse_position()` not updated from synthetic events → use `_last_mouse_pos`
- `get_tree().root` null after `remove_child()` → cache root reference before remove
- HBoxContainer resets child `scale` on `add_child` → use ScaleHelper with deferred frame

## AI Behavior

Simple AI: At the start of its turn, waits 1 second, then plays a **random card** from hand (if any). No strategic logic — purely random selection.

## Card List (14 Unique Cards)

| ID | Name | PW | Keywords | Effect |
|----|------|----|----------|--------|
| athos | 三劍客-阿多斯 | 2 | 三劍客 | Adjacent 三劍客 +1 PW |
| porthos | 三劍客-波爾多斯 | 2 | 三劍客 | Adjacent 三劍客 +1 PW |
| aramis | 三劍客-阿拉密斯 | 2 | 三劍客 | Adjacent 三劍客 +1 PW |
| swamp_mage | 沼澤法師 | 0 | 法師 | 3 turns: enemy all -1 permanent PW |
| mage_assassin | 法師刺客 | 2 | 刺客 | Kill enemy 0-PW mage, +1 permanent |
| fireball_mage | 火球法師 | 0 | 法師 | Opposing enemy -4 temp PW |
| armor_merchant | 護身武器商人 | 0 | 商人 | Aura: allies with 0 PW get +1 |
| cannon_commander | 火砲指揮官 | 0 | 槍手 | Damage all enemies by right ally's PW |
| mercenary_leader | 僱傭兵領隊 | 2 | 僱傭兵, 戰士 | Summon 1-PW mercenary |
| bronze_assassin | 銅牌刺客 | 1 | 刺客 | +1 temp to all allies, kill enemy ≤1 PW |
| gladiator | 角鬥士 | 1 | 戰士 | +1 permanent when enemy destroyed (max 6) |
| prayer_warrior | 祝禱戰士 | 1 | 戰士 | Cleanse last ally's debuff, -2 temp all |
| mind_eater | 噬心巫師 | 0 | 巫師 | Attach mind_eat to front enemy |
| time_mage | 時光法師 | 0 | 法師 | 5 turns: +1 permanent each turn |

## Development Notes

- **Engine**: Godot 4.7.2 stable
- **Language**: GDScript (typed, modern style)
- **No external dependencies**: Pure Godot, no plugins (except godot-ai for MCP)
- **All UI is code-generated**: No .tscn UI nodes for cards — everything built via `_create_card_visual()` and `_build_full_card()`
- **class_name used for**: Card, CardsData, DeckBuilder, Battlefield, HandManager, TurnManager, UIManager, DraggableCard, GameConfig
