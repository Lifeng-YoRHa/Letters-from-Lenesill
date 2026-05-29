# Ending System

## Overview

The Ending System governs all possible adventure conclusions in Babel Archive. The game features two primary endings — a False Ending and a True Ending — with a branching decision point in Chapter 4 that determines which path the player takes. The True Ending is gated behind collecting all four Survivor's Letters scattered across Chapters 1–4.

**Scope:** All ending conditions, ending screens, narrative payoff, post-ending state (Survivor Notes write, meta-progression), and the Chapter 4 branching decision.

**Key characteristics:**
- **False Ending:** Available when the player has fewer than 4 Survivor's Letters upon reaching the end of Chapter 4, or voluntarily chosen even with 4 letters.
- **True Ending:** Requires collecting all 4 Survivor's Letters and defeating the Final Boss (Origin) in the hidden Final Chapter.
- **Chapter 4 decision point:** The player chooses between "Open and Read" (proceed to True Ending path) or "Fulfill Your Duty" (accept the False Ending).
- **No partial endings:** All other chapter conclusions (1–4 Boss victories) lead to further progression, not termination.

## Detailed Rules

### Definitions

- **Survivor's Letter:** A quest reward obtained by completing the 委托任务 (Commission Quest) in each chapter. Four letters exist, one per chapter. Required for True Ending access.
- **False Ending (假结局):** Adventure conclusion with narrative finality but no resolution of the overarching story. All progress is saved to Survivor Notes; player returns to main menu.
- **True Ending (真结局):** Full narrative resolution. Requires all 4 Survivor's Letters and defeating the Origin Boss in the Final Chapter.
- **Ending Choice Dialog:** A dialog in Chapter 4 that presents the two ending paths when the player has exactly 4 Survivor's Letters.
- **Adventure End:** The moment the player reaches any ending screen — all remaining adventure state is flushed to Survivor Notes and the main menu is shown.

### 1. Ending Types

#### 1.1 False Ending (假结局)

**Trigger conditions (any one):**
- Player defeats Chapter 4 Boss (Numbness) with fewer than 4 Survivor's Letters.
- Player defeats Chapter 4 Boss with exactly 4 Survivor's Letters and chooses "恪尽职守" (Fulfill Your Duty).

**Narrative:**
> [Content to be provided by Narrative Director]

**Consequences:**
1. Loot sequence is **not** presented (no gold, consumables, relics, or keys granted).
2. Survivor Notes are updated with the adventure's statistical record (gold accumulated, nodes visited, Bosses defeated, etc.).
3. Adventure ends. Return to main menu.
4. All in-adventure progress (current chapter, inventory, map state) is **discarded**.
5. Survivor Note **cumulative counters are retained** (e.g., Wayfarer node visits, Hoarder gold, etc.).
6. Survivor Note entry progress is **retained** (no regression).
7. The player may begin a new adventure from Chapter 1.

**Note:** The Witness (见证者) entry is **not** written on a False Ending. Only the True Ending fulfills the "完成一次真正的结局" condition.

#### 1.2 True Ending (真结局)

**Trigger condition:**
- Player has exactly 4 Survivor's Letters in inventory.
- Player chooses "拆封阅读" (Open and Read) at the Chapter 4 ending choice.
- Player progresses through the Final Chapter and defeats the Final Boss (Origin).

**Narrative:**
> [Content to be provided by Narrative Director]

**Consequences:**
1. Full loot sequence is presented (Chapter 4 Boss loot + Final Boss loot).
2. Survivor Notes are updated with the adventure's full statistical record.
3. The Witness (见证者) entry is written: Fading Lantern (暗淡提灯) is unlocked.
4. The Survivor (幸存者) entry is written if not already completed.
5. Adventure ends. Return to main menu.
6. All Survivor Note cumulative counters and entry progress are retained.
7. The player may begin a new adventure from Chapter 1.

### 2. Survivor's Letters

#### 2.1 Letter Acquisition

