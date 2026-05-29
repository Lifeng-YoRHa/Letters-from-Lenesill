# Node Interaction System

## Overview

The Node Interaction System governs what happens when the player arrives at, clicks, or departs from a map node. It translates the abstract node types produced by the Map Generation System into concrete gameplay sequences: combat encounters, shop interfaces, event dialogs, loot screens, and node transitions. The system also manages the fog-of-war reveal rules, node visit state tracking, and stamina cost deduction for movement.

**Scope:** All node types (START, Road, Normal Combat, Hard Combat, Random Event, Ruins, Quest, Safe House, Black Market, BOSS). Covers arrival triggers, interaction flows, departure gates, and post-interaction state changes.

**Key characteristics:**
- **Click-to-interact:** The player clicks a revealed adjacent node to move to it; movement is only allowed to directly connected nodes.
- **Stamina gate:** Every move between nodes consumes stamina; if the player lacks sufficient stamina, the move will not be blocked, but player will die after the move and before enter into the node.
- **Node state machine:** Each node tracks whether it is unexplored, visited, or cleared. State determines fog visibility and whether re-interaction is possible.
- **Non-reversible flow:** Most interactions (combat, events) advance game state and cannot be undone. The player is prompted to confirm before committing.
- **Loot and reward piping:** Victory or event outcomes that grant items call the Backpack & Inventory System fit check before presenting the Take/Abandon choice.

## Detailed Rules

### Definitions

- **Node State:** Every node exists in one of four states:
  - **Unexplored:** The node is hidden by fog of war. Neither position nor type is visible.
  - **Revealed:** The node's position is visible, but its type is hidden (shown as a silhouette). Revealed nodes are directly adjacent to an explored node.
  - **Visited:** The player has arrived at this node at least once. Type and position are fully visible. The node may or may not be interactable again.
  - **Cleared:** The node's primary interaction has been resolved (combat won, event completed, ruins searched). Type and position are visible. Re-interaction rules vary by type.
- **Current Node:** The node the player is presently standing on. Only the current node and its connections are eligible for movement.
- **Adjacent Node:** A node that shares a bidirectional edge with the current node.
- **Movement Cost:** The stamina deducted when moving from the current node to an adjacent node. Base cost is 1; modified by backpack and relic effects.
- **Interaction Gate:** A condition that must be met before the node's main interaction begins (e.g., stamina check, confirmation dialog).

### 1. Node State Machine

All nodes begin as **Unexplored**. The START node is the exception: it begins as **Visited**. While the Regional Pollution Source node begins as **Visible**

**State transitions:**
- Unexplored → Revealed: when any adjacent node becomes Visited.
- Revealed → Visited: when the player moves onto the node.
- Visited → Cleared: when the node's primary interaction completes successfully.
- Visited remains Visited: if the player leaves before resolving the interaction (possible for Safe House, Black Market, and flee from a combat).

Nodes never revert to a previous state. Fog of war never re-obscures a node.

### 2. Movement Rules

**Initiating movement:**
1. The player clicks a **Revealed** or **Visited** adjacent node.
2. The system calculates the movement cost.
3. Deduct the movement cost from stamina (stamina may become negative).
4. Move the player token to the target node.
5. If stamina > 0 after deduction:
   - Set the target node to **Visited**.
   - Reveal all adjacent nodes (Unexplored → Revealed).
6. If stamina ≤ 0 after deduction:
   - If the player holds the **Adrenaline Needle** relic, trigger its effect (stamina restore) and survival.
     - After survival, set the target node to **Visited** and reveal adjacent nodes.
   - Otherwise, the player dies; permadeath triggers.

**Movement cost calculation:**
```
movement_cost = base_cost + backpack_penalty + debuff_penalty
base_cost = 1
```
- **Backpack penalty:** Oversized Backpack adds +1.
- **Debuff penalty:** Certain combat debuffs may add +1 (see Combat System).

**Backtracking:** The player may move to any adjacent node, including the one they just came from. There is no penalty for backtracking beyond the normal stamina cost.

