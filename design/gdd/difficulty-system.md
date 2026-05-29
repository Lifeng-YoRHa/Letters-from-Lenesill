# Difficulty System

## Overview

The Difficulty System governs how challenge and rewards vary across combat nodes. It defines two combat tiers — Normal Combat and Hard Combat — their node distribution, per-chapter enemy stat tables, loot drop tables, and the Boss encounter structure at each chapter's end.

There is no multiplier-based scaling. All enemy stats, gold drops, consumable drops, and debuff probabilities are defined as explicit lookup tables per chapter per tier.

**Scope:** All combat encounters (Normal, Hard, Boss) across Chapters 1–4 and the Final chapter.

**Key characteristics:**
- **Two combat tiers:** Normal Combat (no debuff, lower rewards) and Hard Combat (random debuff, higher rewards, relic drop chance).
- **Per-chapter stat tables:** Enemy HP/ATK combinations are drawn from explicit probability distributions for each chapter and tier.
- **Data-driven loot:** Gold quantity, consumable count, consumable type, and relic drop chance all come from chapter-specific probability tables — no formulas.
- **Boss encounters:** Each chapter ends with a unique Boss with fixed stats, debuff, special mechanic, and reward table.
- **Debuff escalation:** Hard Combat debuff pools deepen each chapter; early debuffs fade out, later ones appear.
- **Progressive unlock:** After completing a run at the currently unlocked highest difficulty (true or false ending), the next difficulty level is unlocked, enabling harder modifiers and new challenges.

## Detailed Rules

### 1. Combat Tier Definitions

| Tier | Node Type | Debuff | Enemy Stats | Gold Drop | Consumable Drop | Relic Drop |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Tier 1 | Normal Combat | None | Per-chapter table | Per-chapter table | 1–3 items | None |
| Tier 2 | Hard Combat | 1 random per encounter | Per-chapter table + special mechanic | Per-chapter table | 1–4 items | 20–30% (based on chapter) |
| Tier 3 | Boss (Regional Pollution Source) | 1 fixed per Boss | Boss-specific table | Boss table | 2–5 items | Guaranteed on defeat |

**Hard Combat additional mechanics:** Each Hard Combat enemy also has a chapter-specific special mechanic (e.g., double attack on round 2, HP-threshold stat changes, emergency heal).

### 1b. Difficulty Level Progression

The game ships with Difficulty Level 0 unlocked. After completing a full adventure (reaching any ending — true or false) at the currently unlocked highest difficulty level, the next difficulty level unlocks in the Difficulty System.

| Difficulty Level | Modifier |
| :---: | :--- |
| 0 | No special effects |
| 1 | Chapters 1 and 2: +1 additional Hard Combat node spawns in the map (total node count +1) |
| 2 | Max stamina -2 at adventure start |
| 3 | Adventure starts with 2 "Trash" items in the pocket (occupying 1×1 storage each; cannot be sold) |
(More difficulty level will be added, maximum difficulty level is 40)

**Unlock condition:** Complete a run (any ending) at the current highest unlocked difficulty. The unlock is persistent across sessions — it is saved to the player's save data.

**Subsequent unlocks:** Each subsequent difficulty level (1 → 2 → 3) follows the same unlock condition: beat the current highest difficulty once to unlock the next.

**Scope of modifiers:** Difficulty level modifiers apply to all nodes in the affected chapters for the entire run. They do not selectively affect only certain node types unless explicitly stated.

**Difficulty level display:** The current difficulty level is shown in the UI so the player can track their progression.

### 2. Node Distribution per Chapter

The Map System distributes node types according to chapter counts. Players cannot choose Normal vs Hard — the map generates the count of each type statically.

| Node Type | Ch. 1 | Ch. 2 | Ch. 3 | Ch. 4 | Final |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Normal Combat | 8 | 12 | 16 | 19 | 2 |
| Hard Combat | 4 | 5 | 6 | 9 | 1 |
| Boss | 1 | 1 | 1 | 1 | 1 |

### 3. Normal Combat — Enemy Stat Tables

Enemies are drawn from weighted probability distributions. The player cannot influence which enemy type appears.

**Chapter 1 Normal Combat:**

| HP / ATK | Probability |
| :--- | :---: |
| 8 / 3 | 37% |
| 11 / 2 | 22% |
| 14 / 1 | 31% |
| 15 / 1 | 10% |

