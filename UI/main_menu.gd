extends Node2D

@onready var paused_bg = $BG
@onready var box = $CanvasLayer/VBoxContainer
@onready var target_scale : Vector2

# Buttons
@onready var Load_button = $CanvasLayer/VBoxContainer/Load
@onready var play_button = $CanvasLayer/VBoxContainer/Play
@onready var quit_button = $CanvasLayer/VBoxContainer/Quit
@onready var credits = $CanvasLayer/VBoxContainer2
@onready var buttons = $CanvasLayer/VBoxContainer

# Loading label
@onready var loading_label = $LoadingLabel

var game_scene : PackedScene
var game_scene_path := "res://Level/Level_prototype/level.tscn"
var is_loading := true

func _ready() -> void:
	# Start loading the game scene asynchronously
	ResourceLoader.load_threaded_request(game_scene_path)

	# Hide and disable all buttons while loading
	_set_buttons_enabled(false)

	_on_resize()

	#focus play_button
	play_button.focus_mode = Control.FOCUS_ALL
	play_button.grab_focus()  #makes it the currently focused control

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_resize():
	var texture_size = paused_bg.texture.get_size()
	var screen_size = get_viewport().get_visible_rect().size

	var scale_factor = max(screen_size.x / texture_size.x, screen_size.y / texture_size.y)
	paused_bg.scale = Vector2(scale_factor, scale_factor)
	paused_bg.position = screen_size / 2

	# Scale and center menu boxes
	box.scale = Vector2(scale_factor - 0.1, scale_factor - 0.1)
	credits.scale = Vector2(scale_factor - 0.1, scale_factor - 0.1)

	var vbox_size = box.get_combined_minimum_size() * box.scale
	box.position = (screen_size - vbox_size) / 2

	var credits_size = box.get_combined_minimum_size() * box.scale
	credits.position = Vector2(0, (screen_size.y - credits_size.y))

	# Center loading text
	loading_label.position = screen_size / 2

func _process(_delta):
	if is_loading:
		var status = ResourceLoader.load_threaded_get_status(game_scene_path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				if loading_label:
					loading_label.text = "Loading..."
			ResourceLoader.THREAD_LOAD_LOADED:
				game_scene = ResourceLoader.load_threaded_get(game_scene_path)
				is_loading = false
				if loading_label:
					loading_label.text = ""
				_set_buttons_enabled(true)
			ResourceLoader.THREAD_LOAD_FAILED:
				if loading_label:
					loading_label.text = "Failed to load game!"
				is_loading = false

func _on_play_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("Game scene not ready yet!")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _set_buttons_enabled(enabled: bool):
	buttons.visible = enabled
	for child in buttons.get_children():
		if child is TextureButton:
			child.disabled = not enabled
