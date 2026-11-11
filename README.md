# game-godot-dandy

**Soria's Expeditions** - co-op elevator/floor survival game in Godot 4.7 (GDScript). Design source: Daniel Prikhodko's deck, summarised in `.claude/requirements.md`.

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
