extends CharacterBody3D

@onready var animationPlayer = $Visuals/char1_in_place_mixamo/AnimationPlayer as AnimationPlayer
@onready var visuals = $Visuals as Node3D
const SPEED = 3.0
var isWalking = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("walk_left", "walk_right", "walk_front", "walk_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		visuals.look_at(direction + position)
		if !isWalking:
			isWalking = true
			animationPlayer.play("walk_slow")
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if isWalking:
			isWalking = false
			animationPlayer.play("idle")

	move_and_slide()
