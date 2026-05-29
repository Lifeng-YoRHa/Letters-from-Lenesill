# UI System

## Overview

The UI System governs all visual presentation, user interaction, and screen-to-screen flow in Babel Archive. It covers the main game screens (map, combat, inventory, shop, safe house), the HUD elements displayed during gameplay, and the flow between screens triggered by game state transitions. All UI is rendered through Godot's scene system — no immediate-mode GUI.

**Scope:** All screens, overlays, HUD elements, navigation flows, and input routing. Does not cover game logic (that belongs to respective system documents) but does specify what triggers each UI state and what data it displays.

**Key characteristics:**
- **Scene-based UI:** Each major UI surface is a Godot scene (`*.tscn`). Overlays use `CanvasLayer` or `Window` nodes within the game scene.
- **Data-driven display:** UI always reads from game state; it never owns authoritative data.
- **Turn-gated combat UI:** Combat UI disables non-action inputs during enemy turns and animation sequences.
- **Layered overlays:** Shop, Safe House, Backpack, Card Detail, and Ending screens stack over the game view using `CanvasLayer` nodes with configurable modal behavior.

## Detailed Rules

### Definitions

- **Game View:** The primary gameplay scene — the map view during exploration, or the combat view during fights. Always visible beneath overlays.
- **HUD (Heads-Up Display):** Persistent on-screen elements showing player vitals (stamina bar, gold count, chapter indicator) and quick-access buttons (menu, inventory toggle).
- **Overlay:** A `CanvasLayer` or `Window` that covers the Game View partially or fully, pausing game logic behind it if modal.
- **Modal Overlay:** An overlay that blocks input to the Game View until dismissed.
- **Non-Modal Overlay:** An overlay that allows the Game View to continue responding to input behind it.
- **Screen:** A full replacement of the current scene (e.g., Main Menu → Game). Transitions use a fade-to-black tween.
- **Take/Abandon Flow:** A loot presentation pattern where each item is shown one at a time with Take or Abandon buttons. The player must decide on each item before proceeding.
- **Card Slot:** A fixed slot in the Combat UI that holds one action card. Cards are dragged from the hand area into active slots.
- **Active Slot:** One of the 3 (or more) card slots that are activated for the current turn. Active slots accept card drops.

### 1. Screen List

#### 1.1 Main Menu

**Trigger:** Game launch, returning from any ending, or pressing "Return to Main Menu."

**Elements:**
- Game title ("Letters from Lenesill" / 兰奈希尔的信件)
- "New Adventure" button
- "Continue" button (if a save exists)
- "Survivor Notes" button
- "Settings" button
- Version / credits text

**Flow:**
- New Adventure → Difficulty Selection → Optional Carry → Game scene loads at Chapter 1 START.
- Continue → Game scene loads at the saved chapter and player position.
- Survivor Notes → Survivor Notes screen (see section 4.4).
- Settings → Settings panel (audio, keybindings, accessibility).

#### 1.2 Difficulty Selection

**Trigger:** Pressing "New Adventure" from Main Menu.

**Elements:**
- Title: "Select Difficulty" (难度选择)
- Difficulty buttons: 0 through N (where N = highest unlocked difficulty)
- Description text per difficulty (provided by Difficulty System)
- "Confirm" button

**Flow:**
- Confirm → Optional Carry screen → Game scene.

#### 1.3 Optional Carry Screen

**Trigger:** After Difficulty Selection (new adventure) or returning from any ending.

**Elements:**
- Title: "Survivor Notes" (幸存者笔记)
- Display of current note bonuses (max stamina, starting gold, etc.)
- Two buttons:
  - "Carry Buffs" (携带增益): Apply all Survivor Note bonuses this run.
  - "Disable Buffs" (禁用增益): Start with base values this run. Unlocked relics remain available.

**Flow:**
- Either choice → Game scene loads.

#### 1.4 Game Scene (Exploration Mode)

The persistent game scene. Contains the Game View (map or combat) and the HUD.

**Elements:**
- **Map View (Exploration):** Displays the procedurally generated chapter map with fog of war, node icons, connections, and the player token.
- **HUD:** Stamina bar (filled/empty visual), current/max stamina text, gold count, chapter indicator, menu button (hamburger), inventory quick-toggle button.
- **Mini-map:** Small overview showing chapter structure (optional, if screen space allows).
- **Backpack Entrance** Enter into Backpack Screen.

**Trigger:** Automatically entered after Optional Carry resolution.

#### 1.5 Game Scene (Combat Mode)

The same persistent game scene, but the Game View switches to combat layout.

**Elements:**
- **Player Stats Panel (left):** Current/max stamina bar, weapon slot (with durability), active debuff icons.
- **Player Display** Player figure displayed at the left of the screen.
- **Action Card Area (bottom):** Hand of available action cards. Cards can be dragged into Active Slots.
- **Active Slots (center-bottom):** Fixed slots (3 by default) that define which cards are activated for the current turn. Filled by drag-and-drop.
- **Enemy Display (right):** Enemy sprite or icon, HP bar, name, active debuff icons, intent indicator (what the enemy will do next turn).
- **Pocket Quick-Access (bottom-left corner):** A condensed view of the two pocket mini-grids. Items here can be used without opening the full backpack.
- **End Turn Button:** Prominent button to end the player's turn after taking actions. Disabled if no actions have been taken.