**Chapter 2 Normal Combat:**

| HP / ATK | Probability |
| :---: |
| 10 / 5 | 23% |
| 14 / 4 | 18% |
| 19 / 3 | 31% |
| 21 / 2 | 18% |
| 28 / 1 | 10% |

**Chapter 3 Normal Combat:**

| HP / ATK | Probability |
| :---: |
| 13 / 6 | 24% |
| 17 / 5 | 19% |
| 22 / 4 | 26% |
| 29 / 3 | 20% |
| 49 / 1 | 11% |

**Chapter 4 Normal Combat:**

| HP / ATK | Probability |
| :---: |
| 16 / 8 | 21% |
| 25 / 6 | 23% |
| 30 / 4 | 18% |
| 42 / 3 | 16% |
| 66 / 1 | 22% |

**Final Chapter Normal Combat:**

| HP / ATK | Probability |
| :---: |
| 20 / 10 | 19% |
| 28 / 7 | 23% |
| 33 / 5 | 27% |
| 49 / 3 | 20% |
| 81 / 1 | 11% |

### 4. Normal Combat — Loot Tables

#### Chapter 1

**Gold:**

| Gold Amount | Probability |
| :---: | :---: |
| 3 | 17% |
| 4 | 48% |
| 5 | 20% |
| 6 | 15% |

**Consumables (count + type):**

| Count | Probability | Type | Probability |
| :---: | :---: | :---: | :---: |
| 1 | 40% | Stone (石块) | 17% |
| 2 | 40% | Whetstone (磨刀石) | 21% |
| 3 | 20% | Energy Drink (能量饮料) | 31% |
| — | — | Flashlight (手电筒) | 15% |
| — | — | Torch (火把) | 12% |
| — | — | Safe House Key (安全屋房卡) | 4% |

#### Chapter 2

**Gold:**

| Gold Amount | Probability |
| :---: | :---: |
| 4 | 9% |
| 5 | 26% |
| 6 | 43% |
| 7 | 14% |
| 8 | 7% |
| 9 | 1% |

**Consumables (count + type):**

| Count | Probability | Type | Probability |
| :---: | :---: | :---: | :---: |
| 1 | 20% | Stone | 16% |
| 2 | 35% | Whetstone | 19% |
| 3 | 35% | Energy Drink | 31% |
| 4 | 10% | Flashlight | 16% |
| — | — | Torch | 14% |
| — | — | Safe House Key | 4% |

#### Chapter 3

**Gold:**

| Gold Amount | Probability |
| :---: | :---: |
| 6 | 22% |
| 7 | 38% |
| 8 | 25% |
| 9 | 12% |
| 10 | 3% |

**Consumables (count + type):**

| Count | Probability | Type | Probability |
| :---: | :---: | :---: | :---: |
| 2 | 33% | Stone | 15% |
| 3 | 40% | Whetstone | 19% |
| 4 | 17% | Energy Drink | 30% |
| 5 | 10% | Flashlight | 16% |
| — | — | Torch | 16% |
| — | — | Safe House Key | 4% |

#### Chapter 4

**Gold:**

| Gold Amount | Probability |
| :---: | :---: |
| 8 | 22% |
| 9 | 26% |
| 10 | 20% |
| 11 | 18% |
| 12 | 10% |
| 13 | 4% |

**Consumables (count + type):**

| Count | Probability | Type | Probability |
| :---: | :---: | :---: | :---: |
| 2 | 20% | Stone | 13% |
| 3 | 32% | Whetstone | 22% |
| 4 | 38% | Energy Drink | 29% |
| 5 | 7% | Flashlight | 16% |
| 6 | 3% | Torch | 15% |
| — | — | Safe House Key | 5% |

#### Final Chapter

**Gold:**

| Gold Amount | Probability |
| :---: | :---: |
| 10 | 14% |
| 11 | 22% |
| 12 | 34% |
| 13 | 21% |
| 14 | 7% |
| 15 | 2% |

**Consumables (count + type):**

| Count | Probability | Type | Probability |
| :---: | :---: | :---: | :---: |
| 2 | 15% | Stone | 18% |
| 3 | 35% | Whetstone | 22% |
| 4 | 30% | Energy Drink | 23% |
| 5 | 15% | Flashlight | 14% |
| 6 | 5% | Torch | 17% |
| — | — | Safe House Key | 6% |

