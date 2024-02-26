extends CharacterBody3D
class_name PlayerClass

@onready var animationPlayer = $Visuals/char1_in_place_mixamo/AnimationPlayer as AnimationPlayer
@onready var visuals = $Visuals as Node3D
@onready var camera_pov = $camera_pov as Node3D

const SPEED_STRENGTH_CAP = 0.33
const SLOW_WALK_SPEED = 1.0
const FAST_WALK_SPEED = 3.0
const ROLL_SPEED = 6.3
const RUN_SPEED = 6.0

var running_pressed: bool = false
var is_rolling: bool = false # here goes the iframes
var rolling_timer = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	GameManager.set_player1(self)

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
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("walk_left", "walk_right", "walk_front", "walk_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		if Input.is_action_pressed("sprint"):
			running_pressed = true if !is_rolling else false
		elif Input.is_action_just_released("sprint"):
			running_pressed = false

		if is_rolling:
			rolling_timer += delta
		if Input.is_action_just_pressed("roll"):
			rolling_timer += delta
			is_rolling = true
		
		if rolling_timer >= animationPlayer.get_animation("roll").length:
			rolling_timer = 0
			is_rolling = false

		var speed = get_derived_velocity()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		visuals.look_at(direction + position)

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
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		animationPlayer.play("idle")

	move_and_slide()