Each chapter contains one Commission Quest (委托任务) node. Completing the quest grants one Survivor's Letter specific to that chapter:

| Chapter | Letter Name |
| :--- | :--- |
| 1 | 第一封信 (First Letter) |
| 2 | 第二封信 (Second Letter) |
| 3 | 第三封信 (Third Letter) |
| 4 | 第四封信 (Fourth Letter) |

#### 2.2 Letter Properties

- Survivor's Letters are inventory items. They occupy a slot in the backpack grid.
- Letters are **not** consumed during normal gameplay — they persist until the Chapter 4 decision point.
- At the Chapter 4 decision, if the player chooses "Open and Read," **all 4 letters are simultaneously removed** from inventory.
- If the player chooses "Fulfill Your Duty," the letters remain in inventory but have no further use.

#### 2.3 Letter Counting

The system counts Survivor's Letters in inventory at the moment the player reaches the Chapter 4 Boss node. The count is cached at that moment and determines:
- Whether the ending choice dialog appears.
- What loot is granted (if any).

### 3. Chapter 4 Decision Flow

#### 3.1 Flowchart

```
After defeating Numbness (Ch4 Boss):
    │
    ├─► Has 4 Survivor's Letters?
    │       │
    │       ├─ NO:  ──► Trigger False Ending immediately
    │       │            (no loot, no choice dialog)
    │       │
    │       └─ YES: ──► Present loot sequence first
    │                    │
    │                    ▼
    │               Present Ending Choice Dialog:
    │               ├─ "拆封阅读" (Open and Read)
    │               │       └──► Enter Final Chapter
    │               │
    │               └─ "恪尽职守" (Fulfill Your Duty)
    │                       └──► Trigger False Ending
    │                            (letters remain, unused)
```

#### 3.2 Ending Choice Dialog

When the player has 4 Survivor's Letters and completes the loot sequence:

- The dialog displays the narrative context for the choice.
- Two buttons are presented:
  - **拆封阅读 (Open and Read):** Consumes all 4 letters, loads the Final Chapter map.
  - **恪尽职守 (Fulfill Your Duty):** Triggers False Ending immediately.
- The choice is **final and cannot be undone or reversed**.
- The dialog does **not** appear if the player has fewer than 4 letters.

#### 3.3 Loot Before Choice

When the player has 4 letters, the loot sequence (Chapter 4 Boss rewards) is presented **before** the ending choice dialog. This means:
- The player receives Chapter 4 Boss loot even if they subsequently choose "Fulfill Your Duty."
- If the player has fewer than 4 letters, no loot is presented and the False Ending triggers immediately.

### 4. Final Chapter

#### 4.1 Structure

The Final Chapter is a hidden map unlocked only by choosing the True Ending path. It contains 17 nodes:

| Node Type | Count |
| :--- | :--- |
| 起点 (Start) | 1 |
| 区域污染源 (Boss) | 1 |
| 普通战斗 | 2 |
| 艰难战斗 | 1 |
| 突发事件 | 4 |
| 废墟 | 2 |
| 黑市 | 1 |
| 安全屋 | 3 |
| 普通道路 | 2 |

#### 4.2 Progression

- The player enters the Final Chapter immediately after choosing "Open and Read."
- The Final Chapter functions like a normal chapter: the player explores nodes, fights encounters, and accumulates resources.
- The Final Boss (Origin) is located at the final 区域污染源 node.
- There is **no second ending choice** after reaching the Final Boss — defeating Origin grants the True Ending automatically.

#### 4.3 Final Boss (Origin)

| HP | ATK | Starting Debuff | Special Mechanic |
| :--- | :--- | :--- | :--- |
| 300 | 7 | Despair, Trembling | Heal 7 HP per enemy turn; ATK +1/+2/+3 at HP ≤ 180/100/50 |

**Debuff effects:**
- Despair (绝望): Lose 6 stamina at encounter start.
- Trembling (颤抖): 3 random cards cost +1 stamina.

