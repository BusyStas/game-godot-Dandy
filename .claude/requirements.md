
# get latest here: https://docs.google.com/presentation/d/1SN0quesu7F6EFkFNrn4G97AoUU_rhAo0Q65-qJgfKSs/edit?slide=id.h6abf26ebc7158a13_1_79#slide=id.h6abf26ebc7158a13_1_79
# when he changes this presentation - update this file. 


# Requirements — Soria's Expeditions

Source: Google Slides "Soria's Expedition - Game Design: Whole Guide" (owner: Daniel Prikhodko; read 2026-11-11), which supersedes `Game Design - The Whole Guide.pdf` in this folder. The PDF is an older snapshot without the Game Basics, Characters or Corruptions sections.

Conventions: **MUST** = stated in the design. **TBD** = the design explicitly defers it ("later"). **ASSUMPTION** = not in the design; a placeholder chosen so work can proceed. IDs are stable so code and issues can reference them.

Target: Godot 4.x, GDScript, multiplayer (see `scripts/round_manager.gd`, `scripts/map_picker.gd`).

---

## 1. Overview

- **R-1.1** The game is called **Soria's Expeditions** (the repo name `game-godot-dandy` is not the game title).
- **R-1.2** Multiplayer co-op survival game: players ride an elevator to a themed floor, complete tasks, then must return to the elevator before time runs out or die.
- **R-1.3** The loading screen shows the logo with the "i" in "Soria" drawn as Soria's head, sideways.
- **R-1.4** Currency is **Sonium**, earned in runs and spent in lobby shops.

## 2. Lobby

- **R-2.1** On first launch the player sees a screen offering **two starting characters** (designs TBD).
- **R-2.2** The lobby contains: a spawn/starting area, a hallway with **four elevators** and two doors, and three shops:
  - **Shop 1** — character shop (shopkeeper: Soria)
  - **Shop 2** — character skin shop (shopkeeper: Serrani)
  - **Shop 3** — player card shop
- **R-2.3** Entering an elevator starts a short countdown (duration TBD, ASSUMPTION 5 s).
- **R-2.4** Each elevator is a separate group/match; players inside the same elevator play the same run together.

## 3. Run flow (round loop)

States, in order:

1. **R-3.1 Countdown** — after entering the elevator (R-2.3).
2. **R-3.2 Selection** — UI to pick **character, skin, and utilities**. Ends when all players are ready **or** a timer expires (duration TBD, ASSUMPTION 30 s).
3. **R-3.3 Pre-floor elevator** — all players are placed in one elevator for about **15 seconds**.
4. **R-3.4 Floor** — doors open onto a **random map chosen by RNG** (section 4). Players complete the floor's tasks (section 5).
5. **R-3.5 Panic mode** — starts as soon as the floor's tasks are complete.
6. **R-3.6 Return** — everyone has **90 seconds** to run back to the elevator they originally came from. **Anyone not in the elevator when time ends dies.**
7. **R-3.7 Repeat** — the loop repeats after everyone is in the elevator; floor number increases each time.

- **R-3.8** Floor number drives map eligibility (R-4.2) and Corruption spawns (R-6.3).
- **R-3.9** Open: what happens when all players die, when a run ends, and what the results screen shows are not specified.

## 4. Maps (floors)

- **R-4.1** About **24 floors**. Categories:
  - 15 regular floors (themed rooms)
  - **4 character floors** (CH1–CH4) — "the most important to the game"
  - **3 shop-character challenge floors** (CL1–CL3) — challenges with a reward for beating them (reward TBD)
  - **2 lore floors** (LR1–LR2) — explain what happened in this place
- **R-4.2** Each map has a **minimum floor** at which it can appear and a **rarity** (percentage odds).
- **R-4.3** Rarity values are the odds **at or after floor 30**. Before floor 30 the odds are "higher for certain maps" (exact pre-30 odds TBD; the current code uses the floor-30 odds at every floor).
- **R-4.4** Map table (order follows the design). The code in `scripts/map_picker.gd` implements this table.

| Map | Min floor | Rarity |
|---|---|---|
| Library | 0 | 8% |
| Laboratory | 0 | 4% |
| Train Station | 0 | 6% |
| Kitchen | 0 | 10% |
| Warehouse | 5 | 5% |
| Aquarium | 0 | 2% |
| Diner | 0 | 5% |
| Museum | 0 | 3% |
| Art Gallery | 0 | 5% |
| Rainbow Room | 5 | 10% |
| School | 0 | 7% |
| Factory | 10 | 4% |
| Gardens | 5 | 5% |
| Playhouse | 0 | 4% |
| Gift Shop | 0 | 2% |
| CH1 Floor | 15 | 3% |
| CH2 Floor | 15 | 4% |
| CH3 Floor | 15 | 4% |
| CH4 Floor | 15 | 6% |
| CL1 Floor | 20 | 0.5% |
| CL2 Floor | 20 | 0.75% |
| CL3 Floor | 20 | 0.75% |
| LR1 Floor | 25 | 0.5% |
| LR2 Floor | 30 | 0.5% |

