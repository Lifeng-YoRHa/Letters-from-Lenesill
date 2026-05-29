# Combat System

## Overview

The Combat System handles all turn-based encounters between the player and enemies. Encounters occur on Normal Combat, Hard Combat, and Boss (Regional Pollution Source) nodes. The system manages round structure, action card activation, stamina costs, damage calculation, debuff application, enemy AI, loot spawning, and the flee/escape flow.

Combat is the primary stamina sink and the main gate for progression: the player cannot advance past a Boss without defeating it, and retreating from combat wastes the stamina spent to reach that node.

**Scope:** All combat encounters in Chapters 1–4 and the Final chapter. Normal and Hard Combat share the same core loop; Boss fights extend the loop with phase mechanics and escape teleportation.

**Key characteristics:**
- **Fixed action deck:** 8 cards, 3 randomly activated per round(could add up to 5).
- **Player-first turn order:** Player acts, then enemy acts.
- **Stamina as dual resource:** Spent to play cards; also reduced by taking damage.
- **Hard Combat debuffs:** Exactly 1 random debuff applied at encounter start (blocked by Eye Mask relic).
- **Boss escape:** Teleports player to nearest Safe House; Boss recovers 50% lost health on next encounter.
- **Loot is manual:** After victory, player chooses take/abandon for each item individually.
- **Solo:** Each node only possess 1 enemy

## Detailed Rules

### Definitions

- **Round:** One full cycle of player turn + enemy turn.
- **Action:** A single play of an action card or a single pocket item use. The player may perform up to 3 actions per turn (base); some effects can grant extra actions.
- **Activated Card:** One of the 3 (up to 5) action cards randomly selected for availability this turn. Only activated cards can be played.
- **Debuff:** A negative status effect applied at the start of a Hard Combat or Boss encounter. Persists until the encounter ends.
- **Encounter:** The entire combat session from start to victory, defeat, or flee.

### 1. Action Cards

The player always has access to the following 8 action cards. At the start of each player turn, 3 of them are randomly activated (upgradable to 5 via Survivor Notes).

| Action Card | Base Stamina Cost | Effect | Survivor Note Upgrade |
| :--- | :-: | :--- | :--- |
| Unarmed Attack | 1 | Deal 3 damage. | Damage +1 per "Warrior" stage (max 5). |
| Weapon Attack | 1 | Deal (weapon_attack) damage; weapon durability -1. Disabled if weapon durability ≤ 0. | None |
| Dodge | 2 | If enemy attacks next turn, damage taken -4. | Damage reduction +1 per "Sports Enthusiast" stage (max -6). |
| Search Backpack | 1 | Open the backpack interface. | None |
| Analyze Countermeasure | 1 | Next action card played this turn costs -3 stamina (min 0). | None |
| Flee | 5 | Escape combat; return to previous node. | Cost -1 per "Escape Master" stage (min 3). |
| Summon Courage | 1 | This encounter: Unarmed Attack and Weapon Attack damage +2. | None |
| Adjust Breathing | 1 | Next player turn: +1 action. | None |

**Activation rules:**
- Cards are selected uniformly at random from the 8-card pool without replacement.
- If a card's effect makes it unusable (e.g., Weapon Attack with broken weapon), it may still appear activated but is visually disabled.
- Pocket items are usable any time during the player's turn; each use consumes 1 action. They do not need to be activated.

### 2. Turn Structure

**Player Turn:**
1. Resolve any start-of-turn effects (debuffs, relic triggers, breathing bonus).
2. Randomly activate 3 action cards (or 5 with upgrades).
3. Player spends up to 3 actions (or 4 with Adjust Breathing), in any order:
   - Play an activated action card (pays stamina cost).
   - Use a pocket item.
4. After 3 actions (or when player ends turn manually), the player turn ends.

**Enemy Turn:**
1. Resolve any start-of-enemy-turn effects (Boss phase triggers, regeneration, etc.).
2. Enemy performs its attack: deals damage equal to its attack stat to the player.
3. Resolve any on-hit effects (player debuffs, relic reactions).
4. Enemy turn ends; next round begins.

### 3. Damage and Stamina