### 3. Fog of War

- **Unexplored nodes:** Completely invisible. No position marker, no type hint.
- **Revealed nodes:** Position is shown as a generic silhouette. Type is hidden. Connections to the explored node are drawn as faint lines.
- **Visited / Cleared nodes:** Fully visible. Type icon, name, and state are displayed. All connections to adjacent nodes are drawn.

When a node becomes Visited, all its adjacent nodes transition from Unexplored to Revealed. If an adjacent node was already Revealed or Visited, it remains unchanged.

### 4. START Node

- The START node is automatically Visited when the adventure begins.
- It has no interaction; the player simply begins here.
- It is never a combat node and never grants rewards.
- Connections from START lead to layer 2 nodes.

### 5. Road Node

- **Arrival:** No interaction. The player arrives and may immediately move again.
- **State:** Becomes Cleared immediately upon arrival.
- **Purpose:** Filler nodes that create path length and stamina drain.

### 6. Normal Combat Node

- **Arrival trigger:** Combat begins automatically. There is no choice to avoid it.
- **Interaction flow:**
  1. Transition to combat scene.
  2. Combat resolves using the Combat System.
  3. If the player wins:
     - Node becomes **Cleared**.
     - Loot is presented (1–3 items, refer to the probability table). See Backpack System fit check rules.
     - Player returns to the map on this node.
  4. If the player loses:
     - Permadeath triggers; adventure ends.
- **Revisit:** A Cleared Normal Combat node cannot be interacted with again. It is treated as a Road node for movement purposes only.

### 7. Hard Combat Node

- **Arrival trigger:** Combat begins automatically.
- **Interaction flow:** Identical to Normal Combat, but enemy stats are higher and debuff chance on victory is increased (see Combat System).
- **Loot:** Hard Combat grants better loot (higher tier item table).
- **Revisit:** Same as Normal Combat; cannot be re-interacted once Cleared.

### 8. Random Event Node

- **Arrival trigger:** Event dialog opens automatically.
- **Interaction flow:**
  1. Display event text and 2–4 choice buttons.
  2. Player selects a choice.
  3. Outcome resolves (stats change, items gained/lost, stamina change, combat forced, nothing happens).
  4. Node becomes **Cleared**.
  5. Player returns to the map.
- **Revisit:** Cannot be re-interacted once Cleared.
- **Item outcomes:** If the outcome grants an item, the Backpack fit check is called. If the item does not fit, the player is forced to Abandon it; there is no inventory access during event resolution.

### 9. Ruins Node

- **Arrival trigger:** Choice dialog appears: "Search the ruins?" with **Search** and **Leave** options.
- **Search flow:**
  1. Player clicks **Search**. This consumes 1 action (outside combat context; this is a map action, not a combat action).
  2. A random outcome is rolled from the Ruins loot table.
  3. Outcome possibilities: Refer to the probability table.
  4. If an item is found, the Backpack fit check is called. Take/Abandon is presented.
  5. Node becomes **Cleared** after a cumulative total of 3 Searches, regardless of outcome. The counter persists if the player leaves and returns.
- **Leave:** Player returns to the map. Node remains **Visited** (not Cleared) and can be searched later.
- **Revisit:** Once Cleared, Ruins behave like Road nodes.

### 10. Quest Node

- **Arrival trigger:** Quest dialog opens automatically.
- **Interaction flow:**
  1. Display quest text and **Accept** / **Decline** buttons.
  2. If Decline: node becomes **Cleared** (quest is gone for this adventure). Player returns to map.
  3. If Accept: quest is added to the active quest log. Node becomes **Cleared**.
  4. Quest completion is checked at specific trigger points (combat wins, item collection, node visits).
  5. When a quest completes, rewards are granted immediately (items, gold, stamina restore). Backpack fit check applies to item rewards.
- **Revisit:** Once Cleared, Quest nodes behave like Road nodes.
- **Quest failure:** Quest failed when leaving the Chapter before handing over "lost letter". Failure removes the quest silently; no penalty.