**Combat-specific behaviors:**
- Active slots are populated at the start of each player turn by random draw from the full deck (size = activated cards per turn, default 3).
- Cards in active slots can be used in any order during the turn.
- Enemy turn auto-plays after the player ends the turn.
- During enemy turn, all input except forced survival choices (Adrenaline Needle, Last Effort) is disabled.

**Flow:**
- Combat ends → Loot Take/Abandon flow → Exploration Mode or next Combat or Boss End sequence.

#### 1.6 Loot Overlay (Take/Abandon)

**Trigger:** After combat victory (Normal Combat, Hard Combat, Boss).

**Elements:**
- Loot item displayed large in center (icon, name, description).
- "Take" button (bottom-left).
- "Abandon" button (bottom-right).
- Item counter ("Item 3 of 7").
- Gold counter (if gold is among loot).

**Behavior:**
- Each item is presented sequentially.
- If the item is gold, "Take" adds to gold counter directly (no inventory check).
- If the item is a consumable/relic/weapon, Take attempts to add to inventory. If inventory is full, the player is prompted to make space (rearrange or abandon existing items) before deciding.
- Abandon skips the item with no further action.
- After the last item, the overlay closes and game resumes.

#### 1.7 Backpack Screen (Full Overlay)

**Trigger:** Pressing the inventory quick-toggle button, or playing the "翻找背包" (Search Backpack) action card in combat.

**Elements:**
- **Backpack Grid:** The full backpack grid for the current backpack type. Items are displayed as draggable icons within the grid. Empty cells show as outlined slots.
- **Pocket Grids:** Two 1×2 (or 1×3 with Magician upgrade) mini-grids. Items in pocket are accessible during combat without opening the full backpack.
- **Equipped Weapon Slot:** A highlighted slot showing the currently equipped weapon (if any), with durability display.
- **Equipped Relic Slots:** Row of relic slots showing equipped relics.
- **Stats Summary (side panel):** Current max stamina, current stamina, gold held, chapter progress.
- **Close Button:** Returns to game view.

**Behavior:**
- In exploration: Full interaction allowed. Items can be dragged between grid cells, between backpack and pocket, and equipped/unequipped.
- In combat: Backpack screen can be opened, but only pocket items can be interacted with. Backpack items require playing "翻找背包" first.
- Closing the backpack does NOT end the player's turn in combat.

#### 1.8 Shop Overlay (Black Market)

**Trigger:** Arriving at a Black Market node (see Node Interaction System and Shop System).

**Elements:**
- **Shop Title Bar:** "黑市" (Black Market) with chapter lock indicator.
- **5-Slot Stock Grid:** Each slot shows item icon, name, buy price (with Friendship Token discount applied), and quantity.
- **Inventory Panel (right or bottom):** Scrollable list of inventory items available for selling, with sell prices.
- **Gold Display:** Current gold at top.
- **Buy/Sell Toggle (or separate tabs):** Switch between buy mode and sell mode.
- **Close Button:** Returns to map. Stock is locked for the remainder of the chapter.
- **Backpack Entrance** Enter into Backpack Screen.

**Behavior:**
- Clicking a stock item in buy mode attempts purchase. If gold is sufficient and inventory has space, transaction completes.
- Clicking an inventory item in sell mode attempts sale. If item is in inventory, gold is added and item removed.
- Full shop system rules (stock generation, price formula, Friendship Token discount) are in Shop System.

#### 1.9 Safe House Overlay

**Trigger:** Arriving at a Safe House node.

**Elements:**
- **Safe House Title:** "安全屋" (Safe House).
- **Fridge Panel:** Shows available Energy Drinks from fridge. "Use" button per drink. Shows uses remaining (per-visit limit).
- **Piggy Bank Panel:** Shows gold currently stored in the piggy bank for this chapter. "Deposit" and "Withdraw" buttons.
- **Anvil Panel:** Shows available weapon repair uses. "Repair" button. Lists current weapon durability if equipped.
- **Rest Button:** Option to rest and restore stamina (if not already at max). Cost: 1 Safe House Key.
- **Close Button:** Returns to map.

**Behavior:**
- All Safe House resource quantities reset per chapter transition. Details in Node Interaction System.
- Fridge, Piggy Bank, and Anvil use per-visit limits are defined in Survivor Notes System (Scholar entry).

#### 1.10 Random Event Overlay (突发事件)

**Trigger:** Arriving at a Random Event node.

**Elements:**
- **Event Title Bar:** Name of the event type (e.g., "偷窃" / "抢劫" / "顺风车" / "尸体" / "密码箱" / "毁灭的营地" / "赌徒" / "破烂集市" / "将熄的火堆").
- **Event Illustration Area:** Visual representation of the event (e.g., shadowy figure for Theft, gambling table for Gambler).
- **Event Description:** Narrative text describing what is happening.
- **Choice Panel:** One or more buttons presenting the available choices for this event. Each choice shows the cost and the potential outcome.
- **Stamina/Gold Cost Display:** Shows what will be paid if the player takes the choice.
- **"Do Nothing" Button (if applicable):** Allows the player to opt out of the event.
- **Close Button:** Returns to map (only available after the event is resolved or "Do Nothing" is chosen). The node transitions to "普通道路" after leaving.

**Behavior by Event Type:**

