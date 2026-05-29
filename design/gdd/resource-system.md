# Resource System

## Overview

The Resource System tracks and manages the two primary numeric resources in the adventure: **Stamina** (体力) and **Gold** (金币). Stamina serves as both the player's health pool and action currency; Gold is the sole medium of exchange for shops, events, and quest transactions. The system governs all gains, losses, caps, recovery triggers, and death checks for these resources.

**Scope:** All stamina and gold mutations across the entire adventure — movement, combat, consumables, node interactions, rewards, and Survivor Note scaling.

**Key characteristics:**
- **Stamina is dual-purpose:** It is spent to play action cards and move between nodes, and it is reduced by enemy damage. There is no separate "HP" stat.
- **Death at ≤ 0:** Stamina dropping to 0 or below triggers permadeath immediately, unless the Adrenaline Needle relic intervenes (once per adventure). In combat, the player may also declare **Last Effort** on their own turn to force-play a card with insufficient stamina; if that card kills the enemy, stamina is restored instead of death.
- **No passive regeneration:** Stamina does not recover naturally; the player must find or consume recovery sources.
- **Gold is spatial and capped:** Coins occupy a fixed 1×1 inventory cell and are hard-capped at 99, regardless of available space.
- **Survivor Note scaling:** Both initial max stamina and starting gold can be permanently increased through Survivor Note progression.

## Detailed Rules

### Definitions

- **Current Stamina:** The player's present stamina value. Mutable during play.
- **Max Stamina:** The player's stamina ceiling. Starts at a base value and can increase permanently via Survivor Notes and temporarily via Boss victories.
- **Stamina Overdraft:** A state where stamina is reduced to 0 or below. Triggers death checks.
- **Current Gold:** The player's present coin count. Mutable during play.
- **Max Gold:** The absolute coin cap, fixed at 99.
- **Death Gate:** The check that fires whenever stamina would drop to ≤ 0. Evaluates Adrenaline Needle before applying permadeath.

### 1. Stamina

#### 1.1 Max Stamina

- Base max stamina at adventure start: **12**.
- Survivor Note "Wayfarer" (行路人): each stage increases initial max stamina by +1.
  - Stage thresholds: 150 / 350 / 650 / 1100 non-Road nodes visited.
  - Maximum stages: 4.
  - Maximum initial max stamina: **16**.
- Boss victory bonus: defeating a Boss fully restores stamina and increases **max stamina by +1** for the remainder of the adventure. This bonus is per-chapter and stacks across chapters.
- Max stamina has no absolute hard cap beyond the practical limit of starting max + 4 Boss bonuses = **20** in a full run.

#### 1.2 Stamina Loss

Stamina is reduced by the following events:

| Source | Timing | Amount |
| :--- | :--- | :--- |
| Node movement | On traversing an edge | `movement_cost` (base 1, modified by backpack / debuff) |
| Action card cost | On playing a card | Card's stated stamina cost |
| Damage taken | On enemy hit or debuff tick | Damage value dealt |
| Ruins search | On choosing "Search" | 1 |
| Random Event | On certain event choices | Defined by event outcome |
| Consumables (Stone / Torch) | On use | 2 |
| Debuff — Bleeding | Start of each player turn | 1 |
| Debuff — Despair | Encounter start | 6 |
| Debuff — Madness | Per damage dealt by player | 1 |
| Debuff — Trembling | On affected cards | +1 to those cards' costs |

- All deductions are applied **immediately** at the triggering event.
- If multiple deductions occur in sequence (e.g., card cost then enemy damage in the same round), each is applied separately and the Death Gate is checked after each.

#### 1.3 Stamina Recovery

Stamina can be restored by the following sources:

| Source | Timing | Amount | Notes |
| :--- | :--- | :--- | :--- |
| Energy Drink | On use | `energy_drink_restore` (base 7) | Cannot exceed max stamina |
| Safe House — Rest | On choosing "Rest" | To full max stamina | Once per Safe House visit |
| Random Event | On certain outcomes | Defined by event | — |
| Boss Victory | Immediately after Boss defeat | To full max stamina | Also increases max by +1 |
| Adrenaline Needle | When stamina would drop to ≤ 0 | 10 | Once per adventure; relic is destroyed |
| Last Effort — Success | After killing enemy with insufficient stamina | `last_effort_recovery` (base 2) | Only if kill succeeds |

- Recovery effects are capped at current max stamina. Excess is discarded.
- The Energy Drink restore amount is upgraded via Survivor Note "Partner" (合作伙伴): each stage +1, max +3, for a maximum restore of **10**.
- Last Effort restore amount is upgraded via Survivor Note "Berserker" (狂战士): each stage +1, max +2, for a maximum restore of **4**.

#### 1.4 Death Gate

Whenever stamina would be reduced to 0 or below:

1. Apply the deduction.
2. Check if the player holds the **Adrenaline Needle** relic and it has **not** been used this adventure.
   - If yes: stamina is set to 10. The relic is destroyed and flagged as used. The triggering event resolves fully. Combat / movement continues.
   - If no: the player dies immediately.
3. If stamina is still ≤ 0 after Adrenaline Needle (e.g., needle was already consumed), evaluate **Last Effort**:
   - Last Effort can only be declared during the **player's own turn**.
   - If declared and the action kills the enemy: stamina is set to `last_effort_recovery`. Combat ends in victory.
   - If declared but the enemy survives: player dies after the action resolves.
   - Last Effort is **once per encounter**.

- Death is **permadeath**: all progress is lost; the next adventure starts from Chapter 1.
- The Death Gate fires after **every** stamina mutation, not just combat damage.

#### 1.5 Overkill and Force-Play

- A player may play an action card even if its cost exceeds current stamina. This is a valid strategic choice.
- If the card kills the enemy and Last Effort is available, it triggers. Otherwise, the player dies after the card resolves.
- Movement may also overdraft stamina: the player may click a node knowing the cost will reduce stamina to ≤ 0.

### 2. Gold

#### 2.1 Starting Gold

- Base starting gold at adventure start: **8**.
- Survivor Note "Hoarder" (囤积者): each stage increases starting gold by +1.
  - Stage thresholds: 100 / 250 / 500 / 800 total gold accumulated across all adventures.
  - Maximum stages: 4.
  - Maximum starting gold: **12**.

#### 2.2 Gold Cap

- Absolute cap: **99** coins.
- The cap is enforced **before** the spatial check. If the player is at 99 coins, all new gold is auto-discarded regardless of inventory space.
- Gold occupies exactly **one 1×1 inventory cell** at all times, even at 0 coins.

#### 2.3 Gold Gain

| Source | Timing | Amount |
| :--- | :--- | :--- |
| Combat victory — Normal | After win | 3–6 (Chapter 1), scales upward |
| Combat victory — Hard | After win | 7–11 (Chapter 1), scales upward |
| Boss victory | After win | 20–50 base, scales by chapter |
| Ruins search | On search outcome | By ruins loot table |
| Random Event | On certain outcomes | By event definition |
| Quest reward | On completion | By quest definition |
| Shop sell | On transaction | Sell price (see Backpack System) |
| Safe House — Piggy Bank | On taking | Small fixed amount (see Safe House rules) |

- Gold gains are presented with a manual "Collect" button in loot interfaces; they are not auto-looted.

#### 2.4 Gold Loss

| Source | Timing | Amount |
| :--- | :--- | :--- |
| Shop purchase | On buying | Item's buy price |
| Random Event | On certain choices | By event definition |
| Quest cost | On completing some quests | By quest definition |

- Gold cannot drop below 0. Any transaction that would cost more than current gold is blocked.

### 3. Resource UI

- **Stamina bar:** Displays current / max stamina as a segmented bar. Color shifts to warning (yellow) at ≤ 30% max, danger (red) at ≤ 10% max.
- **Gold display:** Shows current coin count next to a coin icon. Turns red when at 99 (cap warning).
- **Death flash:** When stamina drops to ≤ 0 and no save is available, a brief red flash plays before the death screen.