### 11. Safe House Node

- **Arrival trigger:** Safe House interface opens automatically.
- **Interaction options:**
  - **Rest:** Restore stamina to maximum. Requires 1 Safe House Key. Can be used once per Safe House visit.
  - **Fridge:** Take 1 Energy Drink (free, if available).Can be used twice for each Safe House.(upgradable to three times via Survivor Notes)
  - **Anvil:** Repair equipped weapon durability and ATK to its maximum (for free). Can be used once for each Safe House.(upgradable to twice via Survivor Notes)
  - **Piggy Bank:** Take gold. The amount is a random value uniformly drawn from a per-chapter table (base 6–10 in Chapter 1, increasing by chapter). Survivor Notes can increase the amount by +1. Replenishes once per chapter transition.
  - **Scattered consumable:** 1 random item on the ground. Roll on the scattered item table (Whetstone 21%, Stone 16%, Energy Drink 32%, Flashlight 15%, Torch 12%, Safe House Key 4%). Scales up to 3 items via Survivor Notes. Replenishes once per chapter transition.
  - **Leave:** Close interface and return to map.
- **Node state:** Safe House nodes do **not** become Cleared. They remain **Visited** indefinitely and can be re-entered at any time by moving back to them.
- **Stamina restore:** Does NOT consume an action. It is a free benefit upon choosing to Rest.
- **One-time resources:** Fridge, Piggy Bank, and scattered consumables are replenished per-chapter or per-adventure based on Survivor Notes progress (see Survivor Notes System).

### 12. Black Market Node

- **Arrival trigger:** Shop interface opens automatically.
- **Interaction options:**
  - **Buy:** Purchase items from the shop stock. Items are generated via weighted random (see ADR-0007). Backpack fit check blocks purchase if no space.
  - **Sell:** Sell items from inventory. Sell prices defined in Backpack System.
  - **Leave:** Close interface and return to map.
- **Node state:** Black Market nodes do **not** become Cleared. They remain **Visited** indefinitely and stock refreshes once per chapter transition.
- **Stock limits:** Each Black Market has a fixed number of item slots (see Tuning Knobs). Sold items are removed from stock; purchased items are removed from stock.

### 13. BOSS Node

- **Arrival trigger:** Boss combat begins automatically. There is no choice to avoid it.
- **Interaction flow:**
  1. Transition to Boss combat scene.
  2. Combat resolves using Boss-specific rules (see Combat System).
  3. If the player wins:
     - Node becomes **Cleared**.
     - Chapter completion rewards are granted (gold, items, Survivor Note progress).
     - Transition to next chapter (or game victory if Final chapter).
  4. If the player loses:
     - Permadeath triggers; adventure ends.
- **Revisit:** N/A; defeating the Boss transitions out of the chapter.

### 14. Departure Gates

Before leaving any node, the system checks:
1. **Ongoing interaction:** Is an interaction dialog or overlay open? If yes, block movement until it is closed.
2. **Pending loot:** Is there an unclaimed loot item on screen? If yes, block movement until Take or Abandon is selected.

If all gates pass, movement proceeds normally.

## Formulas

### Movement Cost

```
movement_cost = BASE_MOVE_COST + backpack_penalty + debuff_penalty
```

| Variable | Value | Description |
| :--- | :-: | :--- |
| `BASE_MOVE_COST` | 1 | Base stamina cost for every edge traversal. |
| `backpack_penalty` | 0 or 1 | 1 if Oversized Backpack is equipped; 0 otherwise. |
| `debuff_penalty` | 0 or 1 | 1 if the active combat debuff "Heavy Legs" is applied; 0 otherwise. |

### Stamina Overdraft Death Check

```
if current_stamina - movement_cost <= 0:
    if player_has_relic("Adrenaline Needle"):
        trigger_relic_effect("Adrenaline Needle")
        # player survives; stamina restored by relic-defined amount
    else:
        trigger_permadeath()
```

