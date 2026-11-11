extends CharacterBody3D
## First-person walker. WASD to move, mouse to look, Tab to release/capture the mouse.

const SPEED := 6.0
const MOUSE_SENS := 0.0025
const GRAVITY := 20.0

var _cam: Camera3D
var _pitch := 0.0


func _ready() -> void:
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

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.4, 1.4)
		_cam.rotation.x = _pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var x := 0.0
	var z := 0.0
	if Input.is_physical_key_pressed(KEY_D): x += 1.0
	if Input.is_physical_key_pressed(KEY_A): x -= 1.0
	if Input.is_physical_key_pressed(KEY_S): z += 1.0
	if Input.is_physical_key_pressed(KEY_W): z -= 1.0
	var dir := (transform.basis * Vector3(x, 0.0, z)).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
