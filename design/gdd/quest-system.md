# Quest System

## Overview

The Quest System manages **4 Commission Quests** (委托任务), one per chapter (Chapters 1–4). In each chapter, a委托人 (client) has lost a letter and asks the player to retrieve it.

After accepting a quest, the player must explore the current chapter's map to find the **Lost Letter** (遗失的信件), then return it to the client at the **Quest Node**. Upon completion, the Quest Node transforms into a **Normal Road** node, and the player receives a reward (choose 2 out of 5 options) plus one **Survivor's Letter** (幸存者的信件).

Collecting all 4 Survivor's Letters is the **mandatory condition** for accessing the True Ending.

**Key design principle**: Quests are optional in execution but mandatory for the True Ending. If the player leaves a chapter without completing its quest, the quest fails silently with no reward or penalty.

---

## Detailed Rules

### DR-1. Quest Node Placement

Each chapter's map contains exactly one Quest Node. It is a special node placed by the Map Generation System with a fixed position per chapter variant.

The client permanently resides at the Quest Node. The node does not use the standard `Unexplored → Revealed → Visited → Cleared` flow; instead:
- Before quest completion: behaves as a Quest Node
- After quest completion: **transforms into a Normal Road node**

### DR-2. Quest Acceptance

When the player arrives at a Quest Node:
1. Quest dialog opens automatically.
2. Dialog displays quest text and 3 buttons: **Accept** / **Come Back Later** / **Decline**.
3. **If Decline**: The node **transforms into a Normal Road node**. No quest is added to the active log. The client leaves and cannot be revisited.
4. **If Accept**: The quest is added to the active quest log. The Lost Letter spawn process begins (see DR-3).
5. **If Come Back Later**: The node **remains a Quest Node** but its interaction state becomes `Cleared`. The player can return later in the same adventure to accept the quest. No Lost Letter spawns until acceptance.

A player can have **at most one active quest at a time** because chapter transitions clear unfinished quests.

### DR-3. Lost Letter Spawn Rules

Upon quest acceptance, the Lost Letter is spawned in the current chapter according to the following probability distribution:

| Node Type | Probability | Acquisition Method |
| :-------: | :---------: | :---------------- |
| 艰难战斗 | 70% | Drops as combat victory loot; equal chance across all Hard Combat nodes |
| 黑市 | 15% | Sold as merchandise; the Black Market gains one extra item slot; equal chance across all Black Market nodes |
| 安全屋 | 10% | Automatically obtained upon entering the Safe House; equal chance across all Safe House nodes |
| 普通战斗 | 5% | Drops as combat victory loot; equal chance across all Normal Combat nodes |

If the Lost Letter spawns in a Black Market, its price is:

| Chapter | Price (Gold) |
| :-----: | :----------: |
| 1 | 18 |
| 2 | 29 |
| 3 | 40 |
| 4 | 52 |

The Lost Letter occupies **1×1 grid space** in the backpack. It cannot be sold, dropped, or consumed.

### DR-4. Lost Letter Removal on Chapter Transition

When the player transitions to the next chapter (by defeating the Chapter Boss or escaping):
- Any Lost Letter in the backpack is **automatically removed**.
- If the player had an active quest, it **fails silently**.
- No reward or penalty is applied for the failed quest.

This rule applies even if the player is carrying the Lost Letter but has not yet returned it to the client.

### DR-5. Quest Completion and Rewards

The player returns the Lost Letter to the client at the Quest Node. Upon hand-in:

1. The Lost Letter is removed from inventory.
2. The Quest Node **transforms into a Normal Road node**.
3. The player receives a **Survivor's Letter** (1×1 item, cannot be sold or dropped).
4. The player chooses **2 rewards** from the following 5 options:

#### Option A: 信物 (Relic)
- Chapter 1 or 2 quest: **1 relic**
- Chapter 3 or 4 quest: **2 relics**
- Only relics that are **not yet obtained in the current adventure** and **already unlocked** can appear.
- All eligible relics have **equal probability**.

#### Option B: 金币 (Gold)
- Chapter 1: **22 gold**
- Chapter 2: **33 gold**
- Chapter 3: **44 gold**
- Chapter 4: **55 gold**