## Formulas

### Max Stamina

```
max_stamina = BASE_MAX_STAMINA + wayfarer_stages + boss_victories_this_adventure
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_MAX_STAMINA` | 12 | 10–20 | Starting max stamina before any bonuses. |
| `wayfarer_stages` | 0–4 | 0–4 | Survivor Note "Wayfarer" stages earned across all adventures. |
| `boss_victories_this_adventure` | 0–4 | 0–4 | Number of Bosses defeated in the current adventure. Resets on new adventure. |

**Example:** A player with Wayfarer stage 2 who has defeated 2 Bosses has `12 + 2 + 2 = 16` max stamina.

### Starting Gold

```
starting_gold = BASE_STARTING_GOLD + hoarder_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_STARTING_GOLD` | 8 | 5–15 | Starting coins before any bonuses. |
| `hoarder_stages` | 0–4 | 0–4 | Survivor Note "Hoarder" stages earned across all adventures. |

**Example:** A player with Hoarder stage 3 starts with `8 + 3 = 11` gold.

### Energy Drink Restore

```
energy_drink_restore = BASE_ENERGY_RESTORE + partner_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_ENERGY_RESTORE` | 7 | 5–10 | Base stamina restored by one Energy Drink. |
| `partner_stages` | 0–3 | 0–3 | Survivor Note "Partner" stages. Each adds +1 restore. |

**Example:** A player with Partner stage 2 restores `7 + 2 = 9` stamina per Energy Drink.

### Last Effort Recovery

```
last_effort_recovery = BASE_LAST_EFFORT_RECOVERY + berserker_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_LAST_EFFORT_RECOVERY` | 2 | 2–4 | Base stamina restored on successful Last Effort. |
| `berserker_stages` | 0–2 | 0–2 | Survivor Note "Berserker" stages. Each adds +1 recovery. |

**Example:** A player with Berserker stage 1 recovers `2 + 1 = 3` stamina on Last Effort success.

### Movement Cost

```
movement_cost = BASE_MOVE_COST + backpack_penalty + debuff_penalty
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_MOVE_COST` | 1 | 1–3 | Base stamina cost per edge traversal. |
| `backpack_penalty` | 0 or 1 | 0–1 | 1 if Oversized Backpack equipped. |
| `debuff_penalty` | 0 or 1 | 0–1 | 1 if "Heavy Legs" or equivalent movement debuff active. |

### Gold Cap Enforcement

```
function add_gold(amount):
    if current_gold >= MAX_GOLD:
        return 0  # all incoming gold discarded
    new_total = current_gold + amount
    if new_total > MAX_GOLD:
        accepted = MAX_GOLD - current_gold
        current_gold = MAX_GOLD
        return accepted  # excess silently discarded
    else:
        current_gold = new_total
        return amount
```

### Stamina Recovery Cap

```
function restore_stamina(amount):
    current_stamina = min(current_stamina + amount, max_stamina)
```

## Edge Cases

### E1. Adrenaline Needle + Last Effort on Same Drop

If both could trigger on the same stamina reduction (e.g., player has 2 stamina, takes 5 damage):
1. Adrenaline Needle fires first. Stamina becomes 10.
2. Because stamina is now > 0, Last Effort is **not** offered.
3. The 5 damage is fully applied; final stamina = 5.

### E2. Last Effort on Non-Damaging Card

If Last Effort is declared on an action that cannot kill (Dodge, Search Backpack, Flee, Adjust Breathing, Analyze Countermeasure), the enemy cannot die. Last Effort fails; the player dies immediately after the card resolves.

### E3. Last Effort During Enemy Turn

If stamina drops to ≤ 0 during the enemy turn (enemy attack, Bleeding tick, etc.), Last Effort is **not** offered. Last Effort is only available during the player's own turn. The player dies immediately.

### E4. Energy Drink at Full Stamina