| Event | Choices | UI Elements Specific to This Event |
| :--- | :--- | :--- |
| 偷窃 (Theft) | — | "Continue" button only. Shows which 2 items were stolen (or empty if Badge blocks it). |
| 抢劫 (Robbery) | "Pay Half Gold" / "Fight" | For "Pay Half Gold": gold cost shown with floor-half calculation. For "Fight": triggers combat transition. |
| 顺风车 (Hitchhike) | "Pay 2 Gold + Choose Destination" / "Do Nothing" | After paying, a node selection list appears showing all non-Boss nodes on the map. Selected node is highlighted and player teleports there. |
| 尸体 (Corpse) | "Search (Cost 3 Stamina)" / "Do Nothing" | If searching: loot roll from the ruins table; loot Take/Abandon overlay appears. |
| 密码箱 (Locked Box) | "Attempt Code (Cost 1 Stamina)" / "Do Nothing" | After choosing to attempt: a 2-digit code input UI appears (two columns of 0–9 digits). Feedback shown: "Higher" / "Lower" / "Correct!" per digit. Loop until correct or player closes. |
| 毁灭的营地 (Destroyed Camp) | "Fight" | Triggers Hard Combat. Loot includes bonus Locked Box on victory. |
| 赌徒 (Gambler) | "Bet (1–10 Gold) + Play" / "Do Nothing" | A slider or number input for bet amount. Then a simplified Blackjack UI (player vs dealer). Result: "Win" / "Lose" / "Push". |
| 破烂集市 (Rogue Market) | — | The node transforms into a temporary Black Market. Shop overlay appears immediately. Leaving reverts the node to "普通道路". |
| 将熄的火堆 (Dying Embers) | — | "Continue" button. Stamina is restored automatically (+8). Animation: warm glow effect on the stamina bar. |

**Common behaviors:**
- All events (except "Do Nothing") advance the node to **Cleared** state. The node becomes "普通道路" after the player leaves.
- If the player lacks the required resources (e.g., 2 gold for Hitchhike but only 1 gold), the choice button is disabled (grayed out) with a tooltip explaining why.
- During the 21-point game (Gambler), the simplified Blackjack UI shows: dealer's hand (face-down + one face-up card), player's hand (all face-up), action buttons (Hit / Stand), and a "Fold" button to abandon the game and lose the bet.
- The Locked Box code input uses two digit selectors (0–9 each). Each confirmed guess costs 1 stamina. Feedback arrows appear after each guess.

**Flow:**
- Enter event → Read description → Choose action → Resolve outcome → (If loot/combat → Loot/Combat overlay) → Event overlay closes → Node becomes "普通道路" → Return to map.

#### 1.11 Card Detail Overlay

**Trigger:** Clicking or hovering over an action card (exploration or combat) for 0.5 seconds, or right-clicking.

**Elements:**
- Card name in large text.
- Illustration area (placeholder or art).
- Stamina cost.
- Effect description in full.
- "Close" button or click-outside-to-dismiss.

**Behavior:**
- Non-modal: player can still interact with the game while the overlay is open.
- In combat, clicking a card during the hold-preview period shows this overlay.

#### 1.12 Item Detail Overlay

**Trigger:** Clicking or hovering over an item (consumable, relic, weapon) in inventory, shop, or loot screen for 0.5 seconds.

**Elements:**
- Item name and type (consumable / relic / weapon).
- Effect description.
- For weapons: current/max durability, attack power.
- For relics: effect text, whether currently equipped.
- For consumables: usage effect.
- "Close" button.

**Behavior:**
- Non-modal.
- In shop buy mode, shows the same detail with buy price and stock remaining.
- In shop sell mode, shows the same detail with sell price.

#### 1.13 Ending Screens

**False Ending Screen:**
- Full-screen overlay (modal).
- Title: 假结局 (False Ending).
- Narrative text (narrative content from Narrative Director).
- Statistics summary (chapters completed, gold earned, nodes visited).
- "Return to Main Menu" button.

**True Ending Screen:**
- Full-screen overlay (modal).
- Title: 真结局 (True Ending).
- Narrative text (narrative content from Narrative Director).
- Statistics summary (all chapters completed, final boss defeated, letters collected).
- "Return to Main Menu" button.

**Flow:** Both ending screens return to Main Menu. Survivor Notes are written before the screen is dismissed (see Ending System).

#### 1.14 Survivor Notes Screen

**Trigger:** Pressing "Survivor Notes" on the Main Menu or from the pause/menu overlay.

**Elements:**
- **Tab Navigation:** List of written note entries, grouped by category (combat, exploration, economy, meta).
- **Entry View:** When an entry is selected:
  - Entry name (Chinese + English).
  - Description / lore text.
  - Current progress bar toward next stage.
  - Reward description.
  - "Already Completed" badge if fully written.
- **Summary Panel:** Total entries written, total stages completed, next reward preview.

**Behavior:**
- Read-only. No in-game effects from browsing.
- Unwritten entries are not shown (or shown as "???" with no detail).
- Completed entries show a checkmark and the reward received.

#### 1.15 Settings Panel

**Trigger:** Pressing "Settings" on Main Menu or from the pause/menu overlay.

**Elements:**
- **Audio Sliders:** BGM volume, SFX volume.
- **Keybindings:** Rebindable input map. Lists all actions (move, confirm, cancel, inventory, etc.).
- **Accessibility:** Text size slider (if applicable), colorblind mode toggle, screen shake toggle.
- **Close Button:** Returns to previous screen.