#### Option C: 武器 (Weapon)
- Any **weapon not yet obtained in the current adventure** and **already unlocked** can appear.
- All eligible weapons have **equal probability**.
- The weapon is added to inventory.

#### Option D: 背包 (Backpack)
- Any **backpack not yet obtained in the current adventure** and **already unlocked** can appear.
- All eligible backpacks have **equal probability**.
- The backpack is added to inventory (or replaces the current one if the player chooses to equip it immediately).

#### Option E: 消耗品 (Consumables)
- Chapter 1: **4 items**
- Chapter 2: **6 items**
- Chapter 3: **9 items**
- Chapter 4: **11 items**

Each item is drawn independently from the following probability table:

| Consumable | Probability |
| :--------: | :---------: |
| 磨刀石 | 22% |
| 石块 | 11% |
| 能量饮料 | 29% |
| 手电筒 | 15% |
| 火把 | 17% |
| 安全屋房卡 | 6% |

### DR-6. Survivor's Letter Properties

- **Size**: 1×1 grid cell
- **Stackable**: Yes
- **Sellable**: No
- **Droppable**: No
- **Usable**: Only at the Chapter 4 decision point (see DR-7)
- **ID format**: `survivor_letter_ch{N}` where N ∈ {1, 2, 3, 4}

The Quest System maintains a `survivors_letter_count` (0–4) that is exposed to the Ending System and Save/Load System. On load, the system reconciles this counter against the actual inventory contents.

### DR-7. Chapter 4 Decision Integration

After defeating the Chapter 4 Boss (区域污染源), the Ending System queries `survivors_letter_count`.

| Letter Count | Behavior |
| :----------: | :------- |
| 0–3 | **False Ending triggers automatically**. No player choice. Letters remain in inventory. |
| 4 | **Choice dialog appears** with two options: |
| | **拆封阅读 (Open and Read)** → All 4 letters are removed from inventory. Player enters the Final Chapter. Defeating the Final Boss leads to the True Ending. |
| | **恪尽职守 (Fulfill Your Duty)** → Letters remain in inventory. False Ending plays. |

If the player chooses "Open and Read" and dies in the Final Chapter, the letters are **not restored**. The player must start a new adventure and re-collect all 4 letters.

### DR-8. Quest State Persistence

Quest state is part of the Adventure Layer:

- `active_quest_id`: String or null
- `active_quest_state`: enum `None` / `InProgress` / `Completed`
- `lost_letter_location_node_id`: String or null (where the Lost Letter spawned)
- `lost_letter_acquired`: bool
- `quest_node_transformed`: bool (whether the Quest Node has become a Normal Road)

The Save/Load System serializes this state. On load, if `quest_node_transformed == true`, the Quest Node is restored as a Normal Road node.

---

## Formulas

### F-1. Lost Letter Spawn Probability

```
roll = random_float(0.0, 1.0)

if roll < 0.70:
    spawn_type = HardCombat
elif roll < 0.85:
    spawn_type = BlackMarket
elif roll < 0.95:
    spawn_type = SafeHouse
else:
    spawn_type = NormalCombat

eligible_nodes = filter(chapter_nodes, spawn_type)
spawn_node = random_choice(eligible_nodes)
```

| Variable | Definition | Range |
| :------- | :--------- | :---- |
| `roll` | Random float for spawn type selection | 0.0–1.0 |
| `spawn_type` | Node type where Lost Letter appears | HardCombat / BlackMarket / SafeHouse / NormalCombat |
| `eligible_nodes` | Nodes of the selected type in current chapter | 1–19 |

---

### F-2. Black Market Price Scaling

```
lost_letter_price = 7 + (chapter_number × 11) + floor((chapter_number - 1) × 0.5)
```

Simplified to the fixed values in the design doc:

| Chapter | Price |
| :-----: | :---: |
| 1 | 18 |
| 2 | 29 |
| 3 | 40 |
| 4 | 52 |

| Variable | Definition | Range |
| :------- | :--------- | :---- |
| `chapter_number` | Current chapter | 1–4 |
| `lost_letter_price` | Gold cost in Black Market | 18–52 |

---

### F-3. Gold Reward per Quest

```
quest_gold_reward = 11 + (chapter_number × 11)
```