### 5. Hard Combat — Enemy Stat Tables

Each enemy also has a special mechanic defined in the table.

**Chapter 1 Hard Combat:**

| HP / ATK | Probability | Special Mechanic |
| :---: | :---: | :--- |
| 13 / 4 | 22% | Second enemy turn: attack twice at normal ATK |
| 22 / 3 | 27% | None |
| 26 / 2 | 31% | ATK +1 when HP ≤ 11 |
| 34 / 1 | 20% | One-time: when HP ≤ 15, heal 15 HP instead of attacking |

**Chapter 2 Hard Combat:**

| HP / ATK | Probability | Special Mechanic |
| :---: | :---: | :--- |
| 19 / 6 | 23% | Second enemy turn: attack twice at normal ATK |
| 29 / 5 | 18% | None |
| 32 / 3 | 31% | Damage taken -2 when HP ≤ 17 |
| 41 / 2 | 18% | ATK +2 when HP ≤ 18 |
| 55 / 1 | 10% | One-time: when HP ≤ 23, heal 20 HP instead of attacking |

**Chapter 3 Hard Combat:**

| HP / ATK | Probability | Special Mechanic |
| :---: | :---: | :--- |
| 22 / 7 | 23% | Third enemy turn: attack twice at normal ATK |
| 36 / 6 | 19% | None |
| 39 / 4 | 26% | Damage taken -2 when HP ≤ 19 |
| 48 / 3 | 20% | ATK +2 when HP ≤ 22 |
| 71 / 1 | 12% | One-time: when HP ≤ 34, heal 30 HP instead of attacking |

**Chapter 4 Hard Combat:**

| HP / ATK | Probability | Special Mechanic |
| :---: | :---: | :--- |
| 27 / 8 | 19% | Third enemy turn: attack twice at normal ATK |
| 43 / 7 | 23% | None |
| 44 / 4 | 20% | Damage taken -2 when HP ≤ 21 |
| 61 / 3 | 16% | ATK +3 when HP ≤ 24 |
| 82 / 1 | 22% | One-time: when HP ≤ 38, heal 41 HP instead of attacking |

**Final Chapter Hard Combat:**

| HP / ATK | Probability | Special Mechanic |
| :---: | :---: | :--- |
| 29 / 12 | 19% | Fourth enemy turn: attack twice at normal ATK |
| 47 / 9 | 23% | None |
| 51 / 6 | 27% | Damage taken -2 when HP ≤ 19 |
| 79 / 3 | 20% | ATK +2 when HP ≤ 22 |
| 111 / 1 | 11% | One-time: when HP ≤ 54, heal 55 HP instead of attacking |

### 6. Hard Combat — Loot Tables

#### Chapter 1 Hard

**Gold:**

| Amount | Probability |
| :---: | :---: |
| 7 | 17% |
| 8 | 48% |
| 9 | 20% |
| 10 | 12% |
| 11 | 3% |

**Consumables + Relic:**

| Count | Probability | Type | Probability | Relic | Probability |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 30% | Stone | 15% | 0 relics | 80% |
| 2 | 45% | Whetstone | 21% | 1 relic | 20% |
| 3 | 20% | Energy Drink | 30% | — | — |
| 4 | 5% | Flashlight | 14% | — | — |
| — | — | Torch | 15% | — | — |
| — | — | Safe House Key | 5% | — | — |

#### Chapter 2 Hard

**Gold:**

| Amount | Probability |
| :---: | :---: |
| 8 | 9% |
| 9 | 26% |
| 10 | 43% |
| 11 | 14% |
| 12 | 7% |
| 13 | 1% |

**Consumables + Relic:**

| Count | Probability | Type | Probability | Relic | Probability |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 6% | Stone | 10% | 0 relics | 70% |
| 2 | 41% | Whetstone | 19% | 1 relic | 30% |
| 3 | 41% | Energy Drink | 31% | — | — |
| 4 | 8% | Flashlight | 17% | — | — |
| 5 | 4% | Torch | 17% | — | — |
| — | — | Safe House Key | 6% | — | — |

#### Chapter 3 Hard

**Gold:**

| Amount | Probability |
| :---: | :---: |
| 12 | 17% |
| 13 | 48% |
| 14 | 20% |
| 15 | 12% |
| 16 | 3% |