For full Origin mechanics, see Boss and Chapter Transition System.

### 5. Post-Ending State

#### 5.1 Survivor Notes Writes

Upon reaching any ending, the following Survivor Note entries are checked and written if thresholds are met:

| Entry | Condition | Reward |
| :--- | :--- | :--- |
| Survivor (幸存者) | Completed 1 adventure | Heart of Hope unlocked |
| Witness (见证者) | True Ending only | Dim Lantern unlocked |
| All cumulative entries | Thresholds met | Per-entry reward |

#### 5.2 Adventure Statistics Saved

The following statistics from the completed adventure are flushed to the save file:

- Total gold accumulated this adventure (not current gold, but gold ever held)
- Total nodes visited (per type)
- Total damage dealt
- Total combats won
- Chapters reached
- Bosses defeated
- Survivor's Letters obtained

#### 5.3 Return to Main Menu

After any ending:
1. The ending screen displays for a set duration or until the player presses a confirmation button.
2. All adventure state (chapter progress, inventory, map) is cleared from memory.
3. The main menu is shown.
4. A new adventure can be started from Chapter 1.
5. The Optional Carry choice (carry or disable Survivor Note buffs) is presented at the start of the next adventure.

### 6. Ending Screen Content

#### 6.1 False Ending Screen

- Title: 假结局 (False Ending)
- Narrative text (provided by Narrative Director)
- Statistics summary: chapters completed, gold earned, nodes visited
- "Return to Main Menu" button

#### 6.2 True Ending Screen

- Title: 真结局 (True Ending)
- Narrative text (provided by Narrative Director)
- Statistics summary: all chapters completed, final boss defeated, letters collected
- "Return to Main Menu" button

## Formulas

### Chapter 4 Ending Determination

```
letters_held = count_survivor_letters_in_inventory()
if letters_held < 4:
    trigger_false_ending()
    # no loot, no choice dialog
elif letters_held == 4:
    present_loot_sequence()
    show_ending_choice_dialog()
    # player chooses: "Open and Read" -> Final Chapter
    #                 "Fulfill Your Duty" -> False Ending
```

### Loot Presence at Chapter 4

```
if letters_held < 4:
    loot_granted = false
elif letters_held == 4:
    loot_granted = true  # regardless of ending choice made after loot
```

### Letter Consumption on True Ending Path

```
if player_chooses_open_and_read:
    for letter in inventory:
        if letter.type == SURVIVOR_LETTER:
            remove_from_inventory(letter)
    # All 4 letters removed simultaneously
```

### True Ending Unlock Condition

```
true_ending_unlocked = (
    witness_entry_written == false and
    player_has_4_letters == true and
    origin_boss_defeated == true
)
```

## Edge Cases

### E1. Chapter 4 Boss Defeated with 0 Letters

If the player enters Chapter 4 with 0 letters (e.g., skipped or failed all 4 quests):
1. Numbness is defeated.
2. No loot is presented.
3. False Ending triggers immediately.
4. The ending choice dialog does not appear.

### E2. Chapter 4 Boss Defeated with 1–3 Letters

Same as E1 — the False Ending triggers immediately with no loot and no choice dialog. The letters are not consumed and remain in inventory, but the adventure ends nonetheless.

### E3. Choosing "Open and Read" with Fewer Than 4 Letters

This scenario cannot occur. The ending choice dialog only appears when the player has exactly 4 letters. If the player somehow has fewer than 4, the False Ending triggers before any choice is presented.

### E4. Choosing "Fulfill Your Duty" — Letters Remain

When the player chooses "Fulfill Your Duty" with 4 letters:
1. False Ending triggers.
2. All 4 Survivor's Letters remain in inventory (they are **not** consumed).
3. No further use of the letters is possible in this or future adventures.
4. The letters cannot be transferred to a new adventure — adventure state is discarded on ending.

### E5. True Ending — Loot From Both Chapters

