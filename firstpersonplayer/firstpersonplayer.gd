extends CharacterBody3D

const EYE_HEIGHT_STAND = 1.5
const EYE_HEIGHT_CROUCH = 0.75

const MOVEMENT_SPEED_GROUND = 0.6
const MOVEMENT_SPEED_AIR = 0.11
const MOVEMENT_SPEED_CROUCH_MODIFIER = 0.5
const MOVEMENT_FRICTION_GROUND = 0.9
const MOVEMENT_FRICTION_AIR = 0.98
const JUMP_POWER = 4.5

var _mouse_motion = Vector2()
var _prev_interactable: Interactable

var _crouch_counter: float = 0

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D
@onready var camera: Node3D = $HeadPosition

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	# Mouse movement.
	_mouse_motion.y = clamp(_mouse_motion.y, -1560, 1560)
	transform.basis = Basis.from_euler(Vector3(0, _mouse_motion.x * -0.001, 0))
	camera.transform.basis = Basis.from_euler(Vector3(_mouse_motion.y * -0.001, 0, 0))

func _physics_process(delta: float) -> void:
	HandleMovement(delta)
	HandleRaycast()

func HandleMovement(delta: float):
	# Keyboard movement.
	var crouching = Input.is_action_pressed(&"crouch")
	if crouching:
		_crouch_counter += delta
	else:
		_crouch_counter -= delta
	_crouch_counter = clampf(_crouch_counter, 0, 0.5)
	camera.transform.origin.y = lerpf(camera.transform.origin.y, EYE_HEIGHT_CROUCH if crouching else EYE_HEIGHT_STAND, _crouch_counter)

	var movement_vec2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var movement = transform.basis * (Vector3(movement_vec2.x, 0, movement_vec2.y))

	if is_on_floor():
		movement *= MOVEMENT_SPEED_GROUND
	else:
		movement *= MOVEMENT_SPEED_AIR

	if crouching:
		movement *= MOVEMENT_SPEED_CROUCH_MODIFIER

	# Gravity.
	velocity.y -= gravity * delta

	velocity += Vector3(movement.x, 0, movement.z)
	# Apply horizontal friction.
	velocity.x *= MOVEMENT_FRICTION_GROUND if is_on_floor() else MOVEMENT_FRICTION_AIR
	velocity.z *= MOVEMENT_FRICTION_GROUND if is_on_floor() else MOVEMENT_FRICTION_AIR
	move_and_slide()

	# Jumping, applied next frame.
	if is_on_floor() and Input.is_action_pressed(&"jump"):
		velocity.y = JUMP_POWER

func HandleRaycast():
	var collider = ray_cast_3d.get_collider()
	if collider != null and collider is Interactable:
		if collider != _prev_interactable:
			if _prev_interactable != null:
				_prev_interactable.on_ray_exited.emit()
			collider.on_ray_entered.emit()
			_prev_interactable = collider
		if Input.is_action_just_pressed("interact"):
			collider.interacted.emit()
	elif _prev_interactable != null:
		_prev_interactable.on_ray_exited.emit()
		_prev_interactable = null

func _input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_mouse_motion += event.relative