- **R-4.5** The rarities sum to 100%. When some maps are ineligible (below their min floor), selection must renormalize over the eligible maps.
- **R-4.6** The deck does not say which map is which category beyond the CH/CL/LR prefixes, nor whether a map can repeat on consecutive floors. TBD.

## 5. Tasks and completion

- **R-5.1** A floor is completed by finishing its task(s). **Most floors have one task: fix the machines** on the floor.
- **R-5.2** Other floors have other tasks, for example **open every storage container**, or **everyone is spotted by all the Corruptions**.
- **R-5.3** Machine types: **regular, hard, treadmill, clicker, search** (the deck says "they are sorted"; meaning unclear, TBD).
- **R-5.4** Machines, Corruptions and storage containers **spawn on every floor even when they are not the required task**.
- **R-5.5** Storage containers are **hidden** around the map.
- **R-5.6** A progress **bar at the top of the screen** fills slightly each time a task is completed, and is **shared by every player in the run**.
- **R-5.7** When the tasks are complete, panic mode starts (R-3.5) and the 90-second return begins (R-3.6).
- **R-5.8** Number of machines/containers per floor and how many complete a task: TBD (the code uses a placeholder of 3 tasks).

## 6. Characters and Corruptions

Three antagonists, all labeled "Fatal", appear in the design. All can **kill a character instantly**.

- **R-6.1 Soria** — shopkeeper of the character shop and the most important character.
  - Appearance: syringe head, human body, a suit with blue/green gradient stripes, blue/green gradient gloves.
  - Story: the **Incident** is all her fault. Overwhelmed by insanity, she haunts the floors and tries to catch the others. In the shop she pretends to be nice, then turns insane.
  - Behavior: **targets the healthiest player** in the run.
- **R-6.2 Serrani** — shopkeeper of the character skin shop.
  - Story: worked with Soria during the Incident; when Soria went insane he ran and never turned back, and is overwhelmed by guilt.
  - Behavior: hunts the others and **runs toward any noise he hears**.
- **R-6.3 Surrena** — side/main character.
  - Story: worked with Serrani and Soria; searched for Serrani and was caught by Soria.
  - Behavior: **hides inside the walls** and jumps out to kill players who are **alone** and off guard.
- **R-6.4** Corruptions spawn on the map **depending on the floor and the number of players** in the run (formula TBD).
- **R-6.5** "Spotted by a Corruption" is a tracked event (gives Sonium, R-7.2, and can be a task, R-5.2). The detection rule (line of sight, range) is TBD.
- **R-6.6** The deck's "Corruptions" section is **empty** ("a guide on the corruptions, after characters are shown"). Specific Corruption types are TBD.
- **R-6.7** The two starting characters, character designs, and which characters the shop sells are TBD. Note that Soria's shop sells characters, but the deck doesn't say whether Soria/Serrani/Surrena are themselves playable (they are described as enemies).

## 7. Economy (Sonium)

- **R-7.1** Sonium is the game's currency.
- **R-7.2** Earning:
  - Each **machine** gives about **10 Sonium**. The reward is **reduced if another player did part of the machine**.
  - Being **spotted by any Corruption** gives **1–2 Sonium**.
  - **Opening a storage container** gives about **5 Sonium** to the player who opened it.
- **R-7.3** Spending: **characters** (Shop 1), **skins** (Shop 2) and **player card decorations** (Shop 3).
- **R-7.4** Prices, split rules for shared machines, and whether Sonium is awarded on death are TBD.
- **R-7.5** Rewards must be granted by the server only, never by a client.

## 8. UI

- **R-8.1** Starting screen with two character choices (R-2.1).
- **R-8.2** Selection screens: **character**, **skin**, **utility** (utilities TBD).
- **R-8.3** In-run HUD: shared task progress bar at the top (R-5.6) and the return timer (R-3.6).
- **R-8.4** Loading screen with the logo (R-1.3).
- **R-8.5** Player cards exist (R-2.2) but what a card shows and where it is displayed are TBD.

## 9. Technical notes (from engineering, not the design deck)

- Server-authoritative: task progress, Sonium, deaths and map choice are decided on the server.
- Round loop is an autoload state machine (`scripts/round_manager.gd`); map selection is `scripts/map_picker.gd`.
- Persistence needed for Sonium balance, owned characters/skins/decorations and the selected loadout.

## 10. Open questions for the designer