- The check occurs **after** deducting stamina but **before** entering the node's interaction.
- If the player dies from overdraft on a Combat node, they never enter combat.

### Ruins Search Counter

```
if ruins_search_count < 3:
    allow_search()
    ruins_search_count += 1
    if ruins_search_count >= 3:
        set_node_state(node, CLEARED)
else:
    block_search()  # node already cleared
```

- `ruins_search_count` persists per node for the duration of the adventure.
- Leaving and returning does not reset the counter.

### Piggy Bank Gold

```
piggy_bank_base(chapter) = PIGGY_BANK_CH1_BASE + (chapter - 1) * PIGGY_BANK_BONUS_PER_CHAPTER
piggy_bank_range = [piggy_bank_base, piggy_bank_base + 4]  # 5 equally probable values
gold_amount = uniform_random(piggy_bank_range)
```
- Survivor Notes Wayfarer adds +1 to all values.
- Replenishes on chapter transition; each Safe House generates fresh gold independently.

### Scattered Consumable

```
scattered_item_roll():
    roll = uniform(0.0, 1.0)
    if roll < 0.21: return WHETSTONE
    elif roll < 0.37: return STONE      # 0.21 + 0.16
    elif roll < 0.69: return ENERGY_DRINK  # 0.37 + 0.32
    elif roll < 0.84: return FLASHLIGHT  # 0.69 + 0.15
    elif roll < 0.96: return TORCH        # 0.84 + 0.12
    else: return SAFE_HOUSE_KEY           # 0.96 + 0.04
```
- Number of rolls per Safe House visit = `SAFE_HOUSE_SCATTERED_USES` (base 1, up to 3 with Survivor Notes).
- Replenishes on chapter transition.

### Fog of War Reveal

```
when node N becomes VISITED:
    for each adjacent node A of N:
        if A.state == UNEXPLORED:
            A.state = REVEALED
```

- Revealed nodes show only position; type remains hidden until Visited.

## Edge Cases

### E1. Stamina Exactly Equals Movement Cost
If `current_stamina == movement_cost`, stamina becomes 0 after deduction. Because stamina is 0, the overdraft death check fires immediately. If the player lacks Adrenaline Needle, they die before entering the node. If they hold Adrenaline Needle, it triggers and restores stamina, allowing them to enter the node.

### E2. Stamina Is 0 or Negative Before Moving
If the player has 0 or negative stamina and clicks an adjacent node, `movement_cost` is deducted, and the overdraft death check fires. If the player lacks Adrenaline Needle, they die without ever entering the target node.

### E3. Adrenaline Needle Trigger on Overdraft
If the player overdrafts and holds Adrenaline Needle, the relic triggers **once per adventure** (or per its own cooldown rules; see Relic System). After triggering, the player survives with restored stamina and proceeds into the node's interaction normally.

### E4. Moving onto a Cleared Combat Node
A Cleared Normal Combat or Hard Combat node behaves exactly like a Road node: no combat triggers, the node is already Cleared, and the player may move through freely.

### E5. Fleeing Combat Returns to Visited Node
If the player flees combat, they are returned to the node they were standing on before they entered into the Combat node. That node's state remains **Visited** (it does not become Cleared). The player may choose to move away or, if the node allows, re-enter the interaction.

### E6. Safe House Chapter Lock
Safe House nodes are chapter-local. Within a single chapter, the player may backtrack to a previously visited Safe House; it remains **Visited** and fully functional. Once the player defeats the Boss and transitions to the next chapter, the previous chapter's map is permanently inaccessible. Each chapter's Safe House resources (Piggy Bank gold, scattered items) are independently regenerated on chapter transition; Fridge and Anvil uses reset per visit within the chapter.

### E7. Black Market Chapter Lock
Black Market nodes are chapter-local. Stock is generated when the chapter's map is created and does not refresh during the chapter. Once the player transitions to the next chapter, the previous chapter's Black Market is permanently inaccessible. New Black Markets in the new chapter have freshly generated stock.

