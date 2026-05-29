# Event System

## Overview

The Event System governs all Random Event (突发事件) nodes in Babel Archive. Each event is a self-contained interaction that presents a narrative situation, offers choices, and resolves an outcome affecting player resources, inventory, or progression. The system handles event generation per chapter, event type selection logic, choice resolution, and post-event state changes.

**Scope:** All Random Event node behavior — event type selection, probability weights per chapter, choice outcomes, item grants, state transitions, and the interaction flow with other systems (Combat, Backpack, Resource, Map).

**Key characteristics:**
- **Non-combat by default:** Most events resolve without combat. The "Fight" choice in Robbery and the Destroyed Camp event are the only combat branches.
- **Choice-gated outcomes:** The player actively selects an action; "Do Nothing" is always a safe fallback.
- **Item-outcome with fit check:** Any item granted by an event must pass the backpack fit check before being added to inventory.
- **Badge blocks theft/robbery:** The Badge relic (警徽) removes Theft and Robbery from the chapter's event pool entirely.
- **Per-chapter generation:** Event types are selected and placed during map generation; the same chapter always regenerates fresh events on replay.
- **Limited per chapter:** Each event type appears at most 3 times per chapter map.

## Detailed Rules

### Definitions

- **Event Type:** One of 9 distinct event scenarios (Theft, Robbery, Hitchhike, Corpse, Locked Box, Destroyed Camp, Gambler, Rogue Market, Dying Embers).
- **Event Instance:** A specific occurrence of an Event Type placed on a node during map generation.
- **Event Outcome:** The result of a player's choice — stat change (stamina/gold), item grant, node transformation, combat trigger, or teleport.
- **Locked Box:** A special item outcome that requires a secondary minigame (code guessing) before the actual reward is granted.
- **Gambler Bet:** The gold amount the player wagers in the Gambler event's Blackjack minigame.
- **Rogue Market:** A temporary Black Market that spawns from a Random Event node and reverts to Road on departure.
- **Badge Effect:** When Badge (警徽) is equipped, Theft and Robbery are excluded from the event pool. Probabilities for remaining events are renormalized.

### 1. Event Pool and Generation

#### 1.1 Event Type List

| Event Type | Chinese | Description |
| :--- | :--- | :--- |
| Theft | 偷窃 | 2 random items are removed from the player's backpack. |
| Robbery | 抢劫 | Pay half gold (floor) or trigger a normal combat. |
| Hitchhike | 顺风车 | Pay 2 gold to teleport to any non-Boss node. |
| Corpse | 尸体 | Spend 1 stamina to search (equivalent to ruins 2nd search). |
| Locked Box | 密码箱 | Receive a Locked Box item. Can attempt the code minigame (costs 1 stamina per guess). |
| Destroyed Camp | 毁灭的营地 | Triggers Hard Combat. Victory grants bonus Locked Box. |
| Gambler | 赌徒 | Wager 1–10 gold on a Blackjack game. Win doubles the bet; lose forfeits it. |
| Rogue Market | 破烂集市 | Node becomes a temporary Black Market. |
| Dying Embers | 将熄的火堆 | Restore 8 stamina instantly. |

#### 1.2 Event Generation Timing

- Events are generated once when the chapter's map is created.
- Each event type is assigned to a specific node during procedural map generation.
- The same chapter's map always regenerates fresh events on replay — there is no persistence across failed runs.
- Each event type appears at most **3 times** per chapter (enforced during map generation, not at runtime).

#### 1.3 Event Probability Per Chapter

Without Badge equipped:

| Event | Ch1 | Ch2 | Ch3 | Ch4 | Final |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Theft | 10% | 8% | 6% | 5% | 0% |
| Robbery | 10% | 11% | 12% | 12% | 0% |
| Hitchhike | 13% | 11% | 10% | 9% | 0% |
| Corpse | 11% | 14% | 16% | 18% | 35% |
| Locked Box | 9% | 11% | 11% | 13% | 34% |
| Destroyed Camp | 6% | 10% | 12% | 12% | 4% |
| Gambler | 13% | 11% | 9% | 9% | 0% |
| Rogue Market | 12% | 11% | 10% | 8% | 0% |
| Dying Embers | 16% | 13% | 14% | 14% | 27% |

