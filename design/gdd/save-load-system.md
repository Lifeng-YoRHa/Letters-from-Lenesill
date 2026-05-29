# Save/Load System

## Overview

The Save/Load System manages serialization and deserialization of all game state to enable three core capabilities:

1. **Pause-and-Resume**: The player can exit the game mid-adventure and continue from the exact same state later.
2. **Meta-Progression Persistence**: Survivor Notes, cumulative counters, and adventure statistics survive across failed or completed runs.
3. **Adventure State Clearing**: On death or ending, per-adventure state is discarded while meta-progression is preserved.

This system is the single point of persistence for 11 downstream systems. It does not define gameplay logic — it only captures, validates, and restores state.

**Save data is split into two layers:**

| Layer | Scope | Lifetime |
|-------|-------|----------|
| **Adventure Save** | Current run: map graph, node states, inventory, combat state, resources, chapter progress | Created at adventure start; overwritten on every save; deleted on death/ending |
| **Meta Save** | Cross-run: Survivor Notes, cumulative counters, adventure statistics, unlocked endings | Created at first launch; appended on every ending; never auto-deleted |

The system uses Godot's built-in `Resource` serialization (`to_json` / `dict_to_inst` is forbidden; we use `var_to_bytes` and `FileAccess`) for binary save slots. Each save slot is a single file containing both layers.

---

## Detailed Rules

### DR-1. Save Slot Structure

The game supports exactly **3 save slots**, indexed 0-2. Each slot corresponds to a single file:

- Path: `user://save_slot_{N}.dat` where N ∈ {0, 1, 2}
- Format: binary blob written via `FileAccess` + `var_to_bytes`
- Max file size: 1 MB per slot (hard cap; overflows trigger a runtime error)

Each save file contains a `SaveSlotResource` (custom `Resource` class) with this structure:

| Field | Type | Description |
|-------|------|-------------|
| `version` | `int` | Save format version; current = 1 |
| `checksum` | `int` | `hash(adventure_layer + meta_layer)` for tamper detection |
| `last_saved_at` | `int` | Unix timestamp of last write |
| `adventure_layer` | `AdventureStateResource` | Null if no active adventure |
| `meta_layer` | `MetaStateResource` | Always non-null after first launch |

### DR-2. Adventure Layer Contents

The `AdventureStateResource` captures the full state of the current run. It is populated by querying the following systems in order:

1. **Map Generation System**: `map_graph` (Dictionary: node_id → {type, connections[], visibility}) — the graph is frozen at generation time and never regenerated on load.
2. **Node Interaction System**: `node_states` (Dictionary: node_id → enum), `ruins_search_counters` (Dictionary: node_id → int), `quest_flags` (Dictionary: quest_id → bool), `black_market_stock` (Array of item IDs).
3. **Combat System**: `combat_snapshot` — only non-null if the player is inside a combat encounter when saving. Contains: player_hp, active_debuffs[], round_count, enemy_hp, adrenaline_needle_used.
4. **Resource System**: `current_stamina`, `max_stamina`, `current_gold`, `adrenaline_needle_used`.
5. **Backpack Inventory System**: `grid_layout` (2D Array of item IDs or null), `pocket_contents` (Array), `equipped_weapon` (String or null), `held_backpack_type` (String), `pocket_mini_grid_shape` (Vector2i — modified by Magician upgrade).
6. **Relics and Consumables**: `relics` (Array of {relic_id, used, destroyed}), `consumable_counts` (Dictionary: item_id → int).
7. **Boss and Chapter Transition**: `current_chapter` (int, 1–4), `boss_hp` (int, only if chapter boss was damaged and player escaped), `survivors_letter_count` (int, 0–4).
8. **Event System**: `event_assignments` (Dictionary: node_id → event_id) — events are generated once per map and must not change.

### DR-3. Meta Layer Contents

The `MetaStateResource` persists across all adventures. It is appended on every ending, never overwritten in full:

| Field | Type | Written By |
|-------|------|------------|
| `survivor_notes` | `SurvivorNotesState` | Survivor Notes System — full entry states, stage progress, cumulative counters |
| `adventure_statistics` | `Array[AdventureStats]` | Ending System — one entry per completed/failed run |
| `unlocked_endings` | `Array[String]` | Ending System — ending type IDs unlocked so far (`false_ending`, `true_ending`) |
| `unlocked_difficulty_level` | `int` | Difficulty System — max difficulty unlocked (0–40); increments after any ending |
| `first_launch_at` | `int` | Set once at creation |
| `total_play_time_seconds` | `int` | Accumulated from adventure end timestamps minus adventure start timestamps |

### DR-4. Save Trigger Rules

| Trigger | Saves What | Notes |
|---------|-----------|-------|
| Enter any node | Adventure Layer | Lightweight; excludes combat snapshot if not in combat |
| Exit any node | Adventure Layer | Includes any rewards gained |
| Chapter transition | Adventure Layer + Meta Layer | Survivor Notes progress committed to meta |
| Open Pause Menu | Adventure Layer | Snapshot taken before pause UI appears |
| Player selects "Save & Exit" | Adventure Layer + Meta Layer | Full commit; game closes after write confirmation |
| Ending reached | Meta Layer only | Adventure Layer is discarded after successful meta write |
| Death | Meta Layer only | Adventure Layer is discarded after successful meta write |
| Post-combat loot screen close | Adventure Layer | Inventory and resource changes committed |

**Combat mid-save**: If a save trigger fires during combat (e.g., Pause Menu opened), the Combat System must provide a `combat_snapshot`. On load, the game returns to the combat arena with the snapshot restored. The Combat System re-initializes the encounter from the snapshot rather than regenerating the enemy.

### DR-5. Load Rules

1. On game startup, the system scans `user://save_slot_*.dat` for all 3 slots.
2. A slot is considered **valid** only if `version == 1` and `checksum` matches a recalculated hash.
3. A slot with `adventure_layer != null` displays **"Continue"** in the main menu.
4. Selecting **"Continue"** loads the Adventure Layer and Meta Layer, then routes the player to the appropriate scene:
   - If `combat_snapshot != null` → `CombatArena.tscn`
   - If `combat_snapshot == null` → `MapView.tscn` (current chapter map, camera focused on last visited node)
5. Selecting **"New Adventure"** on a slot with an active adventure prompts for overwrite confirmation. If confirmed, the Adventure Layer is replaced with a fresh state; Meta Layer is preserved.
6. Cross-slot Survivor Notes merging is **not supported**. Each slot has its own isolated Meta Layer.

### DR-6. State Clearing Rules

| Event | Adventure Layer | Meta Layer |
|-------|-----------------|------------|
| False ending | Deleted | Appended with stats; `unlocked_endings` updated if first unlock |
| True ending | Deleted | Appended with stats; `unlocked_endings` updated |
| Death (HP = 0) | Deleted | Appended with stats |
| Player abandons run from menu | Deleted | Appended with stats (counts as death) |
| New Adventure on occupied slot | Replaced | Preserved |

The Ending System calls `SaveLoadManager.commit_ending(ending_type, stats)` which:
1. Appends `stats` to `meta_layer.adventure_statistics`
2. Adds `ending_type` to `meta_layer.unlocked_endings` if not present
3. Writes the updated Meta Layer to disk
4. Sets `adventure_layer = null`
5. Writes the slot file again

### DR-7. Validation & Error Handling

- **Checksum mismatch**: Slot is marked **corrupted** and shown as empty in the UI. Meta Layer is not recoverable.
- **Version mismatch**: Slot is rejected with a main-menu error dialog: "Save file incompatible with current game version."
- **Write failure** (disk full, permission denied): Game shows a modal error and does NOT close. The player can retry.
- **Read failure during Continue**: Falls back to main menu with error message; slot is not auto-deleted.

### DR-8. Godot-Specific Serialization Constraints

