# Boss and Chapter Transition System

## Overview

The Boss and Chapter Transition System governs all aspects of Boss encounters and the flow between chapters. Each chapter ends with a Boss node (Regional Pollution Source). Defeating the Boss triggers the chapter transition sequence: rewards, map regeneration, and progression to the next chapter. Chapter 4 additionally branches between the false ending, the true ending path, and the final chapter.

**Scope:** All Boss encounters (Chapters 1–4 + Final), chapter transition sequences, ending determination (true/false), and post-Boss state resets.

**Key characteristics:**
- **Boss is mandatory:** The player cannot advance without defeating each chapter's Boss.
- **Boss HP persists across escape:** If the player flees a Boss fight, the Boss recovers 50% of its lost HP on the next encounter.
- **Victory heals and upgrades:** Defeating a Boss fully restores stamina, increases max stamina by +1, and grants loot.
- **Chapter 4 branches:** The player chooses between the true ending path (with 4 Survivor's Letters) or the false ending.
- **Final Boss grants true ending:** Defeating the Origin Boss completes the game.

## Detailed Rules

### Definitions

- **Boss Node:** A special node at the end of each chapter. Entering it triggers Boss combat automatically.
- **Boss Encounter:** A combat session against a Boss enemy with unique stats, debuffs, and special mechanics.
- **Chapter Transition:** The sequence of events after a Boss is defeated: loot, backpack organization, max stamina increase, and map regeneration.
- **Emergency Heal:** A one-time Boss ability that triggers when the Boss's HP drops to 50% or below for the first time. Notice: if player flee from the boss-combat after triggering boss's Emergency Heal, Emergency Heal **won't** refresh when player re-enter into the combat.
- **Boss Escape:** Fleeing from a Boss fight teleports the player to the nearest Safe House; the Boss does not heal to full.
- **Ending Determination:** Chapter 4's outcome depends on whether the player has collected all 4 Survivor's Letters.
- **True Ending:** Requires collecting 4 Survivor's Letters and defeating the Final Boss (Origin).
- **False Ending:** Triggered when the player lacks 4 Survivor's Letters upon reaching Chapter 4's end, or player manually decide even possess all 4 survivor's letter.

### 1. Boss List

| Chapter | Boss Name | Chinese | HP | ATK | Starting Debuff(s) | Special Mechanic |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| 1 | Sorrow | 悲伤 | 80 | 4 | Hesitation | Heal 5 HP per enemy turn start |
| 2 | Envy | 嫉妒 | 130 | 5 | Cowardice, Bleeding | Take 6 damage per enemy turn start; ATK +1 |
| 3 | Hatred | 仇恨 | 190 | 6 | Madness, Delirium | ATK +1/+2/+3 at HP ≤ 140/80/20 |
| 4 | Numbness | 麻木 | 240 | 6 | Weakness, Dullness | Skip 1 player turn when HP drops to ≤ 160. If HP simultaneously drops to ≤ 80 (i.e., both thresholds crossed in one action), only skip 1 turn total, not 2. |
| Final | Origin | 起源 | 300 | 7 | Despair, Trembling | Heal 7 HP per enemy turn; ATK +1/+2/+3 at HP ≤ 180/100/50 |

**Debuff effects (applied to player at encounter start):**

| Debuff | Chinese | Effect |
| :--- | :--- | :--- |
| Hesitation | 迟疑 | Skip the first player turn entirely |
| Cowardice | 怯懦 | Damage dealt -2 |
| Bleeding | 出血 | Lose 1 stamina at start of each player turn |
| Madness | 癫狂 | Damage dealt +1; lose 1 stamina per damage dealt |
| Delirium | 谵妄 | 10% chance to deal 0 damage per hit |
| Weakness | 虚弱 | Enemy damage +1 per enemy turn end |
| Dullness | 呆滞 | Actions per turn -1 |
| Despair | 绝望 | Lose 6 stamina at encounter start |
| Trembling | 颤抖 | 3 random cards cost +1 stamina |

**Fading Lantern relic** (暗淡提灯) blocks Boss debuffs. If equipped, none of the above debuffs apply.

### 2. Boss Mechanics

#### 2.1 Emergency Heal

All Bosses share this ability:
- **Trigger:** The first time the Boss's HP drops to or below 50% of max HP.
- **Effect:** The Boss's next turn is replaced with "Heal max_hp × 30%". The emergency heal does not stack; it triggers exactly once per encounter.
- **Boss-specific healing:** In addition to the emergency heal, Sorrow heals 5 HP every enemy turn, and Origin heals 7 HP every enemy turn (Origin's emergency heal is separate from its passive heal).

#### 2.2 Sorrow (Chapter 1)

- **Passive heal:** At the start of every enemy turn, Sorrow heals 5 HP.
- **Emergency heal:** When HP ≤ 40, triggers one-time heal of 24 HP (80 × 30%).
- **Attack pattern:** If not healing, attacks with 4 ATK.

#### 2.3 Envy (Chapter 2)

- **Passive damage:** At the start of every enemy turn, the player takes 6 damage.
- **ATK scaling:** Envy's ATK increases by +1 permanently at the start of the encounter.
- **Emergency heal:** When HP ≤ 65, triggers one-time heal of 39 HP (130 × 30%).

#### 2.4 Hatred (Chapter 3)

- **Phase thresholds:** ATK increases based on current HP:
  - HP ≤ 140: ATK +1 (total ATK 7)
  - HP ≤ 80: ATK +2 (total ATK 8)
  - HP ≤ 20: ATK +3 (total ATK 9)
- **Emergency heal:** When HP ≤ 95, triggers one-time heal of 57 HP (190 × 30%).

#### 2.5 Numbness (Chapter 4)

- **Turn skip:** When HP drops to or below 160 or 80, Numbness skips one of the player's turns on its next turn (not a heal, but a forced skip).
- **Emergency heal:** When HP ≤ 120, triggers one-time heal of 72 HP (240 × 30%).
- **Rewards:** Chapter 4 Boss rewards are conditional — if entering the false ending, no rewards are granted. If entering the true ending (or completing the final chapter), full rewards are granted.

#### 2.6 Origin (Final Boss)

- **Passive heal:** At the start of every enemy turn, Origin heals 7 HP.
- **Phase thresholds:** ATK increases based on current HP:
  - HP ≤ 180: ATK +1 (total ATK 8)
  - HP ≤ 100: ATK +2 (total ATK 9)
  - HP ≤ 50: ATK +3 (total ATK 10)
- **Emergency heal:** When HP ≤ 150, triggers one-time heal of 90 HP (300 × 30%).
- **Victory:** Defeating Origin grants the True Ending. The game ends with a victory screen.

### 3. Boss Combat Rules

#### 3.1 Arrival

- Entering a Boss node triggers combat immediately. There is no choice to avoid it.
- The Boss node is always visible (not fog-of-war hidden), even before adjacent nodes are explored.
- The player cannot leave the Boss node without either defeating the Boss or fleeing.

#### 3.2 Flee from Boss

- The player may flee only by using the Flee action card. Stones are unavaliable in Boss combat.
- Flee cost follows the normal Flee card rules (base 5, reduced by Durable Wire relic and Escape Master Survivor Note, minimum 1).
- Upon fleeing:
  1. Deduct flee stamina cost.
  2. Teleport player to the nearest Safe House node.
  3. The Boss node remains uncleared.
  4. On the next Boss encounter, the Boss recovers 50% of the HP it had lost: `boss_hp = boss_hp + (boss_max_hp - boss_hp) × 0.5`.
- The player may return to the Boss node and fight again.

#### 3.3 Victory

1. The Boss is defeated. Node becomes **Cleared**.
2. **Stamina:** Fully restored to current max stamina.
3. **Max stamina:** Increased by +1 for the remainder of the adventure.
4. **Loot sequence:** Present Chapter 4 conditional rewards or standard Boss rewards (see Loot section).
5. **Backpack organization:** Backpack organization screen appears (same take/abandon flow as normal combat).
6. **Chapter transition:** Load the next chapter's map (or ending screen if Final chapter).

#### 3.4 Death

- If player stamina drops to 0 or below and no Adrenaline Needle or Last Effort is available, permadeath triggers immediately.
- All progress is lost. The next adventure starts from Chapter 1.

### 4. Boss Loot

#### 4.1 Standard Boss Rewards (Chapters 1–3)

| Item | Quantity | Notes |
| :--- | :--- | :--- |
| Gold | Chapter-dependent | See loot table below |
| Random Consumables | Chapter-dependent | See consumable distribution |
| Random Relic | 1 (Ch1–3) | From currently unlocked relic pool; equal probability |
| Safe House Key | 2 (Ch1–3) | Always included |
| Random Weapon | 1 (Ch2 only) | Ch1 and Ch3 Bosses do not drop weapons |
| Random Backpack | 1 (Ch1 only) | Ch2–3 Bosses do not drop backpacks |

**Gold rewards:**

| Chapter | Gold |
| :--- | :--- |
| 1 | 20 |
| 2 | 30 |
| 3 | 40 |

#### 4.2 Chapter 4 Conditional Rewards

Chapter 4 Boss (Numbness) rewards depend on the ending:

- **False ending triggered:** No loot is granted. The player is taken directly to the ending screen.
- **True ending path or Final chapter:** Full loot is granted:

| Item | Quantity |
| :--- | :--- |
| Gold | 50 |
| Random Consumables | 12 |
| Random Relic | 2 |
| Safe House Key | 3 |

#### 4.3 Boss Consumable Distribution

All Bosses use the same consumable probability table:

| Consumable | Probability |
| :--- | :-: |
| Whetstone | 23% |
| Stone | 8% |
| Energy Drink | 32% |
| Flashlight | 17% |
| Torch | 20% |

### 5. Chapter Transition

#### 5.1 Transition Sequence (Chapters 1–3)

After defeating the Boss:

1. **Victory announcement:** Brief victory screen with Boss name.
2. **Stamina restore:** Player stamina set to new max (old max + 1).
3. **Loot sequence:** Present loot one item at a time with Take/Abandon. Gold is manually collected.
4. **Backpack organization:** Open backpack organization screen. Player can rearrange, discard, or equip items.
5. **Map regeneration:** Discard the current chapter's map. Generate a fresh map for the next chapter.
6. **Player placement:** Place player token on the START node of the new chapter.
7. **Resume play.**

#### 5.2 Transition from Chapter 4

Chapter 4 has a branching decision point after defeating Numbness:

**Step 1: Check Survivor's Letters.**
Count the number of Survivor's Letters held in inventory.

**Step 2a: Less than 4 Letters — False Ending.**
- No loot is granted.
- Display the false ending screen.
- Adventure ends. All progress is lost. Return to main menu.
- Progress is saved to Survivor Notes (gold accumulated, nodes visited, etc.).

**Step 2b: Exactly 4 Letters — Ending Choice.**
The player is presented with two options:

- **拆封阅读 (Open and Read):** Enter the Final Chapter. The 4 Survivor's Letters are consumed. Proceed to the Final Chapter map.
- **恪尽职守 (Fulfill Your Duty):** Enter the false ending. No loot is granted. Adventure ends.

Both options consume the chapter transition resources. The choice is final and cannot be undone.

#### 5.3 Final Chapter Transition

After defeating the Final Boss (Origin):

1. Display the true ending screen.
2. All progress is saved to Survivor Notes.
3. Adventure ends. Return to main menu.

### 6. Map and State on Chapter Transition

#### 6.1 Previous Chapter Map

- The previous chapter's map is permanently discarded after transition.
- All nodes, connections, and state (cleared nodes, ruins counters, etc.) are lost.
- The player cannot return to a previous chapter's map.

#### 6.2 Inventory Persistence

- All items, relics, gold, and weapons persist across chapter transitions.
- Max stamina increase applies immediately and carries forward.
- Adrenaline Needle used flag persists across the adventure (once used, it is gone for the remainder of that adventure).

#### 6.3 Safe House Resources

- Safe House Fridge, Piggy Bank, and Anvil uses are **per-chapter**.
- After transitioning to a new chapter, all Safe House resources in the new chapter are refreshed to their per-visit limits (not accumulated from the previous chapter).

#### 6.4 Quest State

- Active quests from the previous chapter are abandoned.
- The Survivor's Letter from each chapter's Quest is granted upon quest completion and persists in inventory.
- If the player leaves a chapter without completing the Quest, the quest is silently failed.

## Formulas

### Boss Emergency Heal

```
if boss_hp <= boss_max_hp * 0.5 and not emergency_heal_used:
    boss_hp += boss_max_hp * 0.3
    emergency_heal_used = true
```

- The emergency heal replaces the Boss's next attack action.
- Sorrow's passive heal (5 HP/turn) and Origin's passive heal (7 HP/turn) are separate from the emergency heal and do not consume the emergency heal flag.

### Boss HP Recovery on Escape

```
boss_hp_on_reenter = boss_hp + (boss_max_hp - boss_hp) * 0.5
```

| Variable | Example |
| :--- | :--- |
| Boss at 30 HP / 80 max (Sorrow) after partial fight | Recovers 50% of lost HP = 30 HP, becomes 60 HP |
| Boss at 0 HP (defeated) | N/A — node is cleared and cannot be re-entered |

### Chapter 4 Ending Decision

```
if letters_held == 4:
    show_ending_choice_dialog()
else:
    trigger_false_ending()
```

### Max Stamina After Boss Victory

```
new_max_stamina = previous_max_stamina + 1
player_stamina = new_max_stamina  # full restore
```

- The +1 bonus stacks across all Bosses in an adventure: up to +5 by defeating all 5 Bosses starting from base 12 = max 17, or +4 starting from base 16 (with Wayfarer stage 4) = max 20.

## Edge Cases

### E1. Boss Emergency Heal Triggered on Same Turn as Death

If the player's action reduces the Boss to ≤ 50% HP and that same action kills the Boss:
1. The Boss dies before its next turn.
2. The emergency heal does **not** trigger because the Boss is already dead.
3. Loot sequence begins immediately.

### E2. Adrenaline Needle Against Boss Passive Damage

If the player has Adrenaline Needle and Envy's passive damage (6 HP per enemy turn) would reduce stamina to ≤ 0:
1. The passive damage is applied.
2. Adrenaline Needle triggers, setting stamina to 10.
3. The relic is destroyed.
4. Combat continues. The enemy turn ends normally.

### E3. Boss Escape with Adrenaline Needle Used

If the player flees the Boss and later returns:
- The Boss recovers 50% of lost HP normally.
- Adrenaline Needle is already destroyed from the previous attempt; the player must proceed without it.

### E4. Boss Fight with Despair Debuff

Despair deducts 6 stamina at encounter start. If this reduces stamina to ≤ 0:
1. Adrenaline Needle triggers if available (sets to 10, destroys relic).
2. If Adrenaline Needle is not available, the player dies before combat begins.

### E5. Chapter 4 with Full Inventory and No Space

If the player enters Chapter 4 with full inventory and then defeats Numbness:
- The Take/Abandon flow for Chapter 4 loot (if true ending path is chosen) still requires the player to make space.
- If the player cannot make space, items are abandoned.
- The ending choice dialog appears after all loot is resolved.

### E6. Last Effort Against Boss

Last Effort can be declared on the Boss if the player declares it on a damaging action (Unarmed Attack, Weapon Attack, Torch) while lacking sufficient stamina. The same rules apply as in normal combat:
- If the action kills the Boss, Last Effort triggers and restores stamina to `last_effort_recovery`.
- If the Boss survives, the player dies after the action resolves.

### E7. Sorrow Passive Heal Stacking with Emergency Heal

Sorrow heals 5 HP every enemy turn. If Sorrow reaches 50% HP and triggers emergency heal (30% of 80 = 24 HP), both heals apply:
- The emergency heal is a single large heal.
- The passive 5 HP heal continues to apply on subsequent enemy turns.
- These are independent.

### E8. Numbness Skip Applied to Last Effort Turn

If the player declares Last Effort against Numbness and the Boss skips the player's next turn, the skip is applied after Last Effort resolves:
1. Player declares Last Effort, kills Numbness, Last Effort restores stamina.
2. Numbness is defeated before its next turn, so the skip has no effect.

### E9. Chapter 4 True Ending Path — Loot Before Choice

The loot sequence (consumables, relics, gold, keys) is presented after defeating Numbness but **before** the ending choice dialog appears. This means the player receives Chapter 4 Boss loot even if they then choose the false ending.

Exception: If the player has fewer than 4 Survivor's Letters, no loot is presented and the false ending triggers immediately.

### E10. Four Survivor's Letters — All Consumed on True Ending

When the player chooses "拆封阅读" (Open and Read) at Chapter 4's end: 
- All 4 Survivor's Letters are removed from inventory simultaneously.
- The player cannot retain any Survivor's Letters for later use.

### E11. Flee from Boss at Full Stamina

If the player flees from a Boss at full stamina, the Flee card still costs stamina (reduced by Durable Wire and Escape Master). The stamina deduction is applied as normal.

### E12. Dim Lantern Blocks Boss Debuffs But Not Envy Passive Damage

Dim Lantern suppresses the debuff application (Hesitation, Cowardice, Bleeding, etc.) but does **not** block Envy's passive 6-damage-per-turn effect. The passive damage is part of Envy's special mechanic, not a debuff applied to the player.

### E13. Boss Node Cleared After Victory

After defeating a Boss, the Boss node becomes Cleared. The player cannot re-enter the Boss node or fight the same Boss again in the same adventure.

### E14. Safe House Resources Reset on Chapter Transition

Each chapter has its own set of Safe House nodes. Resources (Fridge uses, Piggy Bank gold amount, Anvil uses) are determined per chapter and reset when transitioning, regardless of whether the player used those Safe Houses.

### E15. Heart of Hope Triggers on Chapter Transition

The Heart of Hope relic (希望之心) grants 1 random relic at the start of each new chapter. This triggers **before** the chapter map loads, as part of the transition sequence. The relic goes through the Take/Abandon flow before gameplay resumes.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Boss combat uses combat rules; Boss debuffs apply at encounter start; emergency heal checked per Boss turn; loot granted after victory |
| **Backpack & Inventory System** | Loot Take/Abandon flow; backpack organization screen after loot; inventory space checks |
| **Survivor Notes System** | Tracks Bosses defeated, chapter progress, letter collection; applies unlocks on adventure end |
| **Map Generation System** | Generates the next chapter's map on transition; discards previous chapter's map |
| **Node Interaction System** | Boss node arrival triggers combat; Flee card returns to nearest Safe House; Safe House resources reset per chapter |

### Systems That Depend On This

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Reads Boss stats, debuffs, emergency heal from this document; applies Boss-specific phase mechanics |
| **Survivor Notes System** | Increments chapter progress, saves unlocks when Boss is defeated |
| **Save/Load System** | Must serialize: current chapter, Boss HP (for escape recovery), Survivor's Letter count, ending choice state |
| **UI / Rendering System** | Displays Boss health bar, victory screen, ending screens (true/false), loot sequence |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `SORROW_PASSIVE_HEAL` | 5 HP/turn | 3–8 | Sorrow's HP recovery every enemy turn |
| `ENVY_PASSIVE_DAMAGE` | 6 HP/turn | 4–10 | Damage dealt to player every enemy turn by Envy |
| `ORIGIN_PASSIVE_HEAL` | 7 HP/turn | 5–12 | Origin's HP recovery every enemy turn |
| `BOSS_EMERGENCY_HEAL_PCT` | 30% | 20–40% | HP percentage restored when Boss reaches 50% HP |
| `BOSS_ESCAPE_HP_RECOVERY_PCT` | 50% | 25–75% | HP recovered by Boss when player re-enters after fleeing |
| `BOSS_MAX_STAMINA_BONUS` | +1 | 0–2 | Max stamina increase per Boss defeated |
| `CHAPTER4_BOSS_GOLD` | 50 | 30–80 | Gold reward from Chapter 4 Boss (true ending) |
| `CHAPTER4_BOSS_CONSUMABLES` | 12 | 8–20 | Consumable count from Chapter 4 Boss (true ending) |
| `CHAPTER4_BOSS_RELICS` | 2 | 1–3 | Relic count from Chapter 4 Boss (true ending) |
| `FINAL_BOSS_HP` | 300 | 200–400 | Final Boss (Origin) HP |
| `FINAL_BOSS_ATK` | 7 | 5–10 | Final Boss (Origin) base ATK |

## Acceptance Criteria

### AC1. Boss Arrival and Automatic Combat
- [ ] Move onto a Boss node. Verify combat starts automatically with no prompt.
- [ ] Verify the correct Boss for the current chapter is spawned.

### AC2. Boss Emergency Heal
- [ ] Fight Chapter 1 Boss (Sorrow). Reduce its HP to exactly 40 (≤ 50% of 80).
- [ ] Verify its next turn is "Heal 24 HP" instead of an attack.
- [ ] Verify this happens only once per encounter.

### AC3. Boss Escape and HP Recovery
- [ ] Fight Chapter 1 Boss, deal 20 damage (leaving 60 HP), then flee.
- [ ] Re-enter the same Boss. Verify its HP is 70 (60 + 10 = 70, recovering 50% of the 20 damage lost).
- [ ] Defeat the Boss. Verify no further emergency heal is possible.

### AC4. Boss Victory — Stamina Restore and Max Increase
- [ ] Defeat Chapter 1 Boss with 3 stamina remaining and max stamina 12.
- [ ] Verify stamina is fully restored to 13.
- [ ] Verify max stamina is now 13 for the remainder of the adventure.

### AC5. Boss Victory — Loot Sequence
- [ ] Defeat Chapter 1 Boss. Verify loot includes gold, consumables, relic, keys, and backpack.
- [ ] Verify each item is presented with Take/Abandon.
- [ ] Verify backpack organization screen appears after loot.

### AC6. Chapter 1 → Chapter 2 Transition
- [ ] Defeat Chapter 1 Boss. Complete loot and backpack organization.
- [ ] Verify Chapter 2 map is generated and player is placed on Chapter 2 START node.
- [ ] Verify previous chapter's map is no longer accessible.

### AC7. Chapter 4 — False Ending (Fewer Than 4 Letters)
- [ ] Enter Chapter 4 with 3 Survivor's Letters. Defeat Numbness.
- [ ] Verify no loot is presented. Verify false ending screen appears immediately.
- [ ] Verify adventure ends and progress is saved.

### AC8. Chapter 4 — True Ending Path Choice
- [ ] Enter Chapter 4 with 4 Survivor's Letters. Defeat Numbness.
- [ ] Verify loot is presented. Complete loot flow.
- [ ] Verify ending choice dialog appears with "Open and Read" and "Fulfill Your Duty" options.

### AC9. Chapter 4 — True Ending Path (Open and Read)
- [ ] With 4 Survivor's Letters, defeat Numbness, complete loot, choose "Open and Read."
- [ ] Verify all 4 Survivor's Letters are removed from inventory.
- [ ] Verify Final Chapter map is generated.

### AC10. Final Boss — True Ending
- [ ] Defeat the Final Boss (Origin). Verify true ending screen appears.
- [ ] Verify adventure ends and progress is saved.

### AC11. Boss Debuff Application
- [ ] Fight Chapter 1 Boss (Hesitation) without Dim Lantern. Verify first player turn is skipped.
- [ ] Fight Chapter 2 Boss (Cowardice, Bleeding). Verify damage -2 and bleeding ticks.
- [ ] Equip Dim Lantern. Fight Chapter 1 Boss again. Verify no debuffs apply.

### AC12. Sorrow Passive Heal
- [ ] Fight Sorrow for 5 enemy turns without dealing lethal damage.
- [ ] Verify Sorrow heals 5 HP each of those 5 turns.

### AC13. Envy Passive Damage
- [ ] Fight Envy for 3 enemy turns. Verify player takes 6 damage at the start of each enemy turn.
- [ ] Verify Envy's ATK starts at 5 (base) + 1 = 6 from the encounter start bonus.

### AC14. Heart of Hope on Chapter Transition
- [ ] Equip Heart of Hope. Defeat Chapter 1 Boss.
- [ ] Verify a random relic is offered before Chapter 2 map loads.
- [ ] Accept the relic if space allows; verify it is in inventory.

### AC15. Safe House Resources Reset on Transition
- [ ] Use a Safe House in Chapter 1 (consume all Fridge Energy Drinks).
- [ ] Defeat Chapter 1 Boss. Transition to Chapter 2.
- [ ] Enter a Chapter 2 Safe House. Verify Fridge has full uses (not depleted from Chapter 1).

### AC16. Dim Lantern Blocks Boss Debuffs But Not Envy Passive Damage
- [ ] Equip Dim Lantern. Fight Envy.
- [ ] Verify Cowardice and Bleeding debuffs do not apply.
- [ ] Verify the 6-damage-per-enemy-turn effect still applies (Dim Lantern does not block it).