With Badge equipped, Theft (10%/8%/6%/5%) and Robbery (10%/11%/12%/12%) are removed and the remaining probabilities are **renormalized proportionally** to sum to 100%:

| Event (with Badge) | Ch1 | Ch2 | Ch3 | Ch4 | Final |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Hitchhike | 17% | 15% | 13% | 12% | 0% |
| Corpse | 11% | 14% | 15% | 18% | 38% |
| Locked Box | 10% | 11% | 12% | 12% | 36% |
| Destroyed Camp | 8% | 11% | 14% | 17% | 4% |
| Gambler | 14% | 13% | 12% | 11% | 0% |
| Rogue Market | 18% | 16% | 14% | 12% | 0% |
| Dying Embers | 22% | 20% | 20% | 18% | 22% |

#### 1.4 Per-Chapter Event Type Cap

During map generation, event types are selected by weighted random. If placing an event type would exceed the cap of 3 instances for that type in the current chapter, that type is **skipped** and the next event is rolled instead. This ensures no event type appears more than 3 times per chapter.

### 2. Event Outcome Resolution

#### 2.1 Theft (偷窃)

**Trigger:** Player arrives at the event node.

**Without Badge:**
1. Randomly select 2 items from the player's backpack (ignoring pocket).
2. Remove those 2 items from inventory (no confirmation required).
3. Display which items were stolen.
4. If fewer than 2 items exist in backpack, remove only the items present.
5. Node becomes **Cleared**.

**With Badge:**
1. Display a message indicating the theft was blocked by the Badge.
2. No items are removed.
3. Node becomes **Cleared**.

#### 2.2 Robbery (抢劫)

**Trigger:** Player arrives at the event node.

**Choice A — Pay Half Gold (支付半数金币):**
1. Calculate `floor(current_gold / 2)`.
2. Deduct that amount from gold.
3. Display the amount paid.
4. Node becomes **Cleared**.

**Choice B — Fight (战斗):**
1. Close the event overlay.
2. Trigger a **Normal Combat** encounter against a robber enemy.
   - Robber enemy stats: use the Normal Combat table for the current chapter.
   - No special mechanics (no debuffs applied).
3. If the player wins:
   - No additional loot (avoiding payment is the reward).
   - Node becomes **Cleared**.
4. If the player flees:
   - Node becomes **Cleared** (the robbery is already resolved).
   - Player returns to the nearest Safe House.
5. If the player dies:
   - Permadeath triggers. Adventure ends.

**Choice C — Do Nothing (什么都不做):** Not available. The player must choose A or B.

#### 2.3 Hitchhike (顺风车)

**Trigger:** Player arrives at the event node.

**Choice A — Take the Ride (支付2金币):**
1. Verify player has ≥2 gold. If not, this choice is disabled.
2. Deduct 2 gold.
3. Open the **destination selection overlay** — all non-Boss nodes on the current chapter map are highlighted.
4. Player clicks a destination node.
5. Teleport the player token to the selected node.
6. The destination node's state (Unexplored/Revealed/Visited) is unchanged. Moving to an Unexplored node reveals it without triggering it.
7. The original Hitchhike node becomes **Cleared**.

**Choice B — Do Nothing (什么都不做):**
1. No effect.
2. Node becomes **Cleared**.

#### 2.4 Corpse (尸体)

**Trigger:** Player arrives at the event node.

**Choice A — Search (消耗1体力)：**
1. Verify player has >1 stamina. If not, this choice is disabled.
2. Deduct 1 stamina.
   - If stamina drops to ≤0 and Adrenaline Needle is available, it triggers (sets stamina to 10, destroys the relic).
   - If no Adrenaline Needle and stamina ≤0, permadeath triggers immediately. No loot is granted.
3. Roll on the **Ruins 2nd Search loot table** (see Node Interaction System).
4. Present the outcome via the Loot Take/Abandon flow.
5. Node becomes **Cleared**.

**Choice B — Do Nothing (什么都不做):**
1. No effect.
2. Node becomes **Cleared**.

#### 2.5 Locked Box (密码箱)

**Trigger:** Player arrives at the event node.

**Choice A — Take the Box (获得密码箱):**
1. Add one Locked Box item to the player's inventory (backpack fit check applies).
2. If inventory is full: player must make space (rearrange or abandon) before the item can be added.
3. If the player abandons the item, no box is received.
4. Node becomes **Cleared**.