When the player completes the True Ending path:
1. After defeating Numbness (Ch4 Boss), Chapter 4 loot is presented (if 4 letters held).
2. After choosing "Open and Read," the Final Chapter loads.
3. After defeating Origin (Final Boss), Final Chapter loot is presented.
4. Both loot sequences must be resolved before the True Ending screen appears.

### E6. Inventory Full at Chapter 4 Loot

If the player's backpack is full when Chapter 4 loot is presented:
1. The Take/Abandon flow requires the player to make space.
2. If the player abandons all loot, the ending choice dialog still appears (the choice is about the ending, not the loot).
3. The ending choice is presented after all loot is resolved.

### E7. Final Chapter — No Further Boss After Origin

The Final Chapter has exactly one Boss node (Origin). Upon defeating Origin:
1. No more nodes are generated.
2. The True Ending screen appears immediately.
3. No further exploration is possible.

### E8. Witness Entry Unlock — Dim Lantern Blocked by False Ending

The Witness entry requires the True Ending. If the player completes multiple False Endings before eventually achieving the True Ending:
- All previous False Endings do not contribute to Witness.
- Only the first True Ending completion writes the Witness entry.

### E9. Survivor Entry Written Before True Ending

The Survivor entry (complete 1 adventure) is written on **any** ending — False or True. The player does not need to complete the True Ending to unlock Heart of Hope, only to finish one full adventure.

### E10. Starting New Adventure After Ending

When the player starts a new adventure after any ending:
1. All adventure state from the previous run is discarded.
2. Survivor Note cumulative counters are retained.
3. Difficulty selection is required (range from 0 to the highest unlocked difficulty level).
4. The Optional Carry choice is presented: carry all Survivor Note buffs or disable them for this run.
5. The player begins from Chapter 1 with base or buffed starting resources.

### E11. False Ending After Many Survivor Note Unlocks

If the player builds up significant Survivor Note progress across multiple False Ending runs and then achieves the True Ending:
- All accumulated progress (entries, stages, unlocks) is retained.
- The Witness entry is written on that True Ending.
- No additional bonus is granted for the number of previous False Endings.

### E12. Loot From Chapter 4 Boss Given Before Choice Dialog

When the player has 4 letters:
1. Loot is presented first.
2. Player takes/abandons items.
3. After loot resolution, the ending choice dialog appears.
4. If player chooses "Fulfill Your Duty," the already-given loot is **kept** — it is not reclaimed.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Boss and Chapter Transition System** | Reads chapter completion state; Chapter 4 Boss defeat triggers ending check; Origin Boss defeat triggers True Ending |
| **Survivor Notes System** | Writes entries (Survivor, Witness) on ending; persists cumulative counters; reads Optional Carry choice |
| **Backpack & Inventory System** | Manages Survivor's Letter inventory slots; handles loot Take/Abandon flow |
| **Node Interaction System** | Commission Quest completion grants Survivor's Letter |
| **Map Generation System** | Final Chapter map generation on True Ending path |
| **Combat System** | Origin Boss combat; final boss defeat triggers ending |
| **Resource System** | Tracks gold accumulated for Survivor Notes |
| **Save/Load System** | Persists adventure statistics on ending; serializes Survivor Note state across sessions |

### Systems That Depend On This

| System | Dependency Detail |
| :--- | :--- |
| **UI / Rendering System** | Renders ending choice dialog, False Ending screen, True Ending screen, loot sequence |
| **Boss and Chapter Transition System** | Reads ending determination to branch Chapter 4 transition; Final Chapter boss triggers True Ending |
| **Survivor Notes System** | Receives adventure statistics to update cumulative counters; writes Witness entry on True Ending |
| **Save/Load System** | Loads Survivor Note state at startup; saves adventure statistics on ending; clears adventure state on ending |
| **Main Menu** | Returns to main menu after any ending is dismissed |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `LETTERS_REQUIRED_FOR_TRUE_ENDING` | 4 | 4 | Survivor's Letters required to access True Ending path |
| `CHAPTER4_LOOT_WITHOUT_LETTERS` | false | — | Whether Chapter 4 Boss drops loot without 4 letters |
| `LETTERS_CONSUMED_ON_TRUE_ENDING` | 4 | 4 | Number of letters consumed when choosing True Ending path |
| `FALSE_ENDING_GIVES_LOOT` | false | — | Whether False Ending presents loot sequence |
| `FINAL_CHAPTER_NODE_COUNT` | 17 | 14–22 | Number of nodes in Final Chapter |
| `ENDING_SCREEN_DISPLAY_TIME` | — | — | Duration (frames or seconds) before player can dismiss ending screen; 0 = player must press button |

