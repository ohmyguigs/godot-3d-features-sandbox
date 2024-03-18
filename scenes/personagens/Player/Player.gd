extends CharacterBody3D
class_name PlayerClass

@onready var animationPlayer = $Visuals/character_1/AnimationPlayer as AnimationPlayer
@onready var visuals = $Visuals as Node3D

@onready var running_pressed: bool = false
@onready var is_idle:bool = true
@onready var is_rolling: bool = false
@onready var rolling_timer = 0
@onready var roll_direction_cache

# Camera
@onready var yGimbal:Node3D = $yCameraGimbal
@onready var xGimbal:Node3D = $yCameraGimbal/xCameraGimbal
@onready var camera:Camera3D = $yCameraGimbal/xCameraGimbal/SpringArm3D/camera

# joystick properties
@onready var jouystick_sensitivity:float = 0.03
# mouse properties
@onready var mouse_control:bool = false
@onready var mouse_sensitivity:float = 0.005
@onready var invert_y:bool = false
@onready var invert_x:bool = false

# zoom settings
@onready var max_zoom:float = 3.0
@onready var min_zoom:float = 0.4
@onready var zoom_speed:float = 0.09

# Physics
# Get the gravity from the project settings to be synced with RigidBody nodes.
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const SPEED_STRENGTH_CAP = 0.33
const SLOW_WALK_SPEED = 1.0
const FAST_WALK_SPEED = 3.0
const ROLL_SPEED = 6.3
const RUN_SPEED = 6.0

func _ready():
	GameManager.set_player1(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	handle_joystick_camera_control()

func adjust_motion_direction_rotation_to_camera(direction):
	if yGimbal.rotation.y == self.rotation.y:
		return direction # do nothing if camera already aligned
	return direction.rotated(Vector3.UP, yGimbal.rotation.y)
	
func rotate_camera_xgimbal_vertical(dir, strength, sensitivity):
	xGimbal.rotate_object_local(Vector3.RIGHT, dir * strength * sensitivity)

func rotate_camera_ygimbal_horizontal(dir, strength, sensitivity):
	yGimbal.rotate_object_local(Vector3.UP, dir * strength * sensitivity)
	
func rotate_player_horizontal(dir, strength, sensitivity):
	self.rotate_object_local(Vector3.UP, dir * strength * sensitivity)
	
func handle_joystick_camera_control():
	if Input.is_action_pressed("camera_up") || Input.is_action_just_pressed("camera_up"):
		var dir = 1 if invert_x else -1
		var uStr = Input.get_action_strength("camera_up")
		rotate_camera_xgimbal_vertical(dir, uStr, jouystick_sensitivity)
	if Input.is_action_pressed("camera_down"):
		var dir = -1 if invert_x else 1
		var dStr = Input.get_action_strength("camera_down")
		rotate_camera_xgimbal_vertical(dir, dStr, jouystick_sensitivity)
	if Input.is_action_pressed("camera_left") || Input.is_action_just_pressed("camera_left"):
		var dir = -1 if invert_y else 1
		var lStr = Input.get_action_strength("camera_left")
		if is_idle:
			rotate_camera_ygimbal_horizontal(dir, lStr, jouystick_sensitivity)
		else:
			rotate_player_horizontal(dir, lStr, jouystick_sensitivity)
	if Input.is_action_pressed("camera_right"):
		var dir = 1 if invert_y else -1
		var rStr = Input.get_action_strength("camera_right")
		if is_idle:
			rotate_camera_ygimbal_horizontal(dir, rStr, jouystick_sensitivity)
		else:
			rotate_player_horizontal(dir, rStr, jouystick_sensitivity)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if event.relative.x != 0:
			var dir = 1 if invert_x else -1
			if is_idle:
				rotate_camera_ygimbal_horizontal(dir, event.relative.x, mouse_sensitivity)
			else:
				rotate_player_horizontal(dir, event.relative.x, mouse_sensitivity)
		if event.relative.y != 0:
			var dir = 1 if invert_y else -1
			var xGimbalCurrentRotationAngle = xGimbal.global_rotation.x
			if xGimbalCurrentRotationAngle <= -0.313:
				#xGimbal.rotation.x = lerp(xGimbal.rotation.x, -0.313, mouse_sensitivity)
				var clampedStr = event.relative.y if event.relative.y < 0 else 0
				rotate_camera_xgimbal_vertical(dir, clampedStr, mouse_sensitivity) # prevent moving
			elif xGimbalCurrentRotationAngle >= 0.313:
				#xGimbal.rotation.x = lerp(xGimbal.rotation.x, -0.025, mouse_sensitivity)
				var clampedStr = event.relative.y if event.relative.y > 0 else 0
				rotate_camera_xgimbal_vertical(dir, clampedStr, mouse_sensitivity) # prevent moving
			else:
				rotate_camera_xgimbal_vertical(dir, event.relative.y, mouse_sensitivity)

func get_derived_velocity():
	if is_rolling:
		return ROLL_SPEED
	if running_pressed:
		return RUN_SPEED
	var rStr = Input.get_action_strength("walk_right")
	var strength_x = rStr if rStr > 0.0 else Input.get_action_strength("walk_left")
	var fStr = Input.get_action_strength("walk_front")
	var strength_y = fStr if fStr > 0.0 else Input.get_action_strength("walk_back")
	if (strength_x > SPEED_STRENGTH_CAP || strength_y > SPEED_STRENGTH_CAP):
		return FAST_WALK_SPEED
	else:
		return SLOW_WALK_SPEED

func _physics_process(delta):
	# Add the gravity / handle falling.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_rolling:
			rolling_timer += delta
	if rolling_timer >= animationPlayer.get_animation("roll").length:
			rolling_timer = 0
			is_rolling = false

	var input_dir = Input.get_vector("walk_left", "walk_right", "walk_front", "walk_back")
	var direction = (self.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		#print("direction: %s" % [direction])
		is_idle = false
		if Input.is_action_pressed("sprint"):
			running_pressed = true if !is_rolling else false
		elif Input.is_action_just_released("sprint"):
			running_pressed = false

		
		if Input.is_action_just_pressed("roll"):
			rolling_timer += delta
			is_rolling = true
			var rotatedDirection = adjust_motion_direction_rotation_to_camera(direction)
			direction = rotatedDirection
			roll_direction_cache = direction

		var speed = get_derived_velocity()
		if is_rolling:
			velocity.x = roll_direction_cache.x * speed
			velocity.z = roll_direction_cache.z * speed
		else:
			var rotatedDirection = adjust_motion_direction_rotation_to_camera(direction)
			direction = rotatedDirection
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			visuals.look_at(direction + self.position)

		if speed == SLOW_WALK_SPEED:
			animationPlayer.play("walk_slow", 0.2)
		elif speed == FAST_WALK_SPEED:
			animationPlayer.play("walk_fast", 0.2)
		elif speed == RUN_SPEED:
			animationPlayer.play("run", 0.2)
		elif speed == ROLL_SPEED:
			animationPlayer.play("roll", 0.2)
	else:
		if Input.is_action_just_released("sprint"):
			running_pressed = false
		var speed = get_derived_velocity()
		if is_rolling:
			velocity.x = roll_direction_cache.x * speed
			velocity.z = roll_direction_cache.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			animationPlayer.play("idle")
			is_idle = true

	move_and_slide()