Using an Energy Drink at full stamina has no effect. The item is consumed, stamina remains at max, and no overflow is stored.

### E5. Rest at Safe House with Full Stamina

Choosing "Rest" at full stamina is allowed but has no effect. The once-per-visit Rest charge is still consumed.

### E6. Gold at Exactly 99 with Empty Cells

If current gold is 99, all new gold is rejected by the numeric cap, even if the inventory has empty 1×1 cells. The player sees a "Gold cap reached" message, not a space message.

### E7. Gold Below 99 with No 1×1 Space

If current gold < 99 but no empty 1×1 inventory cell exists, gold pickup is rejected for space reasons. The player sees a "No space" message.

### E8. Negative Stamina Before Moving

If the player has 0 or negative stamina and clicks a node, the movement cost is still deducted. The Death Gate fires. Without Adrenaline Needle, the player dies without entering the target node.

### E9. Boss Victory with Bleeding Debuff

If the player defeats a Boss while having the Bleeding debuff, the debuff ends with the encounter. The post-victory full heal sets stamina to the new max; Bleeding does not tick again.

### E10. Adrenaline Needle Already Used

If the Adrenaline Needle was consumed earlier in the adventure, future stamina drops to ≤ 0 result in immediate death. There is no fallback save.

### E11. Multiple Stamina Deductions in One Action

Playing a card that both costs stamina and triggers Madness debuff (lose 1 stamina per damage dealt) results in two separate deductions: first the card cost, then the Madness cost per hit. The Death Gate is checked after each.

### E12. Gold Loss with Zero Gold

If an event or quest attempts to deduct gold when the player has 0, the deduction is blocked. The interaction may fail or branch to an alternative outcome (defined by the event/quest system).

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Survivor Notes System** | Provides Wayfarer, Hoarder, Partner, and Berserker stage values for max stamina, starting gold, Energy Drink restore, and Last Effort recovery |
| **Relic System** | Adrenaline Needle state (held / used) determines Death Gate behavior |
| **Backpack & Inventory System** | Gold spatial check (1×1 cell required); Energy Drink item use triggers stamina restore |
| **Combat System** | Action card costs, damage taken, debuff ticks, and Last Effort declaration all mutate stamina |
| **Node Interaction System** | Movement cost deduction, Safe House Rest trigger, ruins search cost, and event stamina mutations |