**Consumables + Relic:**

| Count | Probability | Type | Probability | Relic | Probability |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 2 | 30% | Stone | 11% | 0 relics | 65% |
| 3 | 40% | Whetstone | 21% | 1 relic | 33% |
| 4 | 20% | Energy Drink | 28% | 2 relics | 2% |
| 5 | 8% | Flashlight | 16% | — | — |
| 6 | 2% | Torch | 18% | — | — |
| — | — | Safe House Key | 6% | — | — |

#### Chapter 4 Hard

**Gold:**

| Amount | Probability |
| :---: | :---: |
| 14 | 22% |
| 15 | 26% |
| 16 | 20% |
| 17 | 18% |
| 18 | 14% |

**Consumables + Relic:**

| Count | Probability | Type | Probability | Relic | Probability |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 2 | 20% | Stone | 9% | 0 relics | 50% |
| 3 | 30% | Whetstone | 20% | 1 relic | 45% |
| 4 | 35% | Energy Drink | 29% | 2 relics | 5% |
| 5 | 8% | Flashlight | 18% | — | — |
| 6 | 5% | Torch | 18% | — | — |
| 7 | 2% | Safe House Key | 6% | — | — |

#### Final Chapter Hard

**Gold:**

| Amount | Probability |
| :---: | :---: |
| 14 | 14% |
| 15 | 22% |
| 16 | 34% |
| 17 | 21% |
| 18 | 7% |
| 20 | 2% |

**Consumables + Relic:**

| Count | Probability | Type | Probability | Relic | Probability |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 3 | 25% | Stone | 7% | 0 relics | 35% |
| 4 | 35% | Whetstone | 22% | 1 relic | 60% |
| 5 | 25% | Energy Drink | 26% | 2 relics | 5% |
| 6 | 10% | Flashlight | 18% | — | — |
| 7 | 5% | Torch | 20% | — | — |
| — | — | Safe House Key | 7% | — | — |

### 7. Hard Combat Debuff Tables

At the start of each Hard Combat encounter, exactly 1 debuff is randomly drawn from the chapter's debuff pool. Debuffs persist for the entire encounter.

| Debuff | Effect | Ch. 1 | Ch. 2 | Ch. 3 | Ch. 4 | Final |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| 怯懦 (Cowardice) | Damage dealt -2 | 40% | 30% | 15% | 10% | 0% |
| 虚弱 (Weakness) | End of each enemy turn: enemy ATK +1 | 20% | 20% | 20% | 20% | 3% |
| 出血 (Bleeding) | Start of each player turn: lose 1 stamina | 10% | 15% | 20% | 20% | 25% |
| 颤抖 (Shivering) | Start of each player turn: random 3 action cards cost +1 stamina | 10% | 12% | 15% | 13% | 20% |
| 癫狂 (Mania) | Damage dealt +1, but lose 1 stamina each time you deal damage | 10% | 10% | 15% | 10% | 10% |
| 谵妄 (Delirium) | 10% chance to deal 0 damage on each damage attempt | 7% | 5% | 5% | 10% | 15% |
| 绝望 (Despair) | Lose 6 stamina immediately at encounter start | 3% | 5% | 7% | 10% | 15% |
| 呆滞 (Stupor) | Action count per turn -1 | 0% | 2% | 2% | 4% | 7% |
| 迟疑 (Hesitation) | Skip the first player turn | 0% | 1% | 1% | 3% | 5% |

**Debuff pool evolution:** Cowardice dominates early but disappears by the Final chapter. Despair, Stupor, and Hesitation only appear from Chapter 2 onward. Bleeding and Shivering grow more likely in later chapters.

### 8. Boss Encounters (Regional Pollution Sources)

Each chapter's Boss is stationed at its Regional Pollution Source node. Defeating the Boss is required to advance to the next chapter.

#### Boss Stat Tables

