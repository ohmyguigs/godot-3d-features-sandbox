extends Node3D
@onready var bg_viewport = $base_camera/background_viewport_container/background_viewport as SubViewport
@onready var fg_viewport = $base_camera/forground_viewport_container/forground_viewport as SubViewport

@onready var bg_camera = $base_camera/background_viewport_container/background_viewport/background_camera as Camera3D
@onready var fg_camera = $base_camera/forground_viewport_container/forground_viewport/forground_camera as Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():

	resize()

func resize():
	bg_viewport.size = DisplayServer.window_get_size()
	fg_viewport.size = DisplayServer.window_get_size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	bg_camera.global_transform = GameManager.player1.camera_pov.global_transform
	fg_camera.global_transform = GameManager.player1.camera_pov.global_transform