- All serializable state objects inherit from `Resource` and use `@export` for all fields.
- `Array` and `Dictionary` must be typed: `Array[String]`, `Dictionary[String, int]`, etc.
- Node paths, `Callable`, and lambda references are **never** serialized.
- Texture, AudioStream, and other `Resource` subclasses are serialized by their `res://` path string, not by embedded data.
- Save/load operations run on the main thread; async I/O is not used to avoid Godot `FileAccess` threading issues on Windows.

---

## Formulas

### F-1. Estimated Save File Size

The save file must stay under the 1 MB hard cap. This formula estimates worst-case size:

```
S_total = S_header + S_adventure + S_meta

S_header = 32 bytes  (version + checksum + timestamp + Resource overhead)

S_adventure = S_map + S_nodes + S_combat + S_resources + S_inventory + S_relics + S_boss + S_events

S_map = N_nodes × (4 + 4×AvgConnections + 1)
        Chapter 4 max: 69 nodes × 25 bytes ≈ 1,725 bytes

S_nodes = N_nodes × (4 + 1 + 1 + 4 + 4)
          = 69 × 14 bytes ≈ 966 bytes
          (node_id + state_enum + ruins_counter + quest_flag + black_market_slot)

S_combat = 150 bytes  (player_hp + debuff_array[0..3] + round_count + enemy_hp + flags)

S_resources = 20 bytes  (stamina + max_stamina + gold + flags)

S_inventory = GridW × GridH × 4 + PocketSlots × 4 + 4 + 4 + 8
              = 8×6×4 + 6×4 + 4 + 4 + 8 ≈ 240 bytes

S_relics = MaxRelics × (4 + 1 + 1) + ConsumableTypes × 8
           = 20 × 6 + 15 × 8 ≈ 240 bytes

S_boss = 20 bytes  (chapter + boss_hp + letter_count + ending_choice)

S_events = N_nodes × 8 = 69 × 8 ≈ 552 bytes

S_adventure worst-case ≈ 1,725 + 966 + 150 + 20 + 240 + 240 + 20 + 552 ≈ 3,913 bytes

S_meta = S_notes + S_stats + S_endings + S_difficulty + S_time
         = 2,000 + (Runs × 80) + 16 + 4 + 8
         After 100 runs: ≈ 2,000 + 8,000 + 28 = 10,028 bytes

S_total worst-case ≈ 3,913 + 10,028 + 32 ≈ 13,973 bytes ≈ 13.7 KB
```

**Safety margin**: Even with 1,000 completed runs, the file remains under 100 KB. The 1 MB cap is unreachable under current data budgets and exists only as a runtime sanity check.

| Variable | Definition | Range |
|----------|-----------|-------|
| `N_nodes` | Number of nodes in current chapter map | 36–69 |
| `AvgConnections` | Average outgoing connections per node | 2–4 |
| `GridW`, `GridH` | Backpack grid dimensions | 8×6 (max) |
| `PocketSlots` | Number of pocket item slots | 4–6 |
| `MaxRelics` | Maximum relics player can hold | ≤ 20 |
| `ConsumableTypes` | Distinct consumable item types | ≤ 15 |
| `Runs` | Total completed or failed adventures | 0–∞ (practically < 10,000) |

---

### F-2. Checksum Calculation

```
checksum = hash(adventure_layer_bytes, meta_layer_bytes)

Where:
  hash(a, b) = (murmur3(a) XOR murmur3(b)) & 0x7FFFFFFF
  murmur3 = Godot built-in HashingContext with HASH_MURMUR3

adventure_layer_bytes = var_to_bytes(adventure_layer)
meta_layer_bytes      = var_to_bytes(meta_layer)
```

**Example**: If `adventure_layer_bytes` hashes to `0xA3B5C7D9` and `meta_layer_bytes` hashes to `0x12E4F608`, then:
```
checksum = 0xA3B5C7D9 XOR 0x12E4F608 = 0xB15131D1 = 2,971,078,609 (int32)
```

On load, the system recalculates the hash from the deserialized layers. If `recalculated != stored_checksum`, the slot is marked corrupted.

