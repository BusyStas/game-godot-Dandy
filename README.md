# game-godot-dandy

**Sonia's Expeditions** - co-op elevator/floor survival game in Godot 4.7 (GDScript). Design source: Daniel Prikhodko's deck, summarised in `.claude/requirements.md`.

## Run
Open `project.godot` in Godot 4.7 and press F5, or `godot --path .`. It starts on the title screen.

## Controls
| Key | Action |
|---|---|
| WASD / mouse | Move / look |
| Shift | Sprint (louder - Serrani hears it) |
| E | Fix machines, open containers (hold; tap for clicker machines) |
| F | Open a shop when standing near its counter |
| Enter | Confirm the selection screen |
| Tab | Free / capture the mouse |
| T | Debug: complete a task |
| Backspace | Abort the run, back to the lobby |
| X or Ctrl+C | Quit the game (works on every screen, like DOS) |

## Layout
- `scenes/` - `title.tscn` (main scene), `lobby.tscn`
- `scripts/round_manager.gd` - autoload: round loop, Sonium, ownership, saving (`user://save.cfg`)
- `scripts/game_data.gd` - characters, skins, decorations, utilities, 24 map themes
- `scripts/map_picker.gd` - weighted map odds from the deck
- `scripts/floor_builder.gd` - procedural floors, elevator doors (steel panels, indicator, call button) and the elevator cabin interior (carpet, wood panels, handrails, lamp, control panel)
- `scripts/mirror.gd` - real mirror in the cabin: a hidden camera at the reflected viewer position, shown flipped on the mirror quad, plus a reflection figure in your skin colour. Only active while you are inside the cabin.
- `scripts/corruption.gd`, `machine.gd`, `container.gd`, `player.gd` - gameplay
- `scripts/lobby.gd`, `selection_screen.gd`, `shop_ui.gd`, `title_screen.gd` - presentation/UI
- `.claude/requirements.md` - requirements, decisions and open questions

Keep the `*.gd.uid` files committed next to their scripts.

## Display, minimap and warnings
- The game starts fullscreen (borderless); **F11** toggles windowed/fullscreen. The UI scales with the window.
- **Minimap** (top-right): a top-down camera over the real level, north up. White disc with a yellow nose = you, red = monsters (hidden Surrena only once it bursts out), yellow squares = machines, blue squares = containers, green square = the elevator. Hidden inside the cabin.
- **Monster warning**: a flashing red screen glow, "!! WARNING !!" banner and a siren beep when a monster comes into view (re-armed after 15 s out of sight) or when Surrena bursts from a wall.

## Corruptions, health and research (deck update 2026-11-15)
- Game name is **Sonia's Expeditions** now. Eight Corruptions (Sonia, Serrani, Surrena, Rencha, Cybot 1.2.7, Ivina, Bolten, Dreina), each with its own behaviour; see `.claude/requirements.md` section 13.
- **Health**: 6 HP (bottom-left). Fatals kill instantly, Stalks deal 2, Dreina 1. **E** next to a medkit heals 2 (Sonia may poison them).
- **Minigames**: Surrena's grab (mash **A/D**), Ivina's thorns (click the red points).
- **Research**: press **R** in the lobby; claim rewards after four tasks per Corruption.
- By the deck's spawn table only Dreina appears before floor 10. To meet the others, press **PageUp** in the lobby to start deeper (floor 11 = Stalks, floor 21 = Fatals).
- New scripts: `hazard.gd` (puddles, plants), `medkit.gd`, `minigame.gd`, `research_ui.gd`, `status_hud.gd`.