#### 1.16 Pause / Menu Overlay

**Trigger:** Pressing the hamburger/menu button in the HUD during exploration or combat.

**Elements:**
- "Resume" button.
- "Survivor Notes" button.
- "Settings" button.
- "Return to Main Menu" button (with confirmation dialog).
- Game paused behind the overlay.

**Behavior:**
- Modal: game is fully paused.
- Combat: pause only available between turns or during player turn (not during enemy turn animations).

### 2. HUD Specification

#### 2.1 Stamina Bar

- **Position:** Top-left corner of the game view.
- **Visual:** Horizontal bar. Filled portion represents current stamina. Empty portion is dark/empty.
- **Text:** "current / max" (e.g., "8 / 12") displayed below or overlaid on the bar.
- **Color coding:**
  - Green (>50%): Normal.
  - Yellow (20–50%): Warning state.
  - Red (<20%): Critical state.
- **Updates:** Real-time as stamina changes.

#### 2.2 Gold Display

- **Position:** Top-left, adjacent to stamina bar or in a top-right corner HUD cluster.
- **Visual:** Coin icon + number.
- **Updates:** Immediately on gold gain or spend.

#### 2.3 Chapter Indicator

- **Position:** Top-center or top-right.
- **Visual:** "Chapter N" text, or a roman numeral badge.
- **Updates:** On chapter transition.

#### 2.4 Inventory Quick-Toggle

- **Position:** Bottom-right or top-right.
- **Visual:** Backpack icon button.
- **Behavior:** Opens the Backpack Screen overlay.

#### 2.5 Menu Button

- **Position:** Top-right corner (opposite to gold/stamina cluster).
- **Visual:** Hamburger icon (three horizontal lines).
- **Behavior:** Opens the Pause/Menu Overlay.

#### 2.6 Active Debuff Icons (Combat)

- **Position:** Below the stamina bar (exploration) or below enemy HP bar (combat).
- **Visual:** Small icons with tooltips showing debuff name and effect.
- **Updates:** Applied at combat start; removed when debuff expires or combat ends.

#### 2.7 Combat Intent Indicator

- **Position:** Above the enemy sprite.
- **Visual:** Icon showing the enemy's next action (sword = attack, shield = defend, etc.) with damage number.
- **Updates:** At the start of each enemy turn (or when enemy intent changes).

### 3. Navigation and Input

#### 3.1 Screen-to-Screen Navigation

```
Main Menu
    ├─► New Adventure → Difficulty Selection → Optional Carry → Game Scene
    ├─► Continue → Game Scene (loaded from save)
    ├─► Survivor Notes → Survivor Notes Screen
    └─► Settings → Settings Panel

Game Scene (Exploration)
    ├─► Node Interaction → Combat / Shop / Safe House / Event / Loot overlays
    ├─► HUD Menu Button → Pause/Menu Overlay
    │       ├─► Resume
    │       ├─► Survivor Notes
    │       ├─► Settings
    │       └─► Return to Main Menu (confirmation)
    └─► Inventory Toggle → Backpack Screen

Game Scene (Combat)
    ├─► Backpack (via "翻找背包" card) → Backpack Screen (limited)
    ├─► Loot Overlay → Take/Abandon Flow
    └─► Combat End → Loot → Exploration or Chapter Transition or Ending

Chapter Transition
    └─► Game Scene (Exploration) with new chapter map

Ending
    └─► Main Menu
```

#### 3.2 Modal / Non-Modal Rules

| Overlay | Modal? | Game Paused? | Notes |
| :--- | :---: | :---: | :--- |
| Pause/Menu | Yes | Yes | Full pause. |
| Random Event | Yes | Yes | Must resolve event before returning to map. |
| Shop | Yes | Yes | Cannot move while shop is open. |
| Safe House | Yes | Yes | Cannot move while safe house is open. |
| Backpack (exploration) | Yes | Yes | Cannot move while backpack is open. |
| Backpack (combat, via "翻找背包") | Yes | Yes | Combat frozen while in backpack. |
| Card Detail | No | No | Non-modal; can click cards while open. |
| Item Detail | No | No | Non-modal. |
| Loot Take/Abandon | Yes | Yes | Must resolve loot before resuming. |
| Ending Screen | Yes | Yes | Adventure ends behind this screen. |
| Survivor Notes (from pause) | Yes | Yes | |
| Settings (from pause) | Yes | Yes | |
| Difficulty Selection | Yes | N/A | Pre-game flow. |
| Optional Carry | Yes | N/A | Pre-game flow. |

#### 3.3 Input Routing

**Mouse/Keyboard (primary):**
- Left-click: Select / Confirm / Move to adjacent revealed node.
- Right-click: Cancel / Back. Also opens Card/Item Detail overlay on the targeted element.
- Hover (0.5s): Same as right-click for Card/Item Detail on hovered element.
- Drag: Drag cards to active slots; drag items within backpack grid.
- Drop: Confirm card placement or item placement.

**Gamepad (secondary):**
- D-pad: Navigate between nodes (exploration) or cards (combat).
- A button: Confirm / Interact.
- B button: Cancel / Back.
- Start: Open pause menu.
- LB/RB or shoulder buttons: Cycle through tabs in Backpack or Survivor Notes.
- Guide button: Open settings.

**Touch (future consideration):**
- Tap: Select / Confirm.
- Long-press (0.5s): Open detail overlay.
- Drag-and-drop: Same as mouse.