### E8. Ruins Counter Persistence
A Ruins node with a search count of 2/3 remains **Visited** (not Cleared) if the player leaves. Upon return, the counter is still 2/3. The 3rd search clears it. The counter is saved and loaded with the adventure state.

### E9. Quest Failure by Chapter Transition
If the player leaves the current chapter without handing over the Lost Letter, the active quest is silently removed. No penalty is applied. The Quest node remains **Cleared** and cannot be revisited for that quest.

### E10. Death by Overdraft on Boss Node
If the player overdrafts stamina moving onto the BOSS node and lacks Adrenaline Needle, they die **before** Boss combat begins. The Boss is never encountered, and the adventure ends.

### E11. Regional Pollution Source Visibility
The Regional Pollution Source node begins as **Visible** (fully visible type and position) even though it may be Unexplored in terms of visit state. This is a special exception to fog-of-war rules. Its interaction flow is defined in the Boss and Chapter Transition System (see Dependencies).

### E12. Multiple Nodes Revealed Simultaneously
When a node becomes Visited, all its Unexplored neighbors become Revealed at the same frame. There is no sequential reveal animation that blocks input.

### E13. Leaving with an Open Overlay
If the player attempts to move while the Safe House or Black Market overlay is open, the Departure Gate blocks movement. The player must close the overlay first.

### E14. Backtracking Through a Long Path
The player may traverse any path regardless of length, provided they have enough cumulative stamina (or are willing to risk overdraft death). There is no "no backtracking" restriction.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Map Generation System** | Provides node types, positions, connections, and variant topology for every chapter |
| **Combat System** | Triggers combat on Normal/Hard/BOSS nodes; handles flee returns; defines debuffs that affect movement cost |
| **Backpack & Inventory System** | Fit check for loot, ruins finds, quest rewards, and shop purchases; shop sell prices |
| **Relic System** | Adrenaline Needle trigger on stamina overdraft; potential relics that modify movement cost or node rewards |
| **Survivor Notes System** | Determines Safe House resource replenishment rates (Fridge uses, Anvil uses, scattered consumables) |
| **Shop System (Black Market)** | Weighted random stock generation (ADR-0007), buy/sell transaction handling |
| **Resource System** | Current stamina value read for movement cost deduction and overdraft checks |

### Systems That Depend on This