| Chapter | Boss Name | HP | ATK | Debuff | Defeat Reward |
| :--- | :--- | :---: | :---: | :---: | :--- |
| 1 | 悲伤 (Sorrow) | 80 | 4 | 迟疑 (Hesitation) | Gold×20, Random Consumable×5, Random Relic×1, Safe House Key×2, Random Backpack×1 |
| 2 | 嫉妒 (Envy) | 130 | 5 | 怯懦 (Cowardice), 出血 (Bleeding) | Gold×30, Random Consumable×7, Random Relic×1, Safe House Key×2, Random Weapon×1 |
| 3 | 仇恨 (Hatred) | 190 | 6 | 癫狂 (Mania), 谵妄 (Delirium) | Gold×40, Random Consumable×9, Random Relic×2, Safe House Key×3 |
| 4 | 麻木 (Numbness) | 240 | 6 | 虚弱 (Weakness), 呆滞 (Stupor) | Gold×50, Random Consumable×12, Random Relic×2, Safe House Key×3 (only on true ending) |
| Final | 起源 (Origin) | 300 | 7 | 绝望 (Despair), 颤抖 (Shivering) | True Ending |

#### Boss Shared Mechanic — Emergency Heal

Each Boss has the following shared ability:
- **Trigger:** Once per encounter, the first time the Boss's HP drops to ≤ 50% of max HP, the Boss's next action turn is replaced with "Heal 30% of max HP."
- If the Boss is already at ≤ 50% HP when the encounter begins (e.g., after fleeing and returning), the Emergency Heal does not retroactively trigger.
- After the Emergency Heal triggers, all subsequent HP crossings of the 50% threshold have no effect.

#### Boss Individual Special Mechanics

| Chapter | Boss | Special Mechanic |
| :--- | :--- | :--- |
| 1 | 悲伤 (Sorrow) | Start of each enemy turn: heal 5 HP |
| 2 | 嫉妒 (Envy) | Start of each enemy turn: take 6 damage, ATK +1 |
| 3 | 仇恨 (Hatred) | ATK +1/2/3 when HP ≤ 140/80/20 |
| 4 | 麻木 (Numbness) | Skip one player turn when HP drops to ≤ 160. If both 160 and 80 thresholds are crossed in one action, only skip 1 turn total. |
| Final | 起源 (Origin) | Start of each enemy turn: heal 7 HP; ATK +1/2/3 when HP ≤ 180/100/50 |

#### Boss Escape

If the player flees a Boss encounter using the Flee action card:
1. The player is teleported to the nearest Safe House.
2. The Boss retains its current HP.
3. On the next encounter with that Boss, it recovers 50% of its lost HP.

#### Post-Boss Rewards Sequence

After defeating a Boss:
1. Player stamina is fully restored and max stamina +1.
2. Loot sequence plays (gold auto-collected up to cap 99; consumables/relics shown in take/abandon list).
3. Backpack organization screen appears.
4. Next chapter's map generates; play resumes at the new START node.

### 9. Consumable Type Probability Table (Boss and Hard Combat)

Used when drawing random consumable type from the loot table.

| Type | Normal Combat | Hard Combat / Boss |
| :--- | :---: | :---: |
| Stone (石块) | ~17% (varies by chapter) | ~10–18% |
| Whetstone (磨刀石) | ~19–22% | ~19–22% |
| Energy Drink (能量饮料) | ~23–31% | ~26–31% |
| Flashlight (手电筒) | ~14–18% | ~16–18% |
| Torch (火把) | ~12–20% | ~15–20% |
| Safe House Key (安全屋房卡) | ~4–6% | ~5–7% |

## Formulas

### Weighted Random Selection

All enemy stat selection, gold drops, consumable count/type, and relic drops use weighted random selection:

```
roll = rand(0, 100)
cumulative = 0
for each entry in table:
    cumulative += entry.probability
    if roll < cumulative:
        return entry
```

### Enemy Stat Lookup

Enemy HP and ATK are determined by a single joint distribution table. A single roll selects both values simultaneously — there is no separate HP roll and ATK roll.

```
roll = rand(0, 100)
# Match against chapter/tier table to find (hp, atk, mechanic)
```

### Consumable Drop Count Scaling

Consumable count increases with chapter number (no formula — hardcoded per chapter/tier tables above).

### Relic Drop Scaling

Hard Combat relic drop probability increases with chapter:

| Chapter | Relic Drop Chance |
| :--- | :---: |
| 1 | 20% |
| 2 | 30% |
| 3 | 35% (1 relic: 33%, 2 relics: 2%) |
| 4 | 50% (1 relic: 45%, 2 relics: 5%) |
| Final | 40% (1 relic: 60%, 2 relics: 5%) |

