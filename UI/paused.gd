extends Node2D

@onready var base = $CanvasLayer
@onready var resume = $CanvasLayer/VBoxContainer/resume
@onready var quit = $CanvasLayer/VBoxContainer/quit
@onready var menu_scene = "res://UI/main_menu.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var screen_size = get_viewport().get_visible_rect().size
	var bg_size: Vector2 = Vector2(1920,1080)
	var target_scale = abs(screen_size.x / bg_size.x)

	base.scale = Vector2(target_scale, target_scale)* 0.4

	resume.pressed.connect(_resume_pressed)
	quit.pressed.connect(_quit_pressed)

func _resume_pressed() -> void:
	print("button clicked")
	get_tree().paused = false
	self.queue_free()

func _quit_pressed() -> void:
	print("Quit to menu button clicked")
	get_tree().paused = false
	
	# Change to main menu scene
	get_tree().change_scene_to_file(menu_scene)