| Chapter | Calculation | Reward |
| :-----: | :---------- | :----: |
| 1 | 11 + (1 × 11) | 22 |
| 2 | 11 + (2 × 11) | 33 |
| 3 | 11 + (3 × 11) | 44 |
| 4 | 11 + (4 × 11) | 55 |

| Variable | Definition | Range |
| :------- | :--------- | :---- |
| `chapter_number` | Chapter where quest was completed | 1–4 |
| `quest_gold_reward` | Gold granted if "金币" is chosen as reward | 22–55 |

---

### F-4. Consumable Reward Count

```
consumable_count = floor(2.75 × chapter_number + 1.25)
```

| Chapter | Calculation | Count |
| :-----: | :---------- | :---: |
| 1 | floor(2.75 × 1 + 1.25) = floor(4.0) | 4 |
| 2 | floor(2.75 × 2 + 1.25) = floor(6.75) | 6 |
| 3 | floor(2.75 × 3 + 1.25) = floor(9.5) | 9 |
| 4 | floor(2.75 × 4 + 1.25) = floor(12.25) | 11 |

| Variable | Definition | Range |
| :------- | :--------- | :---- |
| `chapter_number` | Chapter where quest was completed | 1–4 |
| `consumable_count` | Number of consumables granted if "消耗品" is chosen | 4–11 |

---

### F-5. Relic Reward Count

```
relic_count = 1 if chapter_number <= 2 else 2
```

| Chapter | Count |
| :-----: | :---: |
| 1 | 1 |
| 2 | 1 |
| 3 | 2 |
| 4 | 2 |

---

### F-6. True Ending Accessibility

```
true_ending_accessible = (survivors_letter_count == 4)
```

No randomness. The player either has all 4 letters or does not.

---

## Edge Cases

### EC-1. Player Declines Quest

**Scenario**: Player arrives at the Quest Node and clicks Decline.
**Result**: The node transforms into a Normal Road node. The client leaves permanently. The quest cannot be accepted in this adventure. No Lost Letter spawns.

### EC-2. Player Chooses Come Back Later

**Scenario**: Player arrives at the Quest Node and clicks Come Back Later.
**Result**: The node remains a Quest Node, but its interaction state becomes `Cleared`. The player can leave and return later in the same adventure to accept the quest. No Lost Letter spawns until the player clicks Accept.

### EC-3. Player Has Full Inventory When Lost Letter Drops

**Scenario**: The player's backpack has zero free 1×1 cells when the Lost Letter would be added (e.g., as combat loot or Safe House auto-grant).
**Result**: The Lost Letter is **not** added. A "backpack full" notification appears. For combat drops, the loot screen shows the Lost Letter grayed out with a lock icon. For Safe House, the player enters the Safe House but does not receive the letter. The spawn node retains the Lost Letter; the player can return after freeing space to collect it.

### EC-4. Player Buys Lost Letter from Black Market With Insufficient Gold

**Scenario**: The Lost Letter spawns in a Black Market, but the player cannot afford it.
**Result**: The letter remains in the Black Market's extra slot. The player can return after earning more gold. The Black Market stock is saved with the letter still present.

### EC-5. Player Defeats Chapter Boss With Active Quest

**Scenario**: Player defeats the Chapter Boss, triggering a chapter transition.
**Result**: The active quest is silently failed. The Lost Letter is automatically removed from inventory. No reward is granted. The player advances to the next chapter.

**Note**: Escaping from the Chapter Boss fight does **not** trigger a chapter transition. The player remains in the current chapter and can continue the quest.

### EC-6. Save/Load During Active Quest

**Scenario**: Player has accepted the quest, found the Lost Letter, but not yet returned it. They save and exit.
**Result**: On load, the active quest is still `InProgress`. The Lost Letter is in inventory. The Quest Node remains untransformed. The player can return to hand it in.

### EC-7. Player Collects All 4 Letters, Then Dies in Final Chapter

**Scenario**: Player chooses "Open and Read" at Chapter 4, enters Final Chapter, but dies.
**Result**: Death clears the Adventure Layer. The 4 letters are gone. `survivors_letter_count` resets to 0. The player must re-collect all 4 letters in a new adventure.

### EC-8. Quest Node Transformed on Load

