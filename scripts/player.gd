extends CharacterBody3D
## First-person walker. WASD move, Shift sprint (louder), mouse look, Tab frees the mouse.
## Reads the equipped character/utility from RoundManager.loadout.

const BASE_SPEED := 6.0
const SPRINT_MULT := 1.5
const MOUSE_SENS := 0.0025
const GRAVITY := 20.0

var frozen := false          ## true while a UI screen is open
var fix_speed := 1.0         ## machine repair speed multiplier (character perk)

var _speed_mult := 1.0
var _quiet := 1.0
var _cam: Camera3D
var _lamp: OmniLight3D
var _pitch := 0.0
var _noise := 0.0
var _extra_noise := 0.0
var _extra_until_ms := 0


func _ready() -> void:
	add_to_group("player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	_cam = Camera3D.new()
	_cam.position.y = 1.6
	add_child(_cam)
	_cam.current = true

	_lamp = OmniLight3D.new()
	_lamp.omni_range = 14.0
	_lamp.light_energy = 1.6
	_lamp.visible = false
	_cam.add_child(_lamp)

	apply_loadout()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func apply_loadout() -> void:
	var ch: Dictionary = GameData.CHARACTERS.get(RoundManager.loadout["character"], GameData.CHARACTERS["recruit"])
	_speed_mult = ch["speed"]
	fix_speed = ch["fix"]
	_quiet = ch["quiet"]
	var utility: String = RoundManager.loadout["utility"]
	if utility == "boots":
		_speed_mult *= 1.2
	if utility == "earplugs":
		_quiet *= 0.6
	_lamp.visible = utility == "lantern"


## Called by interactables (machines, containers) so nearby Corruptions can hear the work.
func make_noise(radius: float) -> void:
	_extra_noise = maxf(_extra_noise, radius * _quiet)
	_extra_until_ms = Time.get_ticks_msec() + 300


## How far away the player can currently be heard.
func current_noise() -> float:
	var extra := _extra_noise if Time.get_ticks_msec() < _extra_until_ms else 0.0
	return maxf(_noise, extra)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not frozen:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.4, 1.4)
		_cam.rotation.x = _pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB and not frozen:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var x := 0.0
	var z := 0.0
	var sprint := false
	if not frozen:
		if Input.is_physical_key_pressed(KEY_D): x += 1.0
		if Input.is_physical_key_pressed(KEY_A): x -= 1.0
		if Input.is_physical_key_pressed(KEY_S): z += 1.0
		if Input.is_physical_key_pressed(KEY_W): z -= 1.0
		sprint = Input.is_physical_key_pressed(KEY_SHIFT)
	var dir := (transform.basis * Vector3(x, 0.0, z)).normalized()
	var speed := BASE_SPEED * _speed_mult * RoundManager.slow_factor * (SPRINT_MULT if sprint else 1.0)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	var moving := dir.length() > 0.1
	_noise = (12.0 if sprint else 5.0) * _quiet if moving else 0.0