When relics drop, they are drawn from the pool of relics unlocked in the player's Survivor Notes. All unlocked relics have equal probability.

## Edge Cases

### EC-1: Fleeing Boss before dealing damage
If the player uses the Flee action card before dealing any damage to a Boss, the Emergency Heal has not triggered. On the next encounter, the Boss is at full HP and the Emergency Heal is still available.

### EC-2: Completing a run on a non-highest unlocked difficulty
If the player unlocks difficulty level 1, then completes a run at difficulty level 0 (instead of level 1), the completion at level 0 does not unlock level 2. Only completing the currently highest unlocked difficulty triggers the next unlock.

### EC-3: Difficulty level modifiers persist for the full run
Once a run starts at a given difficulty level, the modifiers for that level apply for the entire run. Difficulty level cannot be changed mid-run.

### EC-4: Boss Emergency Heal on pre-damaged Boss
If the Boss enters combat at ≤ 50% HP (e.g., player fled, returned without full heal), the Emergency Heal does not trigger retroactively. The Boss must cross the threshold from above 50% to below it during the encounter to trigger.

### EC-5: Consumable count roll exceeds chapter table range
The drop count is clamped to the table's defined range. If the table has no entry for the rolled count, the nearest valid count is used.

### EC-6: Gold drop exceeds cap
Gold is auto-collected up to the cap (99). Any overflow is lost. See the Resource System for details.

### EC-7: Relic drops but no relics unlocked in Survivor Notes
The relic is added to the player's inventory but cannot be activated until the corresponding Survivor Notes entry is unlocked through progression. This creates a "saved relic" moment.

### EC-8: All entries in enemy stat table exhausted
Not applicable — enemy stats are drawn per encounter from the table, not consumed. Each encounter re-rolls independently.

### EC-9: Multiple debuffs from the same debuff pool
Only 1 debuff is drawn per Hard Combat encounter. There is no accumulation of multiple debuffs from a single encounter.

### EC-10: Final chapter — no relics can drop on true ending path
The Final chapter Boss (起源 Origin) has no relic reward. Relics in the Final chapter only drop from Hard Combat nodes. The Final Boss grants the True Ending narrative reward.

## Dependencies

| System | Depends On | Provides |
| :--- | :--- | :--- |
| Combat System | Difficulty System (enemy stats, debuff tables, loot tables, Boss mechanics) | Executes encounters; resolves damage, debuffs, rewards |
| Map Generation System | Difficulty System (node counts per chapter, node type distribution) | Reads chapter node count tables to generate map layouts |
| Reward System | Difficulty System (gold/consumable/relic drop tables) | Executes loot rolls; applies gold to player wallet |
| Survivor Notes System | Difficulty System (relic unlock pool for Hard Combat drops) | Player unlocks relics by progressing chapters; Difficulty reads unlock state to filter relic drops |
| Boss and Chapter Transition System | Difficulty System (Boss tables, special mechanics, emergency heal) | Reads Boss data; handles post-Boss rewards and chapter transition |
| Node Interaction System | Difficulty System (tier identification for scouting) | Player can identify node type before entry |
| Resource System | Difficulty System (gold cap enforcement) | Enforces gold cap of 99 |

## Tuning Knobs

| Knob | Location | Affected Gameplay |
| :--- | :--- | :--- |
| Enemy stat tables per chapter/tier | `res://data/combat/enemy_tables/normal_ch{N}.tres`, `hard_ch{N}.tres` | Difficulty curve, challenge per node |
| Special mechanic tables | `res://data/combat/enemy_tables/hard_ch{N}.tres` | Boss/enemy variety and complexity |
| Gold drop tables per chapter/tier | `res://data/combat/loot_tables/gold_ch{N}_{tier}.tres` | Gold economy pacing |
| Consumable count/type tables | `res://data/combat/loot_tables/consumable_ch{N}_{tier}.tres` | Consumable availability |
| Relic drop chance per chapter | `res://data/combat/loot_tables/relic_ch{N}.tres` | Relic acquisition rate |
| Debuff probability pools per chapter | `res://data/combat/debuff_tables/hard_ch{N}.tres` | Debuff variety and challenge escalation |
| Boss stat and mechanic tables | `res://data/bosses/boss_ch{N}.tres` | Chapter-end difficulty and pacing |
| Boss emergency heal threshold/pct | `res://data/bosses/boss_config.tres` | Boss survivability and fight length |
| Boss flee HP recovery ratio | `res://data/bosses/boss_config.tres` | Boss re-engagement cost |
| Gold cap | `res://data/player/player_config.tres` | Gold economy upper bound |