### 4. Visual Layout Patterns

#### 4.1 Card Display in Combat

- Cards in hand are displayed in a curved fan or horizontal row at the bottom of the screen.
- Each card shows: card name, stamina cost (top-left corner), card illustration (center), effect text (bottom).
- Active slots are visually distinct (glowing border, highlighted background).
- Empty active slot shows a dashed outline.
- A card being dragged shows a semi-transparent ghost at its original position and a solid copy following the cursor.

#### 4.2 Item Icons in Grids

- All items (consumables, relics, weapons) are represented by icons on the backpack grid.
- Each cell shows the item icon. Multi-cell items span their required cells.
- Color tint indicates item type: consumable (blue-ish), relic (purple), weapon (orange).
- Equipped items have a small equipped-badge or golden border.

#### 4.3 Node Icons on Map

- Each node type has a distinct icon:
  - START: Flag
  - Road: Dashed line / path icon
  - Normal Combat: Skull with one bone
  - Hard Combat: Skull with two bones
  - Random Event: Question mark
  - Ruins: Rubble / broken pillar
  - Black Market: Coin stack
  - Safe House: House / tent
  - Quest: Scroll / quest marker
  - Boss (Regional Pollution Source): Large skull / cloud

- Fog of war state affects visibility:
  - Unexplored: Fully hidden (no icon).
  - Revealed: Semi-transparent icon with no type label.
  - Visited: Full opacity icon with label.
  - Cleared: Full opacity icon with checkmark overlay.

#### 4.4 Enemy Display in Combat

- Enemy is displayed as a large sprite or stylized portrait on the right side of the combat view.
- HP bar is below the enemy portrait.
- Debuff icons are displayed below the HP bar.
- Intent indicator floats above the enemy.

#### 4.5 Loot Item Presentation

- Loot items are shown one at a time, centered on screen at large scale.
- The item's full illustration and all details are visible.
- Take and Abandon buttons are large and clearly labeled.
- A small progress indicator ("3 / 7") shows position in the loot sequence.

### 5. Animation and Transitions

#### 5.1 Screen Transitions

- **Main Menu → Game Scene:** Fade to black (0.5s), load scene, fade in (0.5s).
- **Game Scene exploration ↔ combat:** No full-screen transition. Combat UI elements slide in from edges (0.3s). Exploration UI elements slide out.
- **Any Overlay Open/Close:** Fade in overlay (0.2s), content scales from 95% to 100% with ease-out.

#### 5.2 Combat Animations

- **Card Play:** Card flies from its slot to the active slot or toward the enemy. Duration: 0.2s.
- **Damage Dealt:** Enemy flashes red, HP bar depletes with tween. Screen shake (optional, configurable).
- **Player Takes Damage:** Stamina bar flashes red, screen edge vignette pulses.
- **Enemy Turn Start:** Brief pause (0.3s) before enemy acts.
- **Victory:** Enemy fades out, a brief "VICTORY" text appears, loot overlay slides in.

#### 5.3 Node Reveal Animation

- When a new node is revealed, it fades in from 0 to full opacity over 0.3s.
- Connection lines draw from the visited node to the new node (optional, animated dashes).

#### 5.4 Loot Take/Abandon

- Items slide in from the bottom of the screen.
- On "Take": item icon flies into the inventory area, a "+1" pop-up appears.
- On "Abandon": item fades and falls off screen.

### 6. Responsive Layout

- **Minimum Resolution:** 1280×720 (16:9).
- **Preferred Resolution:** 1920×1080.
- **UI elements use anchors and margins, not fixed pixel positions.**
- The backpack grid, combat card hand, and map view all scale proportionally with viewport size.
- Aspect ratio lock: 16:9 preferred. Wider or narrower ratios crop top/bottom or add side bars with a neutral background color.

### 7. Accessibility

- **Text Size:** Configurable via Settings (3 levels: Small, Normal, Large).
- **Colorblind Modes:** Deuteranopia (red-green), Protanopia, Tritanopia. Applies color-shift filters to enemy intent colors and damage numbers.
- **Screen Shake:** Toggleable (default ON). Disabling removes all camera shake on damage.
- **High Contrast Mode:** Increases border widths and contrast ratios for all UI elements.
- **Audio Cues:** Distinct sound effects for: card play, damage dealt, damage received, loot drop, loot take, enemy turn start, boss emergency heal, victory, defeat.

## Edge Cases

### E1. Combat Started with Backpack Open

If the player has the backpack open and a combat is triggered (enemy ambush, or walking into a combat node):
1. The backpack is forcibly closed immediately.
2. Combat UI animates in from edges.
3. Combat begins. The player cannot reopen the backpack except via the "翻找背包" action card.

### E2. Loot With Full Inventory

When the loot Take/Abandon flow presents an item and the player's inventory cannot fit it:
1. The "Take" button is disabled (grayed out) until space is made.
2. The player is forced to either: (a) rearrange existing items to make space, or (b) abandon the new item.
3. The player cannot close the loot overlay or proceed until this item is resolved.
4. If the player abandons the item, the loot overlay shows the next item.

### E3. Multiple Overlays Attempted Simultaneously

If two overlays are triggered at the same moment (e.g., reaching a shop node while holding an item that causes a "steal" event):
1. Overlays are stacked in priority order: Ending > Loot > Shop/Safe House/Backpack > Card Detail / Item Detail.
2. Only the highest-priority overlay is shown. Lower-priority overlays queue and open after the higher-priority one is dismissed.