| System | Dependency Detail |
| :--- | :--- |
| **Save/Load System** | Must serialize every node's state (Unexplored/Revealed/Visited/Cleared), ruins search counters, quest completion flags, and Black Market stock |
| **Achievement / Survivor Notes** | "Explorer" notes may track nodes visited; "Trader" notes track Black Market spending |
| **Boss and Chapter Transition System** | Regional Pollution Source visibility and interaction are triggered by node arrival |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_MOVE_COST` | 1 | 1–3 | Base stamina cost per edge. Higher = more stamina pressure, shorter effective path range. |
| `RUINS_SEARCH_LIMIT` | 3 | 1–5 | Number of searches before a Ruins node is Cleared. Higher = more value per ruins. |
| `SAFE_HOUSE_FRIDGE_USES` | 2 | 1–5 | Free Energy Drinks per Safe House visit. Scales with Survivor Notes. |
| `SAFE_HOUSE_ANVIL_USES` | 1 | 1–3 | Free full-repair uses per Safe House visit. Scales with Survivor Notes. |
| `PIGGY_BANK_GOLD_CH1` | 6–10 | 5–15 | Gold amount range in Chapter 1. Each value (6,7,8,9,10) has equal probability. Scales by chapter. |
| `PIGGY_BANK_BONUS_PER_CHAPTER` | +2 | +1–+3 | Amount added to Piggy Bank range per chapter. Chapter N range = Ch1 base + (N-1)×bonus. |
| `SAFE_HOUSE_SCATTERED_USES` | 1 | 1–3 | Scattered consumable items per Safe House visit. Scales with Survivor Notes. |
| `BLACK_MARKET_SLOTS` | 5 | 4–10 | Number of items in each Black Market stock. Higher = more shop relevance. |
| `BOSS_LOOT_GOLD_BASE` | 20 | 10–50 | Base gold granted on Boss victory, before chapter scaling. |
| `ADRENALINE_NEEDLE_RESTORE` | defined in Relic System | — | Stamina restored when Adrenaline Needle triggers on overdraft. |

## Acceptance Criteria

### AC1. Movement and Stamina Deduction
- [ ] Stand on a Road node with 5 stamina. Click an adjacent Road node.
- [ ] Verify stamina becomes 4 and the player token moves.
- [ ] Equip Oversized Backpack. Verify stamina becomes 3 (base 1 + backpack 1).
- [ ] Click another adjacent node with 1 stamina remaining and no Adrenaline Needle.
- [ ] Verify stamina becomes 0 and permadeath triggers; the player never enters the node.

### AC2. Stamina Overdraft Death
- [ ] Reduce stamina to 1. Equip no relics. Click an adjacent node with movement cost 1.
- [ ] Verify stamina becomes 0 and permadeath triggers. Verify no node interaction occurs.
- [ ] Restart adventure. Equip Adrenaline Needle. Reduce stamina to 1. Click an adjacent node with movement cost 1.
- [ ] Verify Adrenaline Needle triggers, stamina is restored, and node interaction begins normally.

### AC3. Fog of War Reveal
- [ ] Start a new adventure. Verify only the START node and Regional Pollution Source are visible.
- [ ] Move from START to an adjacent node. Verify all neighbors of the new node become Revealed (silhouettes).
- [ ] Verify the adjacent node's type is hidden until the player moves onto it.

### AC4. Normal Combat Flow
- [ ] Move onto a Normal Combat node. Verify combat starts automatically.
- [ ] Win combat. Verify the node becomes Cleared and loot is presented.
- [ ] Return to the map on the same node. Move away, then move back.
- [ ] Verify no combat triggers; the node behaves like a Road node.

### AC5. Ruins Cumulative Search
- [ ] Enter a Ruins node. Click Search. Verify node remains Visited.
- [ ] Click Leave. Move away, then return.
- [ ] Click Search twice more. Verify node becomes Cleared on the 3rd search.
- [ ] Verify the node cannot be searched again and behaves like a Road node.

### AC6. Safe House Revisit (Same Chapter)
- [ ] Enter a Safe House. Use Rest and Fridge. Verify stamina is full and Energy Drink is received.
- [ ] Leave, move to another node, then backtrack to the same Safe House.
- [ ] Verify Rest and Fridge are available again (a new visit resets the per-visit limits).
- [ ] Defeat the Boss and transition to the next chapter.
- [ ] Verify the previous chapter's map is no longer accessible.

### AC7. Black Market Stock and Chapter Lock
- [ ] Enter a Black Market. Note the stock items. Buy one item.
- [ ] Leave, move away, then backtrack to the same Black Market.
- [ ] Verify the stock still shows the remaining items (stock does not refresh within a chapter).
- [ ] Defeat the Boss and transition to the next chapter.
- [ ] Verify the previous chapter's Black Market is inaccessible. Verify the new chapter has a new Black Market with fresh stock.

### AC8. Quest Acceptance and Failure
- [ ] Enter a Quest node. Accept the quest. Verify node becomes Cleared.
- [ ] Leave the chapter without handing over the Lost Letter.
- [ ] Verify the quest is silently removed from the quest log with no penalty.

### AC9. Departure Gates
- [ ] Enter a Safe House. While the overlay is open, attempt to click an adjacent node.
- [ ] Verify movement is blocked until the overlay is closed.
- [ ] Win combat and receive loot. While the loot dialog is open, attempt to move.
- [ ] Verify movement is blocked until Take or Abandon is selected.

### AC10. Backtracking
- [ ] From the START node, move to layer 2, then layer 3.
- [ ] Click the layer 2 node to move back. Verify movement succeeds with normal stamina cost.
- [ ] Verify no additional penalty is applied.