## Acceptance Criteria

### AC-1: Normal Combat enemy stats match chapter tables
**Test:** Enter Normal Combat in each chapter 100 times. Record the (HP, ATK) pair each time. Compare the empirical distribution against the chapter table.
**Pass criteria:** Each (HP, ATK) pair appears within ±5% of its defined probability across 100 runs.

### AC-1b: Difficulty level unlocks after completing current highest difficulty
**Test:** Start a new run at difficulty level 0. Complete the run (reach any ending). Check the saved difficulty level state.
**Pass criteria:** Difficulty level is now 1. Level 2 is not unlocked yet.

**Test:** Start a new run at difficulty level 1. Complete the run. Check the saved state.
**Pass criteria:** Difficulty level is now 2. Level 3 is not unlocked yet.

**Test:** Start a new run at difficulty level 2. Complete the run. Check the saved state.
**Pass criteria:** Difficulty level is now 3. No higher level exists.

### AC-1c: Difficulty level modifier applies for entire run
**Test:** Start a run at difficulty level 1. During Chapter 1, verify that the map contains 1 extra Hard Combat node compared to the base table. Complete Chapter 1 without dying.
**Pass criteria:** The extra Hard Combat node is present in the map at generation time and remains for the entire run.

**Test:** Start a run at difficulty level 2. Check player max stamina at adventure start.
**Pass criteria:** Max stamina = base max stamina - 2.

**Test:** Start a run at difficulty level 3. Check the player's pocket inventory at adventure start.
**Pass criteria:** Exactly 2 "Trash" items are present in the pocket.

### AC-2: Hard Combat applies exactly 1 debuff
**Test:** Enter Hard Combat without Eye Mask relic 50 times. Log the applied debuff each time.
**Pass criteria:** Exactly 1 debuff in the active debuff list after encounter start for all 50 runs.

### AC-3: Eye Mask blocks Hard Combat debuff draw
**Test:** Equip Eye Mask relic. Enter Hard Combat 20 times. Log active debuffs.
**Pass criteria:** Active debuff count = 0 for all 20 runs with Eye Mask; count = 1 without.

### AC-4: Boss Emergency Heal triggers at 50% HP threshold
**Test:** Deal damage to a Boss until HP crosses from above 50% to below 50%. Log the Boss action on that turn.
**Pass criteria:** Boss heals 30% max HP and does not attack on that turn. A second HP crossing does not trigger another heal.

### AC-5: Fleeing Boss preserves HP and Emergency Heal availability
**Test:** Deal 30% damage to a Boss, then flee. Re-engage the same Boss. Record Boss HP and Emergency Heal status.
**Pass criteria:** Boss HP is at 70% of max on re-entry. Emergency Heal is available (has not triggered).

### AC-6: Consumable type distribution matches table
**Test:** Record consumable type for 100 Normal Combat victories in Chapter 2. Compare against table probabilities.
**Pass criteria:** Each consumable type appears within ±5% of its defined probability.

### AC-7: Gold drop respects cap
**Test:** Set player gold to 95. Enter Normal Combat in Chapter 1 with a guaranteed 6-gold drop. Verify final gold.
**Pass criteria:** Player gold = 99 after combat; 4 gold is lost.

### AC-8: Boss post-victory restores stamina and increases max stamina
**Test:** Defeat Boss with player at 10 stamina remaining. Record stamina and max stamina after victory resolution.
**Pass criteria:** Stamina = new max stamina; max stamina = old max stamina + 1.

### AC-9: Relic drop chance matches chapter table
**Test:** Enter Hard Combat in Chapter 4 (relic chance 50%) 200 times. Count how many times at least 1 relic dropped.
**Pass criteria:** Relic drops in approximately 100 of 200 runs (±10% due to randomness).

### AC-10: Hard Combat special mechanics activate correctly
**Test:** Enter Chapter 1 Hard Combat with the enemy (13/4). On the second enemy turn, log the action taken.
**Pass criteria:** Enemy attacks twice at ATK=4 on the second turn.