### E4. Card Drag Cancelled

If the player starts dragging a card but releases it outside a valid drop zone:
1. The card animates back to its original position.
2. No stamina is consumed.
3. The active slot (if any) that was being targeted is unchanged.

### E5. Rapid Clicking During Animation

During any animated transition (card play, screen transition, loot item fly-in), input is temporarily blocked:
- Blocking duration is the animation duration + 0.1s buffer.
- Clicking during this period is queued and processed after the block lifts, but only for critical actions (confirm/attack). Non-critical clicks (hover, browse) are discarded.

### E6. Backpack Opened from Pause Menu in Combat

If the player pauses during combat and opens the backpack:
- The backpack shows the full inventory (not the limited "翻找背包" view).
- All item rearrangement is available.
- Resuming from the pause menu closes the backpack and resumes combat in the same state.

### E7. Item Detail While Loot Overlay is Open

If the player right-clicks an item while the loot overlay is showing that same item:
1. The Item Detail overlay appears above the loot overlay.
2. Both overlays remain visible.
3. Closing the Item Detail overlay returns focus to the loot overlay.
4. The player cannot click a different item for detail while loot is unresolved.

### E8. Shop Opened with 0 Gold

If the player enters a Black Market with 0 gold:
1. The shop opens normally. All items show their prices.
2. The buy buttons are disabled for items exceeding the player's gold.
3. The sell panel is fully functional.
4. The player can sell items to accumulate gold and then buy.

### E9. Map Node Clicked During Combat

During combat, clicking nodes on the (hidden) map view is not possible because the map is replaced by the combat view. However, if the player uses a gamepad and somehow navigates to a "return to map" button that shouldn't exist:
1. The button has no function during combat.
2. No error is raised; the input is silently ignored.

### E10. Screen Resolution Changed During Game

If the player changes the screen resolution from the Settings panel mid-game:
1. The UI immediately re-anchors to the new viewport dimensions.
2. No game state is lost.
3. If the new resolution is below minimum (1280×720), a warning is shown and the change is reverted.

### E11. Random Event — Locked Box Code Exhaustion

If the player attempts the Locked Box code multiple times and runs out of stamina mid-attempt:
1. The stamina cost is deducted on each guess.
2. If stamina drops to 0 and Adrenaline Needle is available, it triggers and the player survives.
3. If no Adrenaline Needle and stamina ≤ 0, permadeath triggers immediately.
4. The code attempt is abandoned; no reward is granted.

### E12. Random Event — Robbery "Fight" Choice

If the player chooses "Fight" at a Robbery event:
1. The event overlay closes.
2. Combat UI animates in — the enemy is a special robber enemy.
3. If the player wins: no additional reward (the "payment avoided" is the reward).
4. If the player flees: returns to nearest Safe House. The robbery event is still resolved (node becomes "普通道路").

### E13. Random Event — Gambler and 0 Gold

If the player enters a Gambler event with 0 gold:
1. The "Bet" button is disabled because the player cannot bet any gold.
2. Only "Do Nothing" is available.
3. The event resolves without change.

### E14. Random Event — Hitchhike Teleport Destination

When the player chooses Hitchhike and must select a destination:
1. A map overlay shows all non-Boss nodes highlighted.
2. Clicking a node teleports the player there immediately.
3. The destination node's state does not change (if unexplored/revealed, it stays that way).
4. The stamina cost (2 gold) is deducted before teleportation.

### E15. Random Event — Rogue Market With Full Inventory

If the player enters a Rogue Market with full inventory:
1. The shop overlay opens normally.
2. The player can sell items but cannot buy anything.
3. After leaving, the node becomes "普通道路" and the shop is gone.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Reads combat state to render combat UI; writes card plays, turn progression triggers |
| **Node Interaction System** | Reads node type to display correct icon and interaction prompt; writes node visit/clear state |
| **Map Generation System** | Reads map structure and node positions to render the map view |
| **Random Event System** | Reads event type to display correct event overlay; writes event resolution outcome (loot, combat, stamina change, gold change, teleport) |
| **Backpack & Inventory System** | Reads inventory contents to render grid; writes item rearrangement and equip changes |
| **Shop System** | Reads shop stock to render buy/sell UI; writes buy/sell transactions |
| **Resource System** | Reads stamina, gold, max stamina to update HUD |
| **Boss and Chapter Transition System** | Reads chapter/boss state to render chapter indicator, boss HP bars |
| **Survivor Notes System** | Reads bonus values for Optional Carry display; reads entry progress for Survivor Notes screen |
| **Ending System** | Reads ending type to render appropriate ending screen; reads Survivor Letter count for ending choice dialog |
| **Difficulty System** | Reads difficulty level for difficulty selection UI |
| **Save/Load System** | Reads save data to enable "Continue" button and restore UI state; writes current game state on pause |

