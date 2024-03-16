extends CharacterBody3D
class_name PlayerClass

@onready var animationPlayer = $Visuals/char1_in_place_mixamo/AnimationPlayer as AnimationPlayer
@onready var visuals = $Visuals as Node3D

@onready var running_pressed: bool = false
@onready var is_idle:bool = true
@onready var is_rolling: bool = false
@onready var rolling_timer = 0
@onready var roll_direction_cache

# Camera
@onready var yGimbal:Node3D = $yCameraGimbal
@onready var xGimbal:Node3D = $yCameraGimbal/xCameraGimbal
@onready var camera:Camera3D = $yCameraGimbal/xCameraGimbal/camera

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

func reset_camera_y_rotation_to_player():
	yGimbal.global_rotation.y = self.global_rotation.y

func reset_player_y_rotation_to_camera():
	var inetndedRotation = yGimbal.global_rotation.y
	self.global_rotation.y = inetndedRotation
	yGimbal.global_rotation.y = inetndedRotation

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if event.relative.x != 0:
			var dir = 1 if invert_x else -1
			if is_idle:
				print("1-yGimbalRot: %f" % [yGimbal.global_rotation.y])
				yGimbal.rotate_object_local(Vector3.UP, dir * event.relative.x * mouse_sensitivity)
				print("2-yGimbalRot: %f" % [yGimbal.global_rotation.y])
			else:
				self.rotate_object_local(Vector3.UP, dir * event.relative.x * mouse_sensitivity)
				print("selfRot: %f" % [dir * event.relative.x * mouse_sensitivity])
		if event.relative.y != 0:
			var dir = 1 if invert_y else -1
			var xGimbalCurrentRotationAngle = xGimbal.global_rotation.x
			print("1-xGimbalRot: %f" % [xGimbalCurrentRotationAngle])
			#if xGimbalCurrentRotationAngle <= -0.313:
				#xGimbal.global_rotation.x = -0.313
				#return # clamping
			xGimbal.rotate_object_local(Vector3.RIGHT, dir * event.relative.y * mouse_sensitivity)
			print("2-xGimbalRot: %f" % [xGimbalCurrentRotationAngle])

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
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		is_idle = false
		if Input.is_action_pressed("sprint"):
			running_pressed = true if !is_rolling else false
		elif Input.is_action_just_released("sprint"):
			running_pressed = false

		
		if Input.is_action_just_pressed("roll"):
			rolling_timer += delta
			is_rolling = true
			roll_direction_cache = direction

		var speed = get_derived_velocity()
		if is_rolling:
			velocity.x = roll_direction_cache.x * speed
			velocity.z = roll_direction_cache.z * speed
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			visuals.look_at(direction + position)
			reset_player_y_rotation_to_camera()

		if speed == SLOW_WALK_SPEED:
			animationPlayer.play("walk_slow", 0.2)
		elif speed == FAST_WALK_SPEED:
			animationPlayer.play("walk_fast", 0.2)
		elif speed == RUN_SPEED:
			animationPlayer.play("run", 0.2)
		elif speed == ROLL_SPEED:
			animationPlayer.play("roll", 0.2)
	else:
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
