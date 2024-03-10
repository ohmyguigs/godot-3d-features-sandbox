extends Node3D
@onready var bg_viewport = $camera_inner_gimbal/base_camera/background_viewport_container/background_viewport as SubViewport
@onready var fg_viewport = $camera_inner_gimbal/base_camera/forground_viewport_container/forground_viewport as SubViewport

@onready var bg_camera = $camera_inner_gimbal/base_camera/background_viewport_container/background_viewport/background_camera as Camera3D
@onready var fg_camera = $camera_inner_gimbal/base_camera/forground_viewport_container/forground_viewport/forground_camera as Camera3D

@onready var outter_gimbal = $"."
@onready var inner_gimbal = $camera_inner_gimbal

# Called when the node enters the scene tree for the first time.
func _ready():
	resize()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(_event):
	#if event is InputEvent.MO
	pass

func resize():
	bg_viewport.size = DisplayServer.window_get_size()
	fg_viewport.size = DisplayServer.window_get_size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	bg_camera.global_transform = GameManager.player1.camera_pov.global_transform
	fg_camera.global_transform = GameManager.player1.camera_pov.global_transform