### Systems That Depend On This

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Receives card play input from Combat UI; receives turn-end signal from End Turn button |
| **Node Interaction System** | Receives node click coordinates from Map UI; sends reveal/visit state changes for re-rendering |
| **Random Event System** | Receives event choice input from Event UI; sends loot/combat/teleport/stamina change results for display |
| **Backpack & Inventory System** | Receives item rearrangement drag-drop events from Backpack UI; sends item fit-check results |
| **Shop System** | Receives buy/sell click events; sends stock depletion updates for re-rendering |
| **Resource System** | Receives gold/stamina change requests from UI; sends current values for HUD update |
| **Boss and Chapter Transition System** | Receives loot Take/Abandon decisions; receives ending choice dialog decisions |
| **Ending System** | Receives ending screen dismissal; triggers Survivor Notes write |
| **Save/Load System** | Receives save/load trigger from pause menu; sends current game state for serialization |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `CARD_PREVIEW_HOLD_TIME` | 0.5s | 0.3–1.0s | How long to hold a card before detail overlay appears |
| `OVERLAY_FADE_DURATION` | 0.2s | 0.1–0.5s | Duration of overlay fade-in animation |
| `SCREEN_TRANSITION_FADE` | 0.5s | 0.3–1.0s | Duration of full-screen transition fade |
| `CARD_DRAG_BLOCK_DURATION` | 0.3s | 0.2–0.5s | How long input is blocked during card play animation |
| `MIN_RESOLUTION_WIDTH` | 1280 | 1280 | Minimum supported screen width |
| `MIN_RESOLUTION_HEIGHT` | 720 | 720 | Minimum supported screen height |
| `HUD_STAMINA_WARNING_THRESHOLD` | 50% | 30–60% | Stamina % below which bar turns yellow |
| `HUD_STAMINA_CRITICAL_THRESHOLD` | 20% | 10–30% | Stamina % below which bar turns red |
| `ACTIVE_CARD_SLOTS` | 3 | 3–5 | Number of active slots shown in combat UI |
| `CARD_HAND_VISIBLE_COUNT` | — | 5–10 | How many cards visible in hand at once (scroll if more) |

## Acceptance Criteria

### AC1. Main Menu Navigation
- [ ] Launch the game. Verify Main Menu is displayed with all 4 buttons.
- [ ] Press "New Adventure." Verify Difficulty Selection appears.
- [ ] Select a difficulty and confirm. Verify Optional Carry screen appears.
- [ ] Choose "Carry Buffs." Verify Game Scene loads at Chapter 1.

### AC2. Map View — Node Visibility
- [ ] Start a new adventure. Verify the START node is visible and all adjacent nodes are revealed (fog of war).
- [ ] Move to a new node. Verify old connections remain visible and new adjacent nodes become revealed.
- [ ] Verify visited nodes show their correct type icon; revealed nodes show silhouettes only.

### AC3. Map View — Node Icons
- [ ] Verify each node type has a distinct, clearly recognizable icon.
- [ ] Verify cleared nodes show a checkmark or visual distinction from visited-but-uncleared nodes.
- [ ] Verify Boss node (区域污染源) is always fully visible even before adjacent nodes are explored.

### AC4. Combat UI — Card Slots
- [ ] Enter combat. Verify 3 active slots are displayed with dashed outlines.
- [ ] Drag a card from hand to an active slot. Verify the slot fills and the card stays in place.
- [ ] End turn. Verify cards in active slots are consumed and new cards populate the slots.
- [ ] Verify the End Turn button is disabled until at least one action is taken.

### AC5. Combat UI — Card Drag and Drop
- [ ] Drag a card over a valid active slot. Verify slot highlights as a valid drop target.
- [ ] Drag a card over an invalid area and release. Verify the card animates back to hand.
- [ ] Right-click a card. Verify the Card Detail overlay appears with full card information.

### AC6. HUD — Stamina Bar
- [ ] Verify stamina bar shows current and max stamina with correct fill level.
- [ ] Verify bar turns yellow below 50% and red below 20%.
- [ ] Verify stamina changes (gain/loss) animate smoothly on the bar.

### AC7. HUD — Gold and Chapter
- [ ] Verify gold count is visible and updates immediately on gain/spend.
- [ ] Verify chapter indicator shows the current chapter number.
- [ ] After chapter transition, verify chapter indicator updates.

### AC8. Backpack — Grid Display
- [ ] Open the backpack. Verify the correct grid shape for the current backpack type (Satchel starts as 3×4+1×2).
- [ ] Verify items occupy the correct number of cells.
- [ ] Drag an item to a new empty cell. Verify it moves there.
- [ ] Drag an item onto an incompatible cell (too small). Verify it snaps back to original position.

### AC9. Backpack — Pocket Quick-Access
- [ ] In exploration, open the backpack. Verify both pocket grids are shown.
- [ ] Move an item from backpack to a pocket. Verify it appears in the pocket grid.
- [ ] Verify items in the pocket are usable during combat without opening the full backpack.

### AC10. Shop — Buy and Sell
- [ ] Enter a Black Market. Verify 5 stock slots are displayed with items and prices.
- [ ] Buy an item with sufficient gold and inventory space. Verify gold decreases and item enters inventory.
- [ ] Attempt to buy with insufficient gold. Verify the buy button is disabled.
- [ ] Sell an item from the sell panel. Verify gold increases and item leaves inventory.

### AC11. Safe House — All Panels
- [ ] Enter a Safe House. Verify Fridge, Piggy Bank, and Anvil panels are all visible.
- [ ] Use a fridge Energy Drink. Verify it is consumed and stamina increases.
- [ ] Deposit gold into the piggy bank. Verify it is stored.
- [ ] Repair a weapon at the anvil. Verify durability increases.
- [ ] Exit and re-enter the same Safe House (same chapter visit). Verify resources are unchanged (per-visit limits apply).