**Choice B — Do Nothing (什么都不做):**
1. No item is received.
2. Node becomes **Cleared**.

**Note:** The Locked Box is a passive item. The code-guessing minigame is triggered when the player **uses** the item (outside of an event node) — see Section 3 for the minigame rules.

#### 2.6 Destroyed Camp (毁灭的营地)

**Trigger:** Player arrives at the event node.

**Choice — Fight (进入战斗):**
1. Close the event overlay.
2. Trigger a **Hard Combat** encounter.
   - Enemy stats use the Hard Combat table for the current chapter.
   - Debuffs from the Hard Combat table are applied normally.
3. Victory rewards:
   - Standard Hard Combat loot (gold, consumables, possible relic).
   - **Additional Locked Box** granted as bonus loot (goes through Take/Abandon flow).
4. Node becomes **Cleared**.
5. If the player flees:
   - Returns to the nearest Safe House.
   - Node becomes **Cleared** (no bonus Locked Box granted).
6. If the player dies:
   - Permadeath triggers. Adventure ends.

**Note:** There is no "Do Nothing" option for Destroyed Camp — the event presents only one button.

#### 2.7 Gambler (赌徒)

**Trigger:** Player arrives at the event node.

**Choice A — Play (进入21点游戏):**
1. Open the **bet amount selector**: a slider or number input from 1 to `min(10, current_gold)`.
2. Player confirms the bet amount. Minimum is 1 gold; maximum is 10 or current gold, whichever is lower.
3. The **Blackjack minigame** begins (see Section 4 for minigame rules).
4. Outcome:
   - **Win:** Player receives `bet × 2` gold.
   - **Lose:** Player loses the bet (bet is deducted — already paid at step 2).
   - **Push:** Player's bet is returned (no net change).
5. Node becomes **Cleared**.

**Choice B — Do Nothing (什么都不做):**
1. No effect.
2. Node becomes **Cleared**.

**Edge:** If the player has 0 gold, only "Do Nothing" is available.

#### 2.8 Rogue Market (破烂集市)

**Trigger:** Player arrives at the event node.

**Automatic Behavior:**
1. The event node **transforms into a Black Market node** for the duration of the visit.
2. The Black Market shop overlay opens immediately (same shop interface as a standard Black Market).
3. Player can buy and sell as normal.
4. When the player closes the shop: the node becomes **Cleared** and reverts to "普通道路" (Road). It is no longer a shop.
5. The shop stock is consumed (cannot be revisited in this adventure).

**No player choice is required.** The event resolves automatically on departure.

#### 2.9 Dying Embers (将熄的火堆)

**Trigger:** Player arrives at the event node.

**Automatic Behavior:**
1. Restore 8 stamina: `stamina = min(stamina + 8, max_stamina)`.
2. Display a warm glow animation on the stamina bar.
3. "Continue" button appears.
4. Player clicks "Continue".
5. Node becomes **Cleared**.

**Note:** If the player is already at max stamina, the +8 has no practical effect but is still visually displayed. No "Do Nothing" is needed because there is no cost — only benefit.

### 3. Locked Box Minigame

#### 3.1 Trigger

The Locked Box is a backpack item. The player can use it at any time outside of combat (in exploration, from the Backpack screen, via the "Use" button on the item).

Using the item opens the Locked Box minigame overlay.

#### 3.2 Mechanics

- The box has a randomly generated **2-digit code** (00–99), generated when the item is obtained.
- Each guess attempt costs **1 stamina**.
- The player enters a 2-digit guess using two digit selectors (0–9 each).
- After confirming a guess, the game provides feedback per digit:
  - "Higher" — the actual digit is greater than the guessed digit.
  - "Lower" — the actual digit is less than the guessed digit.
  - "Correct" — the digit matches.
- Feedback is shown **per digit**, not for the whole number. This allows the player to deduce each digit independently.

#### 3.3 Winning

When both digits are correct:
1. The box opens.
2. A reward is rolled from the reward table:

| Reward | Probability |
| :--- | :---: |
| Safe House Key ×1 | 40% |
| Gold ×20 | 20% |
| Unlocked Relic ×1 | 20% |
| Gold ×30 | 15% |
| Current Chapter Weapon | 2.5% |
| Current Chapter Backpack | 2.5% |