**Scenario**: Player completes the quest, the node transforms to Normal Road, then saves and exits.
**Result**: On load, the node is restored as a Normal Road node. Interacting with it shows Normal Road behavior (no quest dialog, no client present).

### EC-9. Player Has 4 Letters Before Chapter 4 Boss

**Scenario**: Player somehow collects all 4 letters before defeating the Chapter 4 Boss (e.g., through future design changes or exploits).
**Result**: The Chapter 4 Boss defeat still triggers the standard choice dialog. The system does not special-case early collection.

---

## Dependencies

### Systems This Depends On

| System | Dependency Reason |
| :----- | :---------------- |
| Map Generation System | Must place the Quest Node at a fixed position per chapter variant |
| Node Interaction System | Must handle Quest Node arrival trigger and transformation to Normal Road |
| Combat System | Must drop Lost Letter as loot on Hard Combat (70%) and Normal Combat (5%) victory |
| Shop System | Must add Lost Letter to a Black Market's extra slot (15%) with chapter-scaled price |
| Safe House System | Must grant Lost Letter automatically on entry (10%) |
| Backpack Inventory System | Must check space before granting Lost Letter; must remove it on hand-in or chapter transition |
| Resource System | Must add gold reward if chosen |
| Relics and Consumables | Must provide eligible relics/consumables for reward selection |
| Ending System | Must query `survivors_letter_count` at Chapter 4 Boss defeat; must consume letters on "Open and Read" |
| Save/Load System | Must persist quest state, Lost Letter location, and node transformation flag |

### Systems That Depend on This

| System | Dependency Reason |
| :----- | :---------------- |
| Ending System | Uses `survivors_letter_count` to branch between False Ending and True Ending choice |
| Save/Load System | Serializes quest state as part of Adventure Layer |
| Node Interaction System | Quest Node behavior is driven by Quest System state; post-completion transforms to Normal Road |
| Map Generation System | Receives confirmation that Quest Node placement is accepted |

---

## Tuning Knobs

| Knob | Current Value | Safe Range | Affects |
| :--- | :------------ | :--------- | :------ |
| `LOST_LETTER_HARD_COMBAT_CHANCE` | 70% | 50–85% | Probability of Lost Letter spawning as Hard Combat loot |
| `LOST_LETTER_BLACK_MARKET_CHANCE` | 15% | 5–25% | Probability of Lost Letter spawning in a Black Market |
| `LOST_LETTER_SAFE_HOUSE_CHANCE` | 10% | 5–20% | Probability of Lost Letter spawning in a Safe House |
| `LOST_LETTER_NORMAL_COMBAT_CHANCE` | 5% | 0–15% | Probability of Lost Letter spawning as Normal Combat loot |
| `LOST_LETTER_PRICE_CH1` | 18 | 10–30 | Black Market price in Chapter 1 |
| `LOST_LETTER_PRICE_CH2` | 29 | 20–40 | Black Market price in Chapter 2 |
| `LOST_LETTER_PRICE_CH3` | 40 | 30–50 | Black Market price in Chapter 3 |
| `LOST_LETTER_PRICE_CH4` | 52 | 40–65 | Black Market price in Chapter 4 |
| `QUEST_GOLD_CH1` | 22 | 15–30 | Gold reward if chosen for Chapter 1 |
| `QUEST_GOLD_CH2` | 33 | 25–40 | Gold reward if chosen for Chapter 2 |
| `QUEST_GOLD_CH3` | 44 | 35–55 | Gold reward if chosen for Chapter 3 |
| `QUEST_GOLD_CH4` | 55 | 45–70 | Gold reward if chosen for Chapter 4 |
| `QUEST_CONSUMABLE_CH1` | 4 | 3–6 | Consumable count if chosen for Chapter 1 |
| `QUEST_CONSUMABLE_CH2` | 6 | 4–8 | Consumable count if chosen for Chapter 2 |
| `QUEST_CONSUMABLE_CH3` | 9 | 6–12 | Consumable count if chosen for Chapter 3 |
| `QUEST_CONSUMABLE_CH4` | 11 | 8–15 | Consumable count if chosen for Chapter 4 |
| `QUEST_RELIC_LOW_CHAPTER_COUNT` | 1 | 1–2 | Relic count for Chapters 1–2 if chosen |
| `QUEST_RELIC_HIGH_CHAPTER_COUNT` | 2 | 1–3 | Relic count for Chapters 3–4 if chosen |
| `CONSUMABLE_TABLE` | See DR-5 | — | Probability distribution for consumable rewards; changing this affects game balance |