1. Playable characters: what are the two starting characters, and what does Shop 1 sell?
2. What are "utilities", and how are they used or earned?
3. Corruptions section: which types exist, and how do they differ from the three Fatal characters?
4. Pre-floor-30 map odds: which maps are boosted, and by how much?
5. What do the shop-character challenge floors (CL1–CL3) reward?
6. What happens when all players die or the run ends? Is there a results screen?
7. How many players per elevator/run (min/max)?
8. What is the meaning of "machine types … are sorted"?
9. How many machines/containers per floor, and how are Corruption counts scaled by player count?
10. Does the Sonium reward for a shared machine split proportionally?

---

## 11. Implementation status and design decisions (single-player build)

Decisions made where the deck was silent. Change any of these by editing `scripts/game_data.gd` or `scripts/round_manager.gd`.

**Implemented and tested headless (Godot 4.7.2)**
- R-2: lobby with 4 elevators and 3 shops; title screen with the two-starter choice on first launch (R-2.1); the logo's "i" is a sideways head (R-1.3).
- R-3: full round loop (countdown, selection, 15 s elevator, floor, panic, 90 s return, death if not back, next floor).
- R-4: all 24 maps with min-floor gating and weighted odds; each has its own palette, prop layout and task type (procedural placeholder geometry).
- R-5: three task types, **machines**, **containers** (hidden, hold E) and **spotted** (be seen by every Corruption). All five machine kinds exist (regular, hard, treadmill, clicker, search). Machines and containers spawn on every floor and pay Sonium even when not the task.
- R-6: Soria, Serrani and Surrena behave as described; they kill instantly. Spotting = line of sight within 14 m.
- R-7: Sonium for machines (10), containers (5) and being spotted (1-2); shops spend it; ownership and loadout are saved.
- R-8: selection screen, shop windows, HUD, shared task progress readout.

**Placeholders chosen (not in the deck)**
- Starting characters: Recruit (balanced) and Scout (+15% speed). Shop also sells Engineer (100, fixes 30% faster) and Ghost (250, half the noise). The unchosen starter costs 60.
- Utilities (all free): Sprint Boots, Lantern, Earplugs. Skins and card decorations are cosmetic with invented prices.
- Timers: 5 s elevator countdown, 30 s selection, 5 s results.
- Task counts: machines 3 (+1 per 8 floors, max 6); containers 5; Corruptions 1 (+1 per 6 floors, max 4; spotted floors at least 2; challenge floors +1). Soria only appears from floor 8.
- Challenge floors (CL1-CL3) give +100 Sonium on completion. Lore floors (LR1-LR2) show a short invented note.
- Pre-floor-30 odds: the floor-30 table is used at every floor (deck says some maps are higher earlier; not specified which).
- Corruption AI is simple direct steering (no navmesh); props are kept sparse so they rarely get stuck.

**Not done**
- **Multiplayer.** Every system is server-authoritative in design but currently runs single-player. It needs decisions (host vs dedicated server, player count, lobby/elevator grouping) and is the largest remaining task. "Healthiest player" targeting for Soria, shared Sonium split on machines and the shared progress bar across players all depend on it.
- Real art, models, animation, sound and music; hand-built maps to replace the procedural ones.
- Per-map task mixes and Corruption rosters beyond the rules above (the deck's Corruptions section is empty).

---

## 12. Deck update: character art and the "Stalk" enemy class (2026-11-11)

The deck now includes drawings. The in-game models follow them (`scripts/character_model.gd`):
- **Common body (Fatal three):** black suit, two white chest stripes, white belt, grey legs, black arms with a white stripe and blue gradient-cuffed gloves.
- **Soria:** wide white head, syringe needle on one side, seven rainbow tabs on top, two big ringed eyes, small black mouth.
- **Serrani:** TV head with a black-to-white frame and blue rim, black screen, two antennas, wide smile.
- **Surrena:** spiky flame head (red at the top, yellow at the bottom), big eyes, wide black mouth.
- **Rencha:** wrench head (ring on one end, open jaw on the other), dark-grey torso, light-blue trousers, one arm raised.
- **Machines** are black cabinets with three lights on top (red broken, green fixed); **storage containers** are grey chests with a yellow lock ring. Faces are painted into textures at runtime, so no art files are needed; swap in real art later.

**New requirements from the updated deck**
- **R-6.8 Stalk class.** A second kind of Corruption that does *not* kill instantly:
  - **Rencha** (implemented): mutated from fear of failure; stalks the halls. Once it has seen you, you are slowed for the whole floor (placeholder: 0.8x speed). In-game it follows at about 5-7 m and never attacks. Appears from floor 4.
  - **Cybot 1.2.7** (not implemented, deck art is only a placeholder): a cyborg who was Rencha's friend and was forgotten. It can **break machines**, which spill their Sonium and make filling them harder.
- Surrena's text now says she "lies inside the walls" and jumps out on characters who are alone. This matches the existing implementation.
