# Directory Structure

## Root

```
project/
├── .godot/              # Godot engine files (generated)
├── addons/              # Third-party addons
│   └── gdUnit4/         # Test framework
├── assets/              # Imported assets (textures, audio, fonts)
├── data/                # Data-driven resources
├── scenes/              # Godot scenes (.tscn)
├── scripts/             # GDScript source code
├── tests/               # Unit and integration tests
├── export_presets.cfg   # Godot export configuration
├── project.godot        # Godot project file
└── README.md
```

## Assets

```
assets/
├── audio/
│   ├── sfx/             # Sound effects
│   └── music/           # Background music
├── fonts/               # Typography
├── icons/               # UI icons
├── sprites/
│   ├── characters/     # Character artwork
│   ├── enemies/         # Enemy artwork
│   ├── items/           # Item icons
│   ├── relics/          # Relic icons
│   └── ui/              # UI elements, card frames
└── textures/            # Raw textures, atlases
```

## Data

```
data/
├── cards/               # Action card definitions
│   ├── unarmed_attack.tres
│   ├── weapon_attack.tres
│   └── ...
├── consumables/         # Consumable item definitions
├── normal_enemies/      # Normal combat enemy definitions
├── hard_enemies/        # Hard combat enemy definitions
├── bosses/              # Boss definitions per chapter
├── loot_tables/          # Loot drop probability tables
├── maps/                # Map generation parameters
│   ├── chapter1.tres
│   └── ...
├── relics/              # Relic definitions
└── shops/               # Shop generation parameters
```

## Scenes

```
scenes/
├── core/                # Core game flow scenes
│   ├── MainMenu.tscn
│   ├── Game.tscn        # Main game entry point
│   └── PauseMenu.tscn
├── combat/              # Combat system scenes
│   ├── CombatArena.tscn
│   ├── ActionCard.tscn
│   ├── EnemyDisplay.tscn
│   ├── PlayerStatusBar.tscn
│   └── LootScreen.tscn
├── map/                 # Map and navigation scenes
│   ├── MapView.tscn
│   ├── MapNode.tscn
│   └── SafeHouse.tscn
├── backpack/            # Inventory scenes
│   ├── BackpackUI.tscn
│   ├── ItemSlot.tscn
│   └── PocketArea.tscn
├── shop/                # Shop scenes
│   ├── ShopOverlay.tscn
│   └── ShopCard.tscn
├── ui/                  # Shared UI components
│   ├── StaminaBar.tscn
│   ├── DebuffIcon.tscn
│   ├── DamageNumber.tscn
│   └── ConfirmationDialog.tscn
└── screens/             # Full-screen overlays
    ├── DeathScreen.tscn
    ├── VictoryScreen.tscn
    └── GameOverScreen.tscn
```

## Scripts

```
scripts/
├── core/                # Foundation layer (no dependencies upward)
│   ├── card_definitions.gd
│   ├── enemy_definitions.gd
│   ├── item_definitions.gd
│   └── resource_definitions.gd
├── core/                # Core layer (Foundation only)
│   ├── stamina.gd              # Stamina resource tracking
│   ├── inventory.gd            # Backpack & pocket management
│   ├── combat_state.gd          # Combat session state
│   └── map_state.gd             # Map generation & traversal
├── feature/             # Feature layer (Core only)
│   ├── combat/
│   │   ├── combat_manager.gd   # Main combat orchestrator
│   │   ├── action_card.gd      # Action card logic
│   │   ├── damage_calculator.gd # Damage formulas
│   │   ├── enemy_ai.gd         # Enemy behavior
│   │   ├── debuff_handler.gd   # Debuff application
│   │   └── loot_distributor.gd  # Loot selection
│   ├── backpack/
│   │   ├── backpack_manager.gd
│   │   ├── item_organizer.gd    # Auto-arrange logic
│   │   └── item_interactor.gd   # Item usage in combat
│   ├── map/
│   │   ├── map_generator.gd    # Chapter map generation
│   │   ├── node_manager.gd      # Node interaction
│   │   └── path_finder.gd       # Movement logic
│   ├── shop/
│   │   ├── shop_manager.gd     # Shop generation
│   │   └── card_vendor.gd      # Card purchasing
│   ├── survival/
│   │   ├── survivor_notes.gd    # Progression upgrades
│   │   └── relic_handler.gd     # Relic effects
│   └── events/
│       ├── event_manager.gd    # Random events
│       └── chapter_transition.gd
├── game_flow/           # Game Flow layer (Feature only)
│   ├── game_manager.gd          # Composition root
│   ├── adventure_session.gd     # Per-adventure state
│   ├── chapter_progression.gd    # Chapter transitions
│   └── death_handler.gd         # Death & restart
├── ui/                  # Presentation layer (Game Flow only)
│   ├── ui_manager.gd
│   ├── combat_ui/
│   │   ├── combat_interface.gd
│   │   ├── card_hand_display.gd
│   │   └── enemy_health_display.gd
│   ├── map_ui/
│   │   ├── map_renderer.gd
│   │   └── node_tooltip.gd
│   ├── backpack_ui/
│   │   ├── backpack_interface.gd
│   │   └── item_tooltip.gd
│   └── shared/
│       ├── tooltip_manager.gd
│       ├── tween_helper.gd
│       └── sound_manager.gd
└── tests/
    ├── unit/
    ├── integration/
    └── smoke/
```

## Layer Dependency Rules

```
Foundation (core definitions)  ←  Core (state)  ←  Feature (systems)  ←  Game Flow  ←  Presentation

- Foundation: Pure data resources, no game logic
- Core: Basic state management, no complex rules
- Feature: Complete systems with business logic
- Game Flow: Orchestrates features, owns session state
- Presentation: UI only, no game rules
```

## File Naming

| Type | Convention | Example |
| :--- | :--- | :--- |
| Scripts | snake_case.gd | `combat_manager.gd` |
| Scenes | PascalCase.tscn | `CombatArena.tscn` |
| Resources | snake_case.tres | `unarmed_attack.tres` |
| Tests | test_<system>_<behavior>.gd | `test_combat_last_effort.gd` |

## Notes

- All game logic lives in `scripts/` — never in `_ready()` or `_process()` of nodes
- Nodes only: signal connection, `add_child()`, delegating to injected dependencies
- Tests mirror `scripts/` structure under `tests/`
- Asset paths are relative to `res://`