## Acceptance Criteria

### AC1. False Ending — Fewer Than 4 Letters
- [ ] Enter Chapter 4 with 2 Survivor's Letters.
- [ ] Defeat Numbness.
- [ ] Verify no loot is presented.
- [ ] Verify False Ending screen appears immediately.
- [ ] Verify no ending choice dialog appears.

### AC2. False Ending — Chosen Manually
- [ ] Enter Chapter 4 with 4 Survivor's Letters.
- [ ] Defeat Numbness.
- [ ] Verify loot is presented first.
- [ ] Complete loot flow.
- [ ] Verify ending choice dialog appears.
- [ ] Choose "恪尽职守" (Fulfill Your Duty).
- [ ] Verify False Ending screen appears.
- [ ] Verify all 4 letters remain in inventory (not consumed).

### AC3. True Ending Path — Loot Before Choice
- [ ] Enter Chapter 4 with 4 Survivor's Letters.
- [ ] Defeat Numbness.
- [ ] Verify loot is presented before the ending choice dialog.
- [ ] Complete loot flow.
- [ ] Verify ending choice dialog appears.
- [ ] Choose "拆封阅读" (Open and Read).
- [ ] Verify all 4 letters are removed from inventory.
- [ ] Verify Final Chapter map loads.

### AC4. True Ending — Final Boss Victory
- [ ] Complete the Final Chapter and defeat Origin.
- [ ] Verify Final Chapter loot is presented.
- [ ] Verify True Ending screen appears.
- [ ] Verify Witness entry is written (Dim Lantern unlocked).

### AC5. Survivor Entry Written on Any Ending
- [ ] Complete a False Ending.
- [ ] Verify Survivor entry is written (Heart of Hope unlocked).
- [ ] Start a new adventure. Verify the relic appears in loot/shop.

### AC6. Survivor Note Counters Persist After False Ending
- [ ] Accumulate 200 gold across an adventure.
- [ ] Complete a False Ending.
- [ ] Verify Hoarder's progress shows 200 gold toward threshold.
- [ ] Start a new adventure. Verify the counter continues from 200.

### AC7. New Adventure After Ending
- [ ] Complete any ending.
- [ ] Return to main menu.
- [ ] Start a new adventure.
- [ ] Verify the Optional Carry dialog appears.
- [ ] Verify Chapter 1 map loads with correct starting resources.

### AC8. Witness Entry Only on True Ending
- [ ] Complete 5 False Endings.
- [ ] Verify Witness entry is NOT written.
- [ ] Complete the True Ending.
- [ ] Verify Witness entry IS written and Dim Lantern is unlocked.

### AC9. Final Chapter — Single Boss
- [ ] Choose "Open and Read" with 4 letters.
- [ ] Complete all nodes in Final Chapter.
- [ ] Verify only one Boss node exists (Origin).
- [ ] Defeat Origin. Verify True Ending triggers with no additional choice.

### AC10. Inventory Full — Loot Take/Abandon
- [ ] Enter Chapter 4 with full inventory and 4 letters.
- [ ] Defeat Numbness.
- [ ] Verify Take/Abandon flow requires making space.
- [ ] Abandon items until loot can be taken.
- [ ] Verify ending choice dialog appears after loot is resolved.