| Variable | Definition | Range |
|----------|-----------|-------|
| `adventure_layer_bytes` | Binary serialization of AdventureStateResource | Variable |
| `meta_layer_bytes` | Binary serialization of MetaStateResource | Variable |
| `checksum` | 31-bit signed integer (top bit cleared for JSON safety) | 0 – 2,147,483,647 |

---

### F-3. Total Play Time Accumulation

```
total_play_time_seconds += adventure_end_timestamp - adventure_start_timestamp

Where:
  adventure_start_timestamp = Unix timestamp when "New Adventure" is confirmed
  adventure_end_timestamp   = Unix timestamp when EndingSystem calls commit_ending()
```

**Example**: Player starts a run at `2026-05-28T14:00:00Z` (timestamp `1748440800`) and reaches the False ending at `2026-05-28T14:45:30Z` (timestamp `1748443530`):
```
total_play_time_seconds += 1748443530 - 1748440800 = 2,730 seconds (45.5 minutes)
```

This value is **not** incremented during pause-and-resume because the adventure never ended. Only completed or abandoned runs append to total play time.

| Variable | Definition | Range |
|----------|-----------|-------|
| `adventure_start_timestamp` | Unix timestamp at adventure creation | > 1,700,000,000 |
| `adventure_end_timestamp` | Unix timestamp at ending or death | > `adventure_start_timestamp` |
| `total_play_time_seconds` | Cumulative play time across all runs | 0 – 2,147,483,647 |

---

### F-4. Difficulty Level Unlock Progression

```
unlocked_difficulty_level = MAX(unlocked_difficulty_level, completed_difficulty + 1)

completed_difficulty = difficulty_level_of_the_adventure_that_just_ended
```

**Example**: Player completes Difficulty 1 (regardless of False or True ending). Before commit: `unlocked_difficulty_level = 1`. After commit:
```
unlocked_difficulty_level = MAX(1, 1 + 1) = 2
```

The highest available difficulty is capped at 40. Attempting to set a value above 40 writes 40 and logs a warning.

| Variable | Definition | Range |
|----------|-----------|-------|
| `unlocked_difficulty_level` | Highest difficulty the player can select | 0 – 40 |
| `completed_difficulty` | Difficulty level of the run that just ended | 0 – 40 |

---

## Edge Cases

### EC-1. Partial Write / Crash During Save

If the game process crashes between `FileAccess.open()` and `file.close()`, the save file may be partially written. On next load, the checksum will mismatch and the slot is marked corrupted. **Mitigation**: Write to a temporary file (`user://save_slot_{N}.tmp`) first, then atomic-rename to `.dat` on success. If a `.tmp` exists at startup without a matching `.dat`, delete the `.tmp`.

### EC-2. Combat Snapshot with Zero Player HP

If the player dies during an encounter and the death trigger fires before the save system clears the `combat_snapshot`, loading could restore a state where `player_hp == 0` and `combat_snapshot != null`. **Resolution**: The Combat System must validate `player_hp` on load. If `player_hp <= 0`, immediately route to `DeathScreen.tscn` and discard the `combat_snapshot`.

### EC-3. Save File Deleted Externally

If the player deletes a `.dat` file while the game is running, the in-memory slot data remains valid until the next save trigger or restart. **Resolution**: Save operations are fire-and-forget; if `FileAccess` fails to open, show a modal error and do not update the in-memory `last_saved_at`. The slot continues to function in memory but warns the player on exit.

### EC-4. Rapid-Fire Save Triggers

Entering and immediately exiting a node could trigger two saves within the same frame. **Mitigation**: The `SaveLoadManager` implements a 500 ms debounce. Consecutive save requests within the window are coalesced into a single write. The debounce timer resets on every request; the actual write happens 500 ms after the last request.

### EC-5. Game Update Changes Resource Schema

A future patch adds a new field to `AdventureStateResource`. Old save files load with the new field as its default value (`0`, `null`, or `[]` depending on type). **Mitigation**: The `version` field in the header gates this. If `version < current_version`, run a migration function per version delta. If no migration exists, reject the slot (DR-7 version mismatch rule).