3. The reward is presented via the Loot Take/Abandon flow.
4. The Locked Box item is consumed (removed from inventory).
5. The minigame overlay closes.

#### 3.4 Losing (Running Out of Stamina Mid-Attempt)

- Each guess deducts 1 stamina.
- If stamina drops to 0 and Adrenaline Needle is available: it triggers (sets stamina to 10, destroys the relic), and the player can continue guessing.
- If no Adrenaline Needle and stamina ≤ 0: permadeath triggers. The box remains in inventory (unsolved) but the adventure is over.
- The player may close the minigame at any time without solving it. The box remains in inventory and can be attempted again later.

#### 3.5 Storage Space

- An unopened Locked Box occupies **2×2 grid cells** in the backpack.
- Once opened (solved or player quits), the space is freed.

### 4. Gambler — Simplified Blackjack Minigame

#### 4.1 Rules

- **Deck:** Standard 52-card deck. Aces count as 11 or 1 (player chooses). Face cards (J, Q, K) count as 10.
- **Objective:** The player's hand must be closer to 21 than the dealer's hand, without exceeding 21.
- **Dealer behavior:** Dealer hits on 16 or below; stands on 17 or above. (Dealer always hits soft 17.)
- **Bust:** Exceeding 21 loses immediately.
- **Blackjack:** A two-card 21 (Ace + 10/Face) is a standard win — not a special payout multiplier.
- **Push (Tie):** If both hands are equal (including both busting or both exactly 21), the bet is returned. No win, no loss.
- **No special card combinations:** No insurance, splitting, doubling down, or side bets.

#### 4.2 Minigame UI Flow

1. **Bet confirmation:** Player has already set the bet amount in the main event dialog. The bet is deducted immediately when the minigame starts.
2. **Initial deal:** Player receives 2 cards face-up. Dealer receives 2 cards — one face-up, one face-down.
3. **Player turn:** Player clicks **Hit** (receive another card) or **Stand** (keep current hand).
   - If player busts (>21): player loses immediately. Minigame ends.
   - If player stands: proceed to dealer turn.
4. **Dealer turn:**
   - Dealer's face-down card is revealed.
   - Dealer hits until reaching 17+.
   - If dealer busts: player wins.
5. **Resolution:**
   - **Win:** Player receives `bet × 2` gold (original bet + winnings equal to the bet).
   - **Lose:** Player loses the bet (already deducted at step 1).
   - **Push:** Player receives the bet back (refunded).
6. **Continue button:** Appears after resolution. Clicking it closes the minigame overlay.

#### 4.3 Edge Cases

- If the player's bet is 0 (0 gold), the minigame cannot start — the "Play" button is disabled at the event dialog.
- If the player's current gold is 1–9, the maximum bet is capped at that amount.
- If a deck runs out of cards during play, the discard pile is reshuffled to form a new deck (standard Blackjack behavior).

## Formulas

### Theft — Items Removed

```
backpack_items = all items in backpack grid (excluding pocket)
items_to_remove = min(2, backpack_items.count())
removed_items = random_sample(backpack_items, items_to_remove)
```

- Pocket items are not affected by Theft.
- If fewer than 2 items exist, all are removed.

### Robbery — Gold Payment

```
robbery_payment = floor(player_gold / 2)
```

### Event Probability Renormalization (with Badge)

```
removed_probabilities = [theft_prob, robbery_prob]
remaining_total = 100% - sum(removed_probabilities)
renormalized_prob[event] = original_prob[event] / remaining_total  # per remaining event
```

### Corpse — Stamina Cost

```
corpse_stamina_cost = 1
```

### Locked Box Reward Roll

```
roll = random_float(0, 1)
if roll < 0.40: reward = Safe House Key × 1
elif roll < 0.60: reward = Gold × 20
elif roll < 0.80: reward = Unlocked Relic × 1
elif roll < 0.95: reward = Gold × 30
elif roll < 0.975: reward = Current Chapter Weapon × 1
else: reward = Current Chapter Backpack × 1
```

### Gambler — Win/Loss/Push Resolution

```
if player_hand > dealer_hand and player_hand <= 21:
    outcome = WIN
    gold_delta = +bet
elif dealer_hand > 21 and player_hand <= 21:
    outcome = WIN
    gold_delta = +bet
elif player_hand > 21:
    outcome = LOSE
    gold_delta = -bet  # already deducted at bet step
elif dealer_hand > player_hand:
    outcome = LOSE
    gold_delta = -bet
elif player_hand == dealer_hand:
    outcome = PUSH
    gold_delta = 0  # bet already deducted, now refunded
```

