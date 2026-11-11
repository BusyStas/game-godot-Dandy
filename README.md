# game-godot-dandy

Multiplayer co-op elevator/floor game built in Godot 4 (GDScript). Design source: `.claude/Game Design - The Whole Guide.pdf`.

## Layout
- `project.godot` - open this in Godot 4.3+
- `scenes/` - `.tscn` scenes (lobby, floors, player)
- `scripts/` - `.gd` code (`round_manager.gd` is an autoload; `map_picker.gd` holds the map odds table)
- `assets/` - models, sounds, images

## Run
Open the folder in Godot, or `godot --path .`