### EC-6. Meta Layer Grows Unbounded

After thousands of runs, `adventure_statistics` could become large enough to slow down load times. **Mitigation**: When `adventure_statistics.size() > 500`, the system archives runs 1–250 into a separate `user://save_slot_{N}_archive.dat` file. The active Meta Layer keeps only the most recent 250 entries. Archiving is transparent to the player.

### EC-7. Player Abandons During Boss Escape Recovery

If the player escapes from a boss fight (leaving `boss_hp` partially depleted), then abandons the run from the menu, the `boss_hp` value is never used again. **Resolution**: Abandonment unconditionally discards the Adventure Layer; `boss_hp` is irrelevant. No special handling required.

### EC-8. First Launch with No Meta Layer

When the game launches for the very first time, no save slots exist. **Resolution**: The main menu shows three empty slots. Selecting any slot and starting a "New Adventure" creates the Meta Layer with default values (`unlocked_difficulty_level = 0`, `unlocked_endings = []`, `total_play_time_seconds = 0`) and immediately writes it to disk before entering Chapter 1 map generation.

### EC-9. Load During Godot Import / Reimport

If the player clicks "Continue" while Godot is still reimporting assets (e.g., after an engine update), `Resource` deserialization may fail because `.tres` or `.tscn` dependencies are temporarily invalid. **Resolution**: The save/load system does not run until the `_ready()` of `MainMenu.tscn` completes. The "Continue" button is disabled until `ProjectSettings.has_setting("application/config/features")` is stable.

---

## Tuning Knobs

| Knob | Current Value | Safe Range | Affects |
|------|---------------|------------|---------|
| `SAVE_SLOT_COUNT` | 3 | 1–5 | Number of save slots shown in main menu. Increasing beyond 3 requires UI layout changes. |
| `SAVE_DEBOUNCE_MS` | 500 | 100–2000 | Delay between save request and actual disk write. Lower = more responsive but more I/O; higher = fewer writes but higher crash loss window. |
| `SAVE_MAX_SIZE_BYTES` | 1,048,576 | 524,288–5,242,880 | Hard cap on save file size. Should never be hit with current data budgets. |
| `META_ARCHIVE_THRESHOLD` | 500 | 100–1000 | Number of completed runs before old adventure statistics are archived. Lower = faster loads but more archive files. |
| `META_ARCHIVE_BATCH_SIZE` | 250 | 50–400 | Number of oldest runs moved to archive per archiving pass. Must be < `META_ARCHIVE_THRESHOLD`. |
| `SAVE_VERSION` | 1 | 1–255 | Increment when Resource schema changes. Triggers migration or rejection logic. |
| `CHECKSUM_ALGORITHM` | `HASH_MURMUR3` | `HASH_MURMUR3` only | Do not change without updating all existing save files. |
| `SHOW_SAVE_ICON` | `true` | `true` / `false` | Whether a small disk icon flashes in the corner on auto-save. Useful for debugging save frequency. |

---

## Acceptance Criteria

### AC-1. Pause-and-Resume Round-Trip

**Given**: Player is mid-adventure on Chapter 2, node 15 visited, stamina = 7, gold = 42, inventory has 3 items.
**When**: Player opens Pause Menu → Save & Exit → restarts game → selects Continue.
**Then**: Player returns to MapView on Chapter 2, node 15 is Visited, stamina = 7, gold = 42, inventory unchanged. Load time < 2 seconds.

### AC-2. Combat Mid-Save Recovery

**Given**: Player is in combat round 3, enemy HP = 12, player HP = 8, debuff = Dullness.
**When**: Player presses Esc (Pause Menu) → Save & Exit → restarts game → selects Continue.
**Then**: Player returns to CombatArena at round 3 with identical HP and debuff values. Enemy is the same type with HP = 12.

### AC-3. Death Preserves Meta, Clears Adventure