### AC12. Loot — Take/Abandon Flow
- [ ] Win a combat that yields 4 items. Verify each item is shown one at a time.
- [ ] Click "Take" on each. Verify items are added to inventory.
- [ ] When inventory is full and "Take" is pressed, verify the player is forced to rearrange or abandon.
- [ ] Verify "Abandon" skips the item with no penalty.

### AC13. Ending Screens
- [ ] Trigger a False Ending. Verify the False Ending screen appears with title, narrative, and statistics.
- [ ] Return to main menu. Start a new adventure with 4 Survivor's Letters. Complete the true ending path.
- [ ] Verify the True Ending screen appears with title, narrative, and complete statistics.

### AC14. Card Detail and Item Detail — Non-Modal
- [ ] During combat, right-click a card. Verify Card Detail overlay appears.
- [ ] While Card Detail is open, verify the player can still interact with the game (click other cards, etc.).
- [ ] Close the Card Detail overlay by clicking the close button or clicking outside.
- [ ] In inventory, right-click an item. Verify Item Detail overlay appears with full information.
- [ ] Verify the same Item Detail overlay appears in the shop when hovering over a stock item.

### AC15. Pause Menu
- [ ] Press the menu button. Verify the Pause/Menu overlay appears and game is paused.
- [ ] Verify all 4 options are present: Resume, Survivor Notes, Settings, Return to Main Menu.
- [ ] Click "Return to Main Menu." Verify a confirmation dialog appears.
- [ ] Cancel the confirmation. Verify the game remains paused.

### AC16. Survivor Notes Screen
- [ ] From Main Menu, press "Survivor Notes." Verify the Survivor Notes screen appears.
- [ ] Verify entries are grouped by category and show progress toward the next stage.
- [ ] Select a completed entry. Verify it shows name, description, and reward.
- [ ] Verify unwritten entries are not shown (or shown as "???").

### AC17. Settings — Audio and Keybindings
- [ ] Open Settings. Verify BGM and SFX volume sliders.
- [ ] Adjust sliders. Verify audio changes in real-time.
- [ ] Verify keybindings list shows all rebindable actions.
- [ ] Rebind a key. Verify the new binding is saved and functional.

### AC18. Optional Carry — Disable Buffs
- [ ] Complete an adventure with significant Survivor Note progress (e.g., Wayfarer +2).
- [ ] Return to main menu. Start a new adventure.
- [ ] At Optional Carry screen, choose "Disable Buffs."
- [ ] Verify starting max stamina is base 12 (not increased by Wayfarer).
- [ ] Verify starting gold is base 8 (not increased by Hoarder).
- [ ] Verify relics remain available in loot and shop.

### AC19. Random Event — Basic Event Flow
- [ ] Enter a Random Event node. Verify the event overlay appears with title, illustration, and description.
- [ ] Verify the correct choices are presented for the event type.
- [ ] Choose "Do Nothing" (if available). Verify the event resolves and node becomes "普通道路".
- [ ] Verify the overlay closes and the player returns to the map.

### AC20. Random Event — Theft with Badge
- [ ] Equip the Badge (警徽) relic.
- [ ] Enter a Theft event. Verify the description states no items are stolen.
- [ ] Verify only "Continue" button is present.
- [ ] Verify the player's inventory is unchanged.

### AC21. Random Event — Robbery Fight
- [ ] Enter a Robbery event. Choose "Fight."
- [ ] Verify the event overlay closes and combat UI appears.
- [ ] Win the combat. Verify the node becomes "普通道路" with no additional reward.

### AC22. Random Event — Hitchhike Teleport
- [ ] Enter a Hitchhike event with ≥2 gold.
- [ ] Pay 2 gold. Verify a node selection overlay appears.
- [ ] Click a non-Boss node on the map. Verify the player teleports to that node.
- [ ] Verify the original event node becomes "普通道路".

### AC23. Random Event — Locked Box
- [ ] Enter a Locked Box event. Choose to attempt the code.
- [ ] Verify the 2-digit code input UI appears.
- [ ] Make a guess. Verify feedback ("Higher" / "Lower") is shown per digit.
- [ ] Verify each guess costs 1 stamina.
- [ ] Guess correctly. Verify a reward is granted.
- [ ] Run out of stamina mid-attempt. Verify Adrenaline Needle triggers if available.

### AC24. Random Event — Gambler (Blackjack)
- [ ] Enter a Gambler event. Set a bet of 5 gold. Click "Play."
- [ ] Verify simplified Blackjack UI appears with player and dealer hands.
- [ ] Click "Hit" until satisfied or busted. Click "Stand."
- [ ] Verify the result: Win (bet doubled), Lose (bet lost), or Push (bet returned).
- [ ] Verify gold is updated accordingly.

### AC25. Random Event — Rogue Market
- [ ] Enter a Rogue Market event. Verify the shop overlay appears immediately.
- [ ] Verify it behaves like a standard Black Market.
- [ ] Close the shop. Verify the node becomes "普通道路".

### AC26. Random Event — Dying Embers
- [ ] Enter a Dying Embers event. Verify stamina is restored by +8.
- [ ] Verify the warm glow animation plays on the stamina bar.
- [ ] Verify only "Continue" button is present.
- [ ] If already at max stamina, verify the +8 is still shown but has no practical effect.