---

## Acceptance Criteria

### AC-1. Quest Node Generation

**Given**: Chapter 3 map generation completes.
**When**: The Map Generation System finalizes the layout.
**Then**: Exactly one Quest Node exists at the designated fixed position. No other Quest Nodes are present.

### AC-2. Quest Acceptance

**Given**: Player arrives at a Quest Node.
**When**: Player clicks "Accept".
**Then**: The quest enters `InProgress` state. The Lost Letter spawn process begins. A notification appears: "The Lost Letter has appeared somewhere in this chapter."

### AC-3. Quest Decline

**Given**: Player arrives at a Quest Node.
**When**: Player clicks "Decline".
**Then**: The node transforms into a Normal Road node. No quest is added to the active log. No Lost Letter spawns. Returning to the node shows Normal Road interaction.

### AC-4. Quest Come Back Later

**Given**: Player arrives at a Quest Node.
**When**: Player clicks "Come Back Later".
**Then**: The node remains a Quest Node with interaction state `Cleared`. No quest is added to the active log. No Lost Letter spawns. The player can return later and click "Accept" to start the quest.

### AC-5. Lost Letter Spawn Distribution

**Given**: 100 quests are accepted across multiple runs.
**When**: Spawn types are recorded.
**Then**: Hard Combat ≈ 70%, Black Market ≈ 15%, Safe House ≈ 10%, Normal Combat ≈ 5% (±5% tolerance).

### AC-6. Lost Letter Black Market Price

**Given**: Chapter 2 quest accepted, Lost Letter spawns in a Black Market.
**When**: Player opens the Black Market.
**Then**: The Lost Letter is in the extra slot with price **29 gold**.

### AC-7. Quest Hand-In and Node Transformation

**Given**: Player carries the Lost Letter and returns to the Quest Node.
**When**: Player interacts and confirms hand-in.
**Then**: The Lost Letter is removed. The node transforms into a Normal Road. One Survivor's Letter is added to inventory. A reward selection UI appears with 5 options (relic, gold, weapon, backpack, consumable).

### AC-8. Reward Selection — Gold

**Given**: Player completes the Chapter 3 quest and selects "金币" as one of two rewards.
**When**: The reward is granted.
**Then**: The player's gold increases by **44**.

### AC-9. Reward Selection — Consumables

**Given**: Player completes the Chapter 2 quest and selects "消耗品" as one of two rewards.
**When**: The reward is granted.
**Then**: Exactly **6** consumables are added to inventory, drawn from the probability table (磨刀石 22%, 石块 11%, 能量饮料 29%, 手电筒 15%, 火把 17%, 安全屋房卡 6%).

### AC-10. Chapter Transition Failure

**Given**: Player has accepted the Chapter 1 quest and the Lost Letter is in inventory.
**When**: Player defeats the Chapter 1 Boss and transitions to Chapter 2.
**Then**: The Lost Letter is removed from inventory. The quest is silently removed from the active log. No reward is granted. Chapter 2 begins normally.

### AC-11. False Ending Auto-Trigger (2 Letters)

**Given**: Player has collected 2 Survivor's Letters and defeats the Chapter 4 Boss.
**When**: The Boss death sequence completes.
**Then**: The False Ending triggers automatically. No choice dialog appears.

### AC-12. True Ending Choice (4 Letters)

**Given**: Player has all 4 Survivor's Letters and defeats the Chapter 4 Boss.
**When**: The Boss death sequence completes.
**Then**: A choice dialog appears. Selecting "Open and Read" removes all 4 letters from inventory and transitions to the Final Chapter map.

### AC-13. Save/Load with Transformed Node

**Given**: Player completes a quest, the node transforms to Normal Road, then saves and exits.
**When**: Player loads the save.
**Then**: The node is restored as a Normal Road. Interacting with it shows Normal Road behavior, not quest dialog.