**Given**: Player has `unlocked_difficulty_level = 2`, `total_play_time_seconds = 3600`, and an active adventure.
**When**: Player dies (HP reaches 0).
**Then**: Main menu shows "Continue" disabled for that slot. Selecting "New Adventure" starts at difficulty selection screen with difficulty 0–2 available. Total play time = 3600 + (this run's duration).

### AC-4. Corrupted Save Detection

**Given**: A save file's checksum byte is manually flipped via hex editor.
**When**: Game starts and scans slots.
**Then**: The corrupted slot appears empty in the main menu. Selecting it shows "New Adventure" only (no Continue).

### AC-5. Difficulty Unlock on False Ending

**Given**: Player starts a run on Difficulty 1 and reaches the False ending.
**When**: Ending sequence completes.
**Then**: `unlocked_difficulty_level` is updated to 2. Starting a new run allows selecting Difficulty 0, 1, or 2.

### AC-6. Difficulty Unlock on True Ending

**Given**: Player starts a run on Difficulty 2 and reaches the True ending.
**When**: Ending sequence completes.
**Then**: `unlocked_difficulty_level` is updated to 3. `unlocked_endings` contains `true_ending`. Starting a new run allows selecting Difficulty 0–3.

### AC-7. New Adventure Overwrite Confirmation

**Given**: Slot 0 has an active adventure (Continue is visible).
**When**: Player selects "New Adventure" on Slot 0.
**Then**: A confirmation dialog appears: "Starting a new adventure will erase your current progress. Survivor Notes and statistics will be preserved. Continue?" If confirmed, a fresh Adventure Layer is created and Meta Layer is retained.

### AC-8. Cross-Slot Isolation

**Given**: Slot 0 has `unlocked_difficulty_level = 3`. Slot 1 is empty.
**When**: Player starts a new adventure on Slot 1.
**Then**: Slot 1's `unlocked_difficulty_level` starts at 0. Slot 0's data is unaffected.

### AC-9. Write Failure Recovery

**Given**: Disk is full or write permission is denied (simulated by marking save directory read-only).
**When**: Any save trigger fires.
**Then**: Game shows modal error: "Unable to save. Please free up disk space and try again." The game does NOT close. The player can dismiss the error and continue playing. The next save trigger retries the write.

### AC-10. Meta Archive Trigger

**Given**: A slot has 499 completed runs in `adventure_statistics`.
**When**: The 500th run ends.
**Then**: Runs 1–250 are transparently moved to `user://save_slot_{N}_archive.dat`. The active Meta Layer retains runs 251–500. Load time does not increase measurably. The player sees no UI change.

---

## Dependencies

### Systems This Depends On

| System | Dependency Reason |
|--------|-------------------|
| Map Generation System | Must understand map graph structure to serialize/deserialize it |
| Node Interaction System | Must understand node state enum and quest flags |
| Combat System | Must understand combat state snapshot format |
| Backpack Inventory System | Must understand grid layout serialization |
| Resource System | Must understand stamina/gold snapshot format |
| Relics and Consumables | Must understand relic used/destroyed flags |
| Boss and Chapter Transition | Must understand chapter progression and escape recovery state |
| Ending System | Must know when to clear adventure state and commit meta-progression |
| Survivor Notes System | Must understand note entry state and stage progress format |
| UI System | Must trigger save on pause/menu exit and show save slot UI |

### Systems That Depend on This

| System | Dependency Reason |
|--------|-------------------|
| Map Generation System | Loads persisted map graph instead of regenerating on resume |
| Node Interaction System | Loads node states, ruins counters, quest flags, Black Market stock |
| Combat System | Loads combat state for pause-and-resume mid-encounter |
| Backpack Inventory System | Loads full inventory layout and pocket state |
| Resource System | Loads stamina, gold, and Adrenaline Needle flag |
| Shop System | Loads Black Market stock from save |
| Relics and Consumables | Loads relic list and consumable counts |
| Boss and Chapter Transition | Loads chapter, Boss HP, Survivor's Letter count, ending choice |
| Ending System | Persists adventure statistics; clears adventure state |
| Survivor Notes System | Loads note states at startup; saves on ending |
| UI System | Displays save slots, load buttons, and "Continue" availability |