### Stamina Restore (Dying Embers)

```
new_stamina = min(current_stamina + 8, max_stamina)
```

## Edge Cases

### E1. Theft with Fewer Than 2 Items

If the player enters a Theft event with only 1 item (or 0 items) in their backpack:
1. Remove the 1 item present (or nothing if empty).
2. Display a message indicating what was stolen (or that nothing could be stolen).
3. No error or crash occurs.

### E2. Robbery — Fight Flee

If the player chooses "Fight" at Robbery, fights, then flees:
1. The robbery is already resolved (the payment was avoided).
2. The node is Cleared.
3. No further interaction with this node is possible.
4. The flee takes the player to the nearest Safe House.

### E3. Hitchhike Teleport to an Unexplored Node

If the player uses Hitchhike and selects a node that is still Unexplored:
1. The player is teleported there.
2. The node becomes **Revealed** (not Visited) by the teleport.
3. The player must spend stamina to move from that node normally.
4. No double-cost or free movement is granted.

### E4. Corpse — No Stamina for Search

If the player has fewer than 2 stamina when entering a Corpse event:
1. The "Search" button is disabled (grayed out).
2. Only "Do Nothing" is clickable.
3. The player cannot accidentally trigger a stamina death from this event.

### E5. Locked Box — Full Inventory

If the player picks up a Locked Box but their inventory is full:
1. The Take/Abandon flow forces the player to make space.
2. If the player abandons the box, no box is received.
3. The player may try to obtain the box again in a future event.

### E6. Locked Box — Solved, Then Found Again

If the player solves a Locked Box and later obtains another Locked Box from a different event:
1. Each box has its own independent code.
2. Each box is a separate inventory item.
3. Each must be solved independently.

### E7. Destroyed Camp — Flee Loses Bonus Loot

If the player enters a Destroyed Camp, fights, but flees before winning:
1. The node becomes **Cleared** (the fight occurred).
2. The bonus Locked Box is **not** granted — even if the player wins the subsequent re-encounter (if they return).
3. The node cannot be re-entered for the bonus loot. The destroyed camp's reward is only available via a full victory in the initial encounter.

### E8. Gambler — All-In Bet

If the player bets all their gold (e.g., 5 gold when they have exactly 5):
1. The bet is placed and deducted.
2. If the player wins: they receive `bet × 2`, ending with 10 gold.
3. If the player loses: they end with 0 gold.
4. The "Do Nothing" option is still available before confirming the bet.

### E9. Rogue Market — Buy Before Selling

If the player enters a Rogue Market with insufficient gold but inventory items to sell:
1. The sell panel works normally — they can sell items to get gold.
2. Once they have gold, they can buy.
3. The shop functions identically to a standard Black Market.

### E10. Dying Embers — Already Full Stamina

If the player is at max stamina when entering Dying Embers:
1. Stamina shows "+8" with a visual indication that the bar is already full.
2. The player still sees the benefit visually (the bar briefly shows it cannot increase further).
3. No penalty or error occurs.

### E11. Event with Badge — Fewer Than 3 Events in Pool

The Badge removes 2 event types from the pool, but the per-chapter cap of 3 applies to each remaining type. The map generator still places events until all event slots are filled. If fewer than 3 instances of any given remaining event type are available, the remaining event slots are filled with other available event types up to the cap of 3 each.

### E12. Multiple Events Triggered Simultaneously

If the player somehow reaches a state where two events would trigger at once:
1. Events are processed one at a time, in the order they were entered.
2. The first event resolves fully (including any loot or combat) before the second event begins.
3. If the first event triggers combat, the second event is queued and activates after combat ends and the player returns to the map.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Node Interaction System** | Reads event node state (Unexplored/Revealed/Visited/Cleared); writes Cleared state after resolution; event triggers are called from node arrival logic |
| **Map Generation System** | Reads chapter event type weights and per-chapter cap; writes event types onto generated nodes |
| **Backpack & Inventory System** | Reads inventory to remove items (Theft) and check fit (Locked Box pickup); writes items granted (Locked Box) and items removed (Theft) |
| **Resource System** | Reads stamina and gold values for cost/enable checks; writes stamina changes (Dying Embers, Corpse, Locked Box guesses) and gold changes (Robbery, Hitchhike, Gambler) |
| **Combat System** | Receives combat trigger from Robbery "Fight" and Destroyed Camp; returns combat result (win/flee/death) |
| **Survivor Notes System** | Tracks Gambler gold won/lost for Hoarder; tracks Corpse searches for Scholar; tracks event node visits for Mischief Maker |
| **Shop System** | Rogue Market delegates all buy/sell logic to Shop System; no duplicate logic |

