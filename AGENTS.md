# AGENTS.md — AI Agent Context for TCG Battle

## Project Overview

Godot 4.7 2.5D turn-based card battle game. Player vs AI, first to 20 PW wins.

**Language**: GDScript (typed)
**Viewport**: 1600×900, stretch mode `canvas_items`, aspect `keep`
**No external dependencies** — pure Godot + godot-ai MCP plugin

## File Map

```
scripts/
├── Card.gd          # class_name Card — data model (RefCounted)
├── CardsData.gd     # class_name CardsData — static card database
├── DeckBuilder.gd   # class_name DeckBuilder — deck construction
├── Battlefield.gd   # class_name Battlefield — card arrays + PW calc + effects
├── HandManager.gd   # class_name HandManager — hand/deck management
├── TurnManager.gd   # class_name TurnManager — turn flow + AI + effects
├── UIManager.gd     # class_name UIManager — visual rendering (Node)
├── DragSystem.gd    # class_name DraggableCard — drag + tooltip (PanelContainer)
├── ScaleHelper.gd   # — deferred scaling helper (one-shot node)
├── GameConfig.gd    # class_name GameConfig — all tunable constants
├── Home.gd          # — home screen (Node2D)
├── Main.gd          # — battle scene root (Node2D)
└── Settings.gd      # — resolution settings (Control)

scenes/
├── Home.tscn        # Main menu
├── Main.tscn        # Battle scene
└── Settings.tscn    # Settings page

resources/
└── cards_data.gd    # class_name CardsData — 14 unique cards + filler generator
```

## Class Hierarchy

```
RefCounted (no scene tree)
├── Card              # Single card instance
├── CardsData         # Static card definitions
├── DeckBuilder       # Static deck builder
├── Battlefield       # battlefield state
├── HandManager       # hand/deck state
└── TurnManager       # turn logic

Node (scene tree)
├── UIManager         # Visual refresh, card creation
├── DraggableCard     # extends PanelContainer — interactive card
├── ScaleHelper       # extends Node — one-shot deferred scale
└── GameConfig        # class_name — static constants only
```

## Key Data Flow

```
Main._ready()
  → Creates: Battlefield, HandManager, TurnManager, UIManager
  → Calls: turn_manager.start_game()
    → hand_manager.initialize_decks()    # builds 15-card decks
    → hand_manager.draw_initial_hands(3)  # 3 cards each
    → start_turn()                        # begins player turn

Player drags card to battlefield
  → DragSystem._end_drag()
    → turn_manager.play_card_from_hand(card)
      → hand_manager.remove_card_from_hand()
      → battlefield.play_card()
      → _apply_enter_effects(card)       # triggers on_enter effects
      → battlefield.recalculate_all_pw()  # applies all effects
    → UIManager.refresh_all()            # re-renders everything

Turn ends
  → turn_manager.end_turn()
    → current_side switches to AI
    → start_turn() → _do_ai_turn() (deferred)
      → random card played
      → end_turn() → back to player
```

## Effect System

Effects trigger at different times:
- **on_enter**: When card is played from hand (one-shot)
- **timer**: After N turns on battlefield (recurring or one-shot)
- **aura**: Continuous while card is on battlefield
- **musketeer_link**: On every PW recalculation (conditional adjacency)

PW recalculation happens on: play_card, remove_card, turn start.

## Key Patterns

### Card Visual Creation
Cards are NOT scene instances — they're built programmatically:
- `UIManager._create_card_visual()` → wrapper (Control) + shadow (PanelContainer) + card (PanelContainer)
- `DragSystem._build_full_card()` → same structure but full-size for tooltip
- All sizes from `GameConfig.CARD_WIDTH` / `GameConfig.CARD_HEIGHT`

### Deferred Scaling (ScaleHelper)
HBoxContainer resets child scale on add_child. Workaround:
1. Add ScaleHelper child node
2. ScaleHelper waits 1 process_frame
3. Sets parent scale to 0.5x
4. Self-destructs

### Drag Reparenting
DragSystem reparents card to CanvasLayer (layer 100) during drag:
- Cache root reference BEFORE remove_child
- On drop: either play card (queue_free) or return to original parent
- Original position/index cached for return

### Synthetic Event Handling
MCP debugger events don't trigger `_gui_input` or update `get_global_mouse_position()`:
- Use `_input()` for all drag phases
- Store mouse position from `InputEventMouse.position` in `_last_mouse_pos`

## Common Edits

### Change card dimensions
Edit `GameConfig.gd` lines 6-7:
```gdscript
const CARD_WIDTH: int = 200
const CARD_HEIGHT: int = 300
```

### Add a new card
1. Add entry to `CardsData.get_all_cards()` in `resources/cards_data.gd`
2. Add effect handler in `TurnManager._apply_on_enter_effect()` or `_apply_timer_effect()`
3. Add color in `UIManager._get_card_color()` and `DragSystem._get_card_color()`

### Change win condition
Edit `TurnManager.check_win()` — currently `>= 20` PW.

### Modify AI logic
Edit `TurnManager._do_ai_turn()` — currently random card selection.

### Adjust layout proportions
Edit `Main._apply_layout()` — percentage-based positioning relative to viewport height.

## Godot MCP Usage

When using godot-ai tools:
- `game_eval` for runtime inspection
- `script_manage` with `op="find_symbols"` to check parse errors
- `filesystem_manage` with `op="scan"` after file changes
- `editor_screenshot` with `source="game"` for visual verification
- `game_manage` with `op="get_ui_elements"` for UI element positions

## Known Issues

- GDScript reload error code 43 is transient — resolves after filesystem scan
- Unicode in .tscn must use literal UTF-8, not `\uXXXX` escapes
- "Embedded window can't be resized" — expected when running in Godot's embedded viewport
- Settings Apply button only works in standalone F5 window, not embedded
