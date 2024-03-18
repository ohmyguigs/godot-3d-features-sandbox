extends CharacterBody3D

@onready var animationPlayer:AnimationPlayer = $Visuals/character_1/AnimationPlayer
@onready var camera_pov:Camera3D = $yCameraGimbal/xCameraGimbal/Camera3D

@onready var is_waving:bool = false

const SPEED = 5.0
const RAY_LENGTH = 5 # detection proximity

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if !is_waving:
		animationPlayer.play("idle", 0.2)

	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin = camera_pov.project_ray_origin(mousepos)
	var end = origin + camera_pov.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var detectedEntitiesInArea = space_state.intersect_ray(query)
	if detectedEntitiesInArea:
		#print("detectedEntities: %s" % [detectedEntitiesInArea])
		is_waving = true
		animationPlayer.play("wave", 0.2)
	else:
		is_waving = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)

	#move_and_slide()