### Systems That Depend On This

| System | Dependency Detail |
| :--- | :--- |
| **UI System** | Reads event type to display the correct Random Event overlay; sends choice selections to this system; Rogue Market triggers shop overlay via Shop System |
| **Node Interaction System** | Event node arrival triggers this system; Cleared state written here is read by Node Interaction to determine revisit behavior |
| **Backpack & Inventory System** | Receives item removal (Theft) and item addition (Locked Box grant) commands; sends fit-check results for Locked Box pickup |
| **Combat System** | Receives event-triggered combat start commands; sends back combat outcome (win/flee) for state resolution |
| **Resource System** | Receives gold/stamina modification commands; sends current values for cost-gate checks |
| **Survivor Notes System** | Receives event-type-specific counters (Gambler gold won, Corpse searches, event visits) to update cumulative entries |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `EVENTS_PER_TYPE_PER_CHAPTER` | 3 | 1–5 | Maximum instances of each event type per chapter |
| `DYING_EMBERS_RESTORE` | 8 | 4–16 | Stamina restored by Dying Embers |
| `CORPSE_STAMINA_COST` | 1 | 1 | Stamina cost to search a Corpse |
| `HITCHHIKE_GOLD_COST` | 2 | 1–4 | Gold cost to take a Hitchhike |
| `ROBBERY_PAYMENT_DIVISOR` | 2 | 2–4 | Divisor for Robbery half-gold payment (floor division) |
| `GAMBLER_MIN_BET` | 1 | 1 | Minimum gold wager for Gambler |
| `GAMBLER_MAX_BET` | 10 | 5–20 | Maximum gold wager for Gambler |
| `LOCKED_BOX_CODE_DIGITS` | 2 | 2–3 | Number of digits in the Locked Box code |
| `LOCKED_BOX_STAMINA_PER_GUESS` | 1 | 1–2 | Stamina cost per Locked Box code guess |
| `THEFT_ITEMS_REMOVED` | 2 | 1–3 | Number of items removed by Theft |

## Acceptance Criteria

### AC1. Event Generation — Per-Type Cap
- [ ] Generate Chapter 1 map 3 times. Verify no event type appears more than 3 times in any single generation.
- [ ] Verify all 9 event types appear with roughly correct frequencies across multiple generations.

### AC2. Theft — Item Removal
- [ ] Enter a Theft event with 5 items in backpack. Verify exactly 2 are removed.
- [ ] Verify the correct items are shown as stolen.
- [ ] Enter a Theft event with 1 item in backpack. Verify only that 1 item is removed.

### AC3. Theft — Badge Blocks Theft
- [ ] Equip Badge (警徽). Enter a chapter.
- [ ] Verify no Theft events appear in that chapter's map.
- [ ] Verify the remaining event probabilities are proportionally higher.

### AC4. Robbery — Pay Half Gold
- [ ] Enter Robbery with 7 gold. Pay the half-gold.
- [ ] Verify 3 gold is deducted (floor(7/2) = 3).
- [ ] Enter Robbery with 8 gold. Pay the half-gold.
- [ ] Verify 4 gold is deducted (floor(8/2) = 4).

### AC5. Robbery — Fight
- [ ] Enter Robbery. Choose "Fight."
- [ ] Verify the event overlay closes and combat begins.
- [ ] Win the combat. Verify no loot is granted.
- [ ] Verify the node becomes "普通道路" (Road).

### AC6. Hitchhike — Teleport
- [ ] Enter Hitchhike with 5 gold. Choose to take the ride.
- [ ] Verify 2 gold is deducted.
- [ ] Verify a destination selection overlay appears with all non-Boss nodes highlighted.
- [ ] Click a distant node. Verify the player teleports there.
- [ ] Verify the original event node is now a Road.