- **Stamina cost:** Deducted immediately when a card is played or an item is used.
- **Damage taken:** Reduces stamina by the damage amount.
- **Last Stand (Adrenaline Needle relic):** If the player possesses the **Adrenaline Needle** relic and any event (damage taken or stamina cost paid) would reduce stamina to 0 or below, the relic triggers **before** death:
  1. Stamina is set to 10.
  2. The Adrenaline Needle relic is destroyed and removed from inventory.
  3. The triggering damage or cost is fully applied (i.e., the player does not ignore the attack or cost; they simply survive it by restoring to 10).
  4. Combat continues normally.
  - This can trigger only once per adventure. After the relic is destroyed, future stamina drops to 0 result in immediate death.
- **Death:** If stamina reaches 0 or below and the Adrenaline Needle is not present (or already used), the player dies immediately. Combat ends, all progress is lost, and the next adventure starts from Chapter 1.
- **Overkill prevention:** An action that would cost more stamina than remaining can still be played. If no Last Stand is available, it will kill the player. This is a valid strategic choice (e.g., a final attack to win before the enemy acts).
- **Last Effort:** If the player's remaining stamina is **insufficient** to pay the cost of an activated action card, the player may choose to **force-play** that card anyway:
  1. The card's effect resolves normally (damage, flee, etc.).
  2. If the card's effect **kills the enemy**, the player's stamina is set to **2** immediately after the kill (upgradable to 4 via Survivor Notes). See **Resource System** for the formula `last_effort_recovery = 2 + berserker_stage` and upgrade thresholds.
  3. If the enemy survives, the player dies immediately after the card resolves (stamina was already exhausted by paying the cost).
  - Last Effort can be used **once per encounter**. After it is declared—regardless of whether it succeeds or fails—it cannot be used again in the same combat.
  - Last Effort triggers **after** the Adrenaline Needle (if the needle would fire on the same stamina drop, the needle fires first; if the player still lacks stamina after the needle's heal, Last Effort may then be declared).
  - **Survivor Note upgrade — Berserker:** Win 20/50 combats with stamina ≤ 5. Each stage increases Last Effort recovery by +1 (max 4).

### 4. Normal Combat

**Enemy generation:**
- A single enemy spawns per node.
- Enemy stats are drawn from the chapter's Normal Combat table (see Formulas).
- The enemy has no special mechanics unless the table states otherwise.

**Victory rewards:**
- Gold coins: amount drawn from chapter table; auto-collected up to 99 max.
- Consumables: 1–3 items drawn from chapter table; presented in a take/abandon list.
- No relics drop from Normal Combat.

### 5. Hard Combat

**Debuff application:**
- At encounter start, draw exactly 1 debuff from the chapter's Hard Combat debuff table.
- If the player has the **Eye Mask** relic, no debuff is drawn.
- The debuff persists for the entire encounter.

**Enemy generation:**
- A single enemy spawns with higher stats and a special mechanic (see Formulas).

**Victory rewards:**
- Gold coins: higher amount than Normal Combat.
- Consumables: 1–4 items.
- Relic: 20% chance in Chapter 1 (see Formulas for chapter scaling); only relics already unlocked in Survivor Notes are eligible.

### 6. Boss Combat

**Boss structure:**
- Bosses are located at the end of each chapter (Regional Pollution Source nodes).
- Each Boss has a unique name, health pool, attack stat, assigned debuffs, special mechanic, and defeat reward list.
- All Bosses share a common emergency heal: once, when health drops to ≤ 50% max HP, the Boss's next turn is replaced with "Heal 30% of max HP".

**Escape:**
- The player may flee the Boss fight using the Flee action card.
- Escape triggers the Map System's Boss Escape logic: teleport to nearest Safe House.
- Boss retains current HP. On next encounter, Boss recovers 50% of lost HP (e.g., if Boss lost 40 HP, it regains 20).

**Defeat rewards:**
- After victory, the player is fully healed, max stamina +1, and enters the loot sequence for Boss rewards.
- Then the backpack organization screen appears (same take/abandon flow).
- Finally, the next chapter's map is generated and play resumes at the new START node.

### 7. Backpack in Combat

- **Pocket items:** Usable at any time during the player's turn; each use consumes 1 action.
- **Backpack items:** Must first play "Search Backpack" (costs 1 action, 1 stamina) to open the backpack interface. Inside the interface:
  - Moving items between backpack and pocket does **not** close the interface.
  - Using an item or equipping a weapon **immediately** closes the interface and consumes the action.

### 8. Loot Sequence

After any combat victory (Normal, Hard, or Boss):
1. Pause combat; enter loot screen.
2. Display each loot item with Take / Abandon buttons.
3. Player clicks through each item. "Take" moves it to inventory (respecting space limits). "Abandon" permanently discards it.
4. Gold coins must also be manually clicked to collect.
5. After all items are resolved, the loot screen closes. If inventory is over capacity after taking, the backpack auto-arrange logic runs (or player is forced to discard).
6. The combat node is marked as cleared and converted to Road.

### 9. Flee Confirmation

When the player clicks the Flee card:
1. A confirmation dialog appears: "Flee this combat? You will return to the previous node and forfeit any progress."
2. If confirmed: deduct flee stamina cost, end combat, move player to previous node.
3. If canceled: return to action selection; the Flee card remains activated and can be clicked again.

### 10. Death

If player stamina reaches 0 or below at any point during combat:
1. Combat immediately ends.
2. Death screen appears.
3. All progress is lost; returning to main menu. Next adventure starts from Chapter 1.

## Formulas

### Damage Calculation

```
final_damage = base_damage + flat_bonuses - enemy_damage_reduction
```

- `base_damage`: Card's base value (3 for Unarmed, weapon_attack for Weapon).
- `flat_bonuses`: +2 from Summon Courage; +1 from Cross relic; +2 from Combat Manual relic; +1 from Cross (stacked with Combat Manual for +3 total); +1 from Brilliant Statue; +2 from Brilliant Statue (total +3 with Cross). Boss and Final chapter relic bonuses are additive.
- `enemy_damage_reduction`: Applied by enemy special mechanics (e.g., "damage taken -2" when HP ≤ threshold). Minimum damage is 1.

**Dodge damage reduction:**
```
damage_after_dodge = enemy_attack - dodge_reduction
```
- Base `dodge_reduction` = 4; upgraded to 6 via Survivor Notes.

### Action Card Upgrades

| Card | Base | Upgrade Path | Max |
| :--- | :-: | :--- | :-: |
| Unarmed Attack damage | 3 | +1 per Warrior stage (350/650 dmg) | 5 |
| Dodge reduction | 4 | +1 per Sports Enthusiast stage (70/150 dodges) | 6 |
| Flee cost | 5 | -1 per Escape Master stage (75/175 flees) | 3 |
| Activated cards per turn | 3 | +1 per Improviser stage (150/350 cards) | 5 |

### Last Effort Recovery

```
last_effort_recovery = 2 + berserker_stage
```

- Base recovery: 2 stamina.
- `berserker_stage`: 0 (locked), 1 (20 wins at ≤ 5 stamina), 2 (50 wins at ≤ 5 stamina).
- Maximum recovery: 4 stamina.

### Normal Combat Enemy Stats

**Chapter 1:**

| HP / ATK | Probability |
| :-: | :-: |
| 8 / 3 | 37% |
| 11 / 2 | 22% |
| 14 / 1 | 31% |
| 15 / 1 | 10% |

**Chapter 2:**

| HP / ATK | Probability |
| :-: | :-: |
| 10 / 5 | 23% |
| 14 / 4 | 18% |
| 19 / 3 | 31% |
| 21 / 2 | 18% |
| 28 / 1 | 10% |

**Chapter 3:**

| HP / ATK | Probability |
| :-: | :-: |
| 13 / 6 | 24% |
| 17 / 5 | 19% |
| 22 / 4 | 26% |
| 29 / 3 | 20% |
| 49 / 1 | 11% |

**Chapter 4:**

| HP / ATK | Probability |
| :-: | :-: |
| 16 / 8 | 21% |
| 25 / 6 | 23% |
| 30 / 4 | 18% |
| 42 / 3 | 16% |
| 66 / 1 | 22% |

**Final Chapter:**

| HP / ATK | Probability |
| :-: | :-: |
| 20 / 10 | 19% |
| 28 / 7 | 23% |
| 33 / 5 | 27% |
| 49 / 3 | 20% |
| 81 / 1 | 11% |

### Normal Combat Loot

**Chapter 1:**

| Gold | Probability | Consumables Count | Probability | Consumable Type | Probability |
| :-: | :-: | :-: | :-: | :-: | :-: |
| 3 | 17% | 1 | 40% | Stone | 17% |
| 4 | 48% | 2 | 40% | Whetstone | 21% |
| 5 | 20% | 3 | 20% | Energy Drink | 31% |
| 6 | 15% | — | — | Flashlight | 15% |
| — | — | — | — | Torch | 12% |
| — | — | — | — | Safe House Key | 4% |

(Loot tables for Chapters 2–4 scale upward; see `game-concept-babel.md` for full tables.)

### Hard Combat Debuff Table

Draw exactly 1 debuff at encounter start using these probabilities:

| Debuff | Effect | Ch1 | Ch2 | Ch3 | Ch4 | Final |
| :--- | :--- | :-: | :-: | :-: | :-: | :-: |
| Cowardice | Damage dealt -2 | 40% | 30% | 15% | 10% | 0% |
| Weakness | Enemy damage +1 per enemy turn end | 20% | 20% | 20% | 20% | 3% |
| Bleeding | Lose 1 stamina per player turn start | 10% | 15% | 20% | 20% | 25% |
| Trembling | 3 random cards cost +1 stamina | 10% | 12% | 15% | 13% | 20% |
| Madness | Damage dealt +1, lose 1 stamina per damage dealt | 10% | 10% | 15% | 10% | 10% |
| Delirium | 20% chance to deal 0 damage per hit | 7% | 5% | 5% | 10% | 15% |
| Despair | Lose 6 stamina at encounter start | 3% | 5% | 7% | 10% | 15% |
| Dullness | Actions per turn -1 | 0% | 2% | 2% | 4% | 7% |
| Hesitation | Skip first player turn | 0% | 1% | 1% | 3% | 5% |

### Hard Combat Enemy Stats

**Chapter 1:**

| HP / ATK | Probability | Special Mechanic |
| :-: | :-: | :--- |
| 13 / 4 | 22% | 2nd enemy turn: attacks twice |
| 22 / 3 | 27% | None |
| 26 / 2 | 31% | ATK +1 when HP ≤ 11 |
| 34 / 1 | 20% | Once: at HP ≤ 15, next turn heals 15 HP |

**Chapter 2:**

| HP / ATK | Probability | Special Mechanic |
| :-: | :-: | :--- |
| 19 / 6 | 23% | 2nd enemy turn: attacks twice |
| 29 / 5 | 18% | None |
| 32 / 3 | 31% | Damage taken -2 when HP ≤ 17 |
| 41 / 2 | 18% | ATK +2 when HP ≤ 18 |
| 55 / 1 | 10% | Once: at HP ≤ 23, next turn heals 20 HP |

**Chapter 3:**

| HP / ATK | Probability | Special Mechanic |
| :-: | :-: | :--- |
| 22 / 7 | 23% | 3rd enemy turn: attacks twice |
| 36 / 6 | 19% | None |
| 39 / 4 | 26% | Damage taken -2 when HP ≤ 19 |
| 48 / 3 | 20% | ATK +2 when HP ≤ 22 |
| 71 / 1 | 12% | Once: at HP ≤ 34, next turn heals 30 HP |

**Chapter 4:**

| HP / ATK | Probability | Special Mechanic |
| :-: | :-: | :--- |
| 27 / 8 | 19% | 3rd enemy turn: attacks twice |
| 43 / 7 | 23% | None |
| 44 / 4 | 20% | Damage taken -2 when HP ≤ 21 |
| 61 / 3 | 16% | ATK +3 when HP ≤ 24 |
| 82 / 1 | 22% | Once: at HP ≤ 38, next turn heals 41 HP |

**Final Chapter:**

| HP / ATK | Probability | Special Mechanic |
| :-: | :-: | :--- |
| 29 / 12 | 19% | 4th enemy turn: attacks twice |
| 47 / 9 | 23% | None |
| 51 / 6 | 27% | Damage taken -2 when HP ≤ 19 |
| 79 / 3 | 20% | ATK +2 when HP ≤ 22 |
| 111 / 1 | 11% | Once: at HP ≤ 54, next turn heals 55 HP |

### Hard Combat Loot

**Chapter 1:**

| Gold | Probability | Consumables Count | Probability | Relic Count | Probability |
| :-: | :-: | :-: | :-: | :-: | :-: |
| 7 | 17% | 1 | 30% | 0 | 80% |
| 8 | 48% | 2 | 45% | 1 | 20% |
| 9 | 20% | 3 | 20% | — | — |
| 10 | 12% | 4 | 5% | — | — |
| 11 | 3% | — | — | — | — |

Consumable type probabilities same as Normal Combat.
Relic pool: only unlocked relics, equal probability.

### Boss Stats

| Chapter | Name | HP | ATK | Debuffs | Defeat Rewards | Special Mechanic |
| :-: | :--- | :-: | :-: | :--- | :--- | :--- |
| 1 | Sorrow | 80 | 4 | Hesitation | Gold×20, Consumables×5, Relic×1, Key×2, Backpack×1 | Heal 5 HP per enemy turn start |
| 2 | Envy | 130 | 5 | Cowardice, Bleeding | Gold×30, Consumables×7, Relic×1, Key×2, Weapon×1 | Take 6 dmg per enemy turn start; ATK +1 |
| 3 | Hatred | 190 | 6 | Madness, Delirium | Gold×40, Consumables×9, Relic×2, Key×3 | ATK +1/+2/+3 at HP ≤ 140/80/20 |
| 4 | Numbness | 240 | 6 | Weakness, Dullness | Gold×50, Consumables×12, Relic×2, Key×3 (true end only) | Skip 1 player turn at HP ≤ 160/80 |
| Final | Origin | 300 | 7 | Despair, Trembling | True Ending | Heal 7 HP per turn; ATK +1/+2/+3 at HP ≤ 180/100/50 |

**Boss emergency heal (all Bosses):**
```
if boss_hp <= max_hp * 0.5 and not emergency_heal_used:
    next_enemy_turn = "Heal max_hp * 0.3"
    emergency_heal_used = true
```

### Boss Loot Consumable Distribution

| Type | Probability |
| :--- | :-: |
| Whetstone | 23% |
| Stone | 8% |
| Energy Drink | 32% |
| Flashlight | 17% |
| Torch | 20% |

## Edge Cases

### E1. Adrenaline Needle + Last Effort on Same Hit

If both the Adrenaline Needle and Last Effort could trigger on the same stamina drop (e.g., player has 2 stamina, takes 5 damage):
1. Adrenaline Needle fires first (stamina becomes 10).
2. Because stamina is now sufficient, Last Effort is **not** offered.
3. Combat continues with 5 stamina remaining.

### E2. Last Effort with Zero-Damage Card

If the player declares Last Effort on a non-damaging card (Dodge, Search Backpack, Flee, Adjust Breathing, Analyze Countermeasure), the enemy cannot be killed by that card. Therefore, Last Effort always fails, and the player dies immediately after the card resolves. The UI should still allow the declaration (the player is gambling on a misplay).

### E3. Last Effort Kills Enemy but Player Already Dead from Debuff

If the player is at 1 stamina, has Bleeding debuff, and uses Last Effort to kill the enemy with an attack:
1. The attack resolves, enemy dies.
2. Last Effort sets stamina to 2 (or upgraded value).
3. Bleeding does **not** tick again because the encounter has ended. The player survives.

### E4. Weapon Attack with 0 Durability

If the player's weapon durability is 0, the Weapon Attack card is visually disabled but may still appear in the activated set. If the player somehow plays it (e.g., via a bug or mod), it deals 0 damage, does not reduce durability further, and wastes the action and stamina.

### E5. Dodge Stacking

If the player plays Dodge multiple times in the same turn, the damage reduction does **not** stack. Only the most recent Dodge applies. If the enemy does not attack next turn (e.g., Boss skips turn), the Dodge is wasted.

### E6. Summon Courage Stacking

If the player plays Summon Courage multiple times in the same encounter, the +2 damage bonus does **not** stack. Playing it again wastes an action and stamina. The bonus persists until the encounter ends.

### E7. Adjust Breathing + Dullness Debuff

If the player has the Dullness debuff (actions per turn -1) and plays Adjust Breathing (next turn +1 action), the net result is 3 actions next turn (base 3 - 1 + 1 = 3). Adjust Breathing cancels Dullness but does not grant a bonus action on top.

### E8. Flee from Normal/Hard Combat

Fleeing from Normal or Hard combat (not Boss) returns the player to the **previous node** (the node they came from). The combat node remains uncleared; re-entering restarts the encounter with a fresh enemy and new debuff draw.

### E9. Loot Screen Inventory Overflow

If the player selects "Take" on a loot item that would exceed inventory capacity, the system triggers the backpack auto-arrange logic. If items still cannot fit after auto-arrange, the newly taken item is **automatically abandoned** and the player is shown a "Not enough space" message.

### E10. Boss Emergency Heal Interrupt

If the player reduces the Boss to ≤ 50% HP and also kills it in the same action (e.g., a massive overkill), the Boss dies immediately. The emergency heal does **not** trigger because the Boss is already dead.

### E11. Eye Mask vs. Boss Debuffs

The Eye Mask relic blocks the **Hard Combat** debuff draw. It does **not** block Boss-assigned debuffs (e.g., Sorrow's Hesitation). Boss debuffs are mandatory.

### E12. Analyzing Countermeasure on 0-Cost Card

If the player plays Analyze Countermeasure and the next card costs 0 stamina (e.g., due to a previous Analyze or a bug), the -3 reduction has no effect but is still consumed.

### E13. Combat Death with Adrenaline Needle Already Used

If the player already used the Adrenaline Needle earlier in the adventure and later dies in combat, death proceeds normally. The needle's "once per adventure" limit is enforced globally, not per combat.

### E14. Pocket Item Use During Backpack Interface

If the player opens the backpack via Search Backpack, they cannot use pocket items while the backpack UI is open. They must close the backpack first (by using a backpack item, equipping a weapon, or canceling).

### E15. Last Effort Trigger Window

**Last Effort can only be declared during the player's own turn.** If the player's stamina drops to 0 or below during the enemy turn (from an enemy attack, debuff tick, or any non-player action), the player dies immediately without being offered Last Effort. This means Last Effort is strictly a proactive gamble on the player's final action, not a reactive save from an enemy hit.

## Dependencies

### Upstream

- **Map Generation System:** Provides the node type (Normal/Hard/Boss) and enemy stat table index for the current encounter. Combat does not modify the map graph.
- **Backpack & Inventory System:** Provides current weapon stats (attack, durability), pocket/backpack item access, and inventory capacity checks during looting.
- **Relic System:** Applies passive effects (Cross, Combat Manual, Eye Mask, Lighter, etc.) at encounter start or during damage calculation. Combat reads relic state but does not modify it (except destroying Adrenaline Needle).
- **Survivor Notes System:** Provides upgrade values for action cards (Unarmed damage, Dodge reduction, Flee cost, activated card count).
- **Resource System (Stamina):** Tracks current and max stamina. Combat deducts stamina for costs and damage; Boss victory restores stamina to max and increments max by 1.
- **Node Interaction System:** Initiates combat when the player steps onto a combat node, and handles node conversion to Road after victory.

### Downstream

- **Save / Load System:** Persists combat state (current HP, debuffs, round count, enemy HP, Adrenaline Needle used flag) for pause-and-resume during encounters.
- **UI / Rendering System:** Displays action cards, enemy sprite, damage numbers, stamina bar, debuff icons, and loot screen.
- **Audio System:** Plays SFX for attacks, hits, dodges, flee, death, and loot.

## Tuning Knobs

| Knob | Default | Safe Range | Gameplay Impact |
| :--- | :-: | :-: | :--- |
| `base_actions_per_turn` | 3 | 2–4 | Core pacing. Lower = more defensive; higher = more combo potential. |
| `base_activated_cards` | 3 | 2–5 | Options available per turn. Lower = more RNG dependency; higher = more consistent plans. |
| `unarmed_base_damage` | 3 | 2–4 | Baseline damage without weapon. Affects early-game feel. |
| `dodge_base_reduction` | 4 | 2–6 | Damage avoided by Dodge. Too high makes Dodge overpowered; too low makes it worthless. |
| `flee_base_cost` | 5 | 3–7 | Stamina tax for escaping. Lower = safer exploration; higher = commitment to fights. |
| `boss_emergency_heal_pct` | 30% | 20–40% | Boss recovery at 50% HP. Higher = longer Boss fights. |
| `boss_escape_recovery_pct` | 50% | 25–75% | HP recovered by Boss after player escapes. Higher = punishes repeated attempts. |
| `hard_combat_relic_drop_rate_ch1` | 20% | 10–30% | Chance for relic in Hard Combat. Higher = more relics in economy. |
| `debuff_dullness_action_penalty` | 1 | 1–2 | Actions removed by Dullness. 2 is extremely punishing. |

## Acceptance Criteria

A QA tester can verify the Combat System with these checks:

1. **[Turn Order]** Enter any combat. Verify the player acts first, then the enemy acts. Repeat for 3 rounds.

2. **[Action Limit]** Verify the player can perform exactly 3 actions per turn (base). Playing a 4th action is impossible unless Adjust Breathing was used the previous turn.

3. **[Activation Count]** Verify exactly 3 action cards are activated at the start of each player turn (or 5 with Survivor Note upgrades). Verify unactivated cards cannot be clicked.

4. **[Stamina Death]** Enter combat with 1 stamina. Play a card costing 1 stamina. Verify the player dies immediately after the card resolves if no Adrenaline Needle is held.

5. **[Adrenaline Needle]** Enter combat with the Adrenaline Needle. Take fatal damage. Verify stamina is set to 10, the relic is destroyed, and combat continues.

6. **[Last Effort – Success]** Enter combat with 1 stamina. Use Last Effort to play Unarmed Attack and kill the enemy. Verify stamina becomes 2 (or upgraded value) and combat ends in victory.

7. **[Last Effort – Failure]** Enter combat with 1 stamina. Use Last Effort to play Unarmed Attack but fail to kill. Verify the player dies after the action resolves.

8. **[Last Effort – Enemy Turn Block]** Enter combat with 1 stamina. End turn. Let the enemy attack and reduce stamina to 0. Verify Last Effort is **not** offered; the player dies immediately.

9. **[Weapon Durability]** Attack with a weapon at 1 durability. Verify durability becomes 0 and the Weapon Attack card is disabled on the next turn.

10. **[Dodge]** Play Dodge, then end turn. Let enemy attack. Verify damage taken is reduced by 4 (or upgraded value). Verify playing Dodge twice in one turn does not stack.

11. **[Summon Courage]** Play Summon Courage, then attack. Verify damage is +2. Play Summon Courage again; verify damage does not increase further.

12. **[Analyze Countermeasure]** Play Analyze Countermeasure, then play a 2-stamina card. Verify it costs 0 stamina (min 0). Then play Analyze again and use a 1-stamina card; verify it still costs 0.

13. **[Hard Combat Debuff]** Enter a Hard Combat node 20 times (with Eye Mask unequipped). Verify exactly 1 debuff is applied each time. Verify no debuff is applied when Eye Mask is equipped.

14. **[Boss Emergency Heal]** Fight Chapter 1 Boss. Reduce its HP to exactly 40 (≤ 50% of 80). Verify its next turn is "Heal 24 HP" instead of an attack. Verify this happens only once.

15. **[Boss Escape]** Enter Boss fight, deal 20 damage, then flee. Re-enter the same Boss. Verify Boss HP is 60 (80 - 20 + 10 recovery).

16. **[Loot Manual]** Defeat an enemy. Verify gold and consumables appear in a list with Take/Abandon buttons. Verify clicking Abandon permanently removes the item. Verify gold must be manually clicked to collect.

17. **[Flee Confirmation]** Click Flee. Verify a confirmation dialog appears. Cancel it; verify combat resumes. Click Flee again and confirm; verify player returns to the previous node.

18. **[Combat Node Clear]** Defeat a Normal or Hard Combat node. Verify the node type changes to Road on the map. Re-enter the node; verify no combat occurs.

19. **[Boss Victory Transition]** Defeat a Boss. Verify player stamina is fully restored, max stamina +1, loot screen appears, then next chapter map is generated.

20. **[Death Reset]** Die in combat. Verify all progress is lost and the next adventure starts from Chapter 1.