### Systems That Depend On This

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Reads current/max stamina for UI display, death checks, and Last Effort eligibility |
| **Node Interaction System** | Reads current stamina for movement cost deduction and overdraft death checks |
| **UI / Rendering System** | Displays stamina bar, gold counter, and death screen |
| **Save / Load System** | Must serialize current stamina, max stamina, current gold, and Adrenaline Needle used flag |
| **Shop System** | Reads current gold for purchase validation; deducts gold on buy |
| **Achievement / Survivor Notes** | Tracks stamina recovered, gold accumulated, and wayfarer/hoarder/partner/berserker progress |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_MAX_STAMINA` | 12 | 10–20 | Starting max stamina. Lower = more punishing early game. |
| `BASE_STARTING_GOLD` | 8 | 5–15 | Starting coins. Lower = tighter economy. |
| `MAX_GOLD` | 99 | 50–999 | Absolute gold cap. Higher reduces inventory pressure. |
| `BASE_MOVE_COST` | 1 | 1–3 | Base stamina per node move. Higher = shorter effective path range. |
| `BASE_ENERGY_RESTORE` | 7 | 5–12 | Stamina restored by Energy Drink. Lower = consumables less impactful. |
| `BASE_LAST_EFFORT_RECOVERY` | 2 | 1–4 | Stamina after successful Last Effort. Lower = riskier gambles. |
| `ADRENALINE_NEEDLE_RESTORE` | 10 | 5–20 | Stamina restored by Adrenaline Needle. Lower = less forgiving. |
| `BOSS_MAX_STAMINA_BONUS` | +1 | 0–2 | Max stamina increase per Boss victory. Higher = snowballing. |
| `WAYFARER_MAX_STAMINA_PER_STAGE` | +1 | +1–+2 | Max stamina bonus per Wayfarer stage. |
| `HOARDER_STARTING_GOLD_PER_STAGE` | +1 | +1–+2 | Starting gold bonus per Hoarder stage. |
| `PARTNER_RESTORE_PER_STAGE` | +1 | +1–+2 | Energy Drink restore bonus per Partner stage. |
| `BERSERKER_RECOVERY_PER_STAGE` | +1 | +1–+2 | Last Effort recovery bonus per Berserker stage. |

## Acceptance Criteria

### AC1. Stamina Death
- [ ] Start a new adventure. Enter combat with 1 stamina.
- [ ] Play a card costing 1 stamina. Verify the player dies immediately after resolution.
- [ ] Restart adventure. Equip Adrenaline Needle. Repeat.
- [ ] Verify stamina is set to 10, relic is destroyed, and combat continues.

### AC2. Last Effort — Success and Failure
- [ ] Enter combat with 1 stamina and no Adrenaline Needle.
- [ ] Declare Last Effort and play Unarmed Attack, killing the enemy.
- [ ] Verify stamina becomes `last_effort_recovery` and combat ends in victory.
- [ ] Enter combat with 1 stamina again. Declare Last Effort on a non-killing action.
- [ ] Verify the player dies after the action resolves.

### AC3. Last Effort — Enemy Turn Block
- [ ] Enter combat with 1 stamina. End turn.
- [ ] Let the enemy attack and reduce stamina to 0.
- [ ] Verify Last Effort is **not** offered; the player dies immediately.

### AC4. Energy Drink Restore
- [ ] Reduce stamina to 5. Use an Energy Drink with Partner stage 0.
- [ ] Verify stamina becomes 12 (5 + 7).
- [ ] Advance Partner to stage 2. Reduce stamina to 5 again.
- [ ] Use an Energy Drink. Verify stamina becomes 14 (5 + 9).
- [ ] Use another at full stamina. Verify stamina stays at max and item is consumed.

### AC5. Gold Cap Enforcement
- [ ] Set gold to 99. Defeat an enemy that drops 5 gold.
- [ ] Verify the gold is discarded and a cap message is shown.
- [ ] Set gold to 98. Defeat an enemy that drops 5 gold.
- [ ] Verify only 1 gold is accepted and current gold becomes 99.

### AC6. Gold Space Check
- [ ] Fill backpack so no 1×1 cell is empty. Set gold to 98.
- [ ] Attempt to pick up 1 gold. Verify rejection with "No space" message.
- [ ] Discard a 1×1 item to free a cell. Attempt pickup again.
- [ ] Verify gold is accepted and becomes 99.

### AC7. Starting Resources — Survivor Notes
- [ ] Start a new adventure with Wayfarer stage 0. Verify max stamina is 12.
- [ ] Start a new adventure with Wayfarer stage 4. Verify max stamina is 16.
- [ ] Start a new adventure with Hoarder stage 0. Verify starting gold is 8.
- [ ] Start a new adventure with Hoarder stage 4. Verify starting gold is 12.

### AC8. Boss Victory Stamina Bonus
- [ ] Defeat Chapter 1 Boss with max stamina 12.
- [ ] Verify stamina is fully restored and max stamina becomes 13.
- [ ] Defeat Chapter 2 Boss. Verify max stamina becomes 14 and stamina is full.

### AC9. Safe House Rest
- [ ] Reduce stamina to 3. Enter a Safe House. Choose Rest.
- [ ] Verify stamina is restored to current max. Leave and re-enter.
- [ ] Verify Rest is available again (per-visit limit, not global cooldown).

### AC10. Movement Overdraft Death
- [ ] Reduce stamina to 1 with no Adrenaline Needle. Click an adjacent node with movement cost 1.
- [ ] Verify stamina becomes 0 and permadeath triggers before entering the node.