### AC7. Corpse — Search
- [ ] Enter Corpse with 5 stamina. Choose to search.
- [ ] Verify 3 stamina is deducted.
- [ ] Verify loot roll is performed from the ruins 3rd search table.
- [ ] Verify loot is presented via Take/Abandon.
- [ ] Verify the node becomes Cleared.

### AC8. Corpse — Do Nothing
- [ ] Enter Corpse with 2 stamina. Choose "Do Nothing."
- [ ] Verify no stamina is deducted.
- [ ] Verify no loot is presented.
- [ ] Verify the node becomes Cleared.

### AC9. Locked Box — Pickup with Full Inventory
- [ ] Have a full backpack (no space). Enter a Locked Box event.
- [ ] Choose to take the box.
- [ ] Verify the Take/Abandon flow forces you to make space.
- [ ] Abandon the box. Verify it is not in inventory.
- [ ] Rearrange to make space, then Take. Verify it is in inventory and occupies 2×2 cells.

### AC10. Locked Box — Code Guessing Minigame
- [ ] Use the Locked Box. Verify the 2-digit code input UI appears.
- [ ] Make a guess. Verify feedback (Higher/Lower/Correct) is shown per digit.
- [ ] Verify 1 stamina is deducted per guess.
- [ ] Run out of stamina mid-attempt. Verify Adrenaline Needle triggers if available.
- [ ] Solve the box. Verify a reward is rolled and Take/Abandon flow appears.
- [ ] Verify the Locked Box is removed from inventory.

### AC11. Destroyed Camp — Combat Victory
- [ ] Enter Destroyed Camp. Choose "Fight."
- [ ] Verify Hard Combat begins.
- [ ] Win the combat.
- [ ] Verify standard Hard Combat loot is presented, followed by an additional Locked Box.
- [ ] Verify the node is Cleared.

### AC12. Destroyed Camp — Flee
- [ ] Enter Destroyed Camp. Choose "Fight." Begin combat.
- [ ] Flee the combat.
- [ ] Return to the map. Verify no bonus Locked Box is granted.
- [ ] Verify the node is Cleared and cannot be re-entered.

### AC13. Gambler — Win
- [ ] Enter Gambler with 10 gold. Bet 5 gold.
- [ ] Play and win the Blackjack game.
- [ ] Verify 10 gold is added (bet × 2 = 5 × 2).
- [ ] Verify total gold is now 15 (10 - 5 + 10).

### AC14. Gambler — Lose
- [ ] Enter Gambler with 10 gold. Bet 5 gold.
- [ ] Play and lose the Blackjack game.
- [ ] Verify 0 gold is added.
- [ ] Verify total gold is now 5 (10 - 5).

### AC15. Gambler — Push
- [ ] Enter Gambler with 10 gold. Bet 5 gold.
- [ ] Play and push (tie) the Blackjack game.
- [ ] Verify 5 gold is added (refund).
- [ ] Verify total gold is still 10.

### AC16. Rogue Market
- [ ] Enter Rogue Market. Verify shop overlay appears immediately.
- [ ] Verify the shop functions like a normal Black Market (buy/sell, 5 slots, chapter stock).
- [ ] Close the shop. Verify the node becomes Road.
- [ ] Return to the node. Verify it is now a Road (no shop available).

### AC17. Dying Embers
- [ ] Enter Dying Embers with 7/12 stamina.
- [ ] Verify stamina increases to 12 (capped at max).
- [ ] Verify the warm glow animation plays on the stamina bar.
- [ ] Enter Dying Embers with 12/12 stamina. Verify +8 is shown but bar stays full.

### AC18. Event State — Cleared After Resolution
- [ ] Complete any event (e.g., Dying Embers).
- [ ] Attempt to return to that node.
- [ ] Verify it is now a Road node and cannot re-trigger the event.

### AC19. Event — Do Nothing on All Applicable Events
- [ ] For each event that has a "Do Nothing" option (Hitchhike, Corpse, Locked Box, Gambler, Dying Embers):
  - Enter the event. Choose "Do Nothing."
  - Verify no stat changes occur.
  - Verify the node becomes Cleared.

### AC20. Badge — Robbery Also Blocked
- [ ] Equip Badge (警徽). Verify both Theft and Robbery are removed from the event pool.