extends Node2D

@onready var paused_bg = $BG
@onready var grid = $BG2
@onready var anime = $motion_graphics
@onready var box = $CanvasLayer/VBoxContainer
@onready var target_scale : Vector2

# Buttons
@onready var Load_button = $CanvasLayer/VBoxContainer/Load
@onready var play_button = $CanvasLayer/VBoxContainer/Play
@onready var quit_button = $CanvasLayer/VBoxContainer/Quit
@onready var credits = $CanvasLayer/VBoxContainer2
@onready var buttons = $CanvasLayer/VBoxContainer
@onready var credits_button = $CanvasLayer/VBoxContainer2/TextureButton

# Loading label
@onready var loading_label = $VBoxContainer/LoadingLabel
@onready var loading_label_container = $VBoxContainer

# Loading progress bar
@onready var progress = $TextureProgressBar

var game_scene : PackedScene
var game_scene_path := "res://Level/Level_prototype/level.tscn"
var is_loading := true
var middle : Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

	# Scale Center loading
	# var grid_texture = grid.texture.get_size()
	# var grid_scale = max(screen_size.x / grid_texture.x, screen_size.y / grid_texture.y)

	# grid.scale = Vector2(grid_scale, grid_scale)

	anime.scale = box.scale * 0.6

	middle = screen_size / 2
	
	grid.position = middle
	anime.position = middle

	# Position progress bar below the animated sprite
	if progress:
		progress.scale = box.scale * 1.5  # Adjust multiplier as needed
		
		# Position progress bar centered horizontally and below the sprite
		progress.position = Vector2(
			middle.x - (progress.size.x * progress.scale.x) / 2,  # Center horizontally
			middle.y + 150  # Fixed offset below center
		)

func _process(_delta):
	if is_loading:
		var progress_array = []  # Create array to store progress
		var status = ResourceLoader.load_threaded_get_status(game_scene_path, progress_array)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				if loading_label:
					# Update progress bar based on loading progress
					# progress_array now contains the progress value (0.0 to 1.0)
					if progress_array.size() > 0:
						var percent = progress_array[0] * 100  # Convert to percentage
						progress.value = percent
						loading_label.text = "Loading... %d%%" % percent
					else:
						loading_label.text = "Loading..."
						progress.value = 0
					
					var loading_size = loading_label.get_combined_minimum_size()
					# loading_label_container.position = Vector2((middle.x - loading_size.x) - (loading_size.x/2), (middle.y - (loading_size.y - 200)))
					loading_label_container.position = Vector2(\
						((middle.x - loading_size.x / 2) - 30),  # Center horizontally
						middle.y + 180  # Fixed offset below center (adjust as needed)
					)
			ResourceLoader.THREAD_LOAD_LOADED:
				game_scene = ResourceLoader.load_threaded_get(game_scene_path)
				is_loading = false
				if loading_label:
					loading_label.text = "Loaded"
				if progress:
					progress.value = 100  # Set to 100% when complete
				# Small delay to show 100% before hiding
				await get_tree().create_timer(0.5).timeout
				_set_buttons_enabled(true)
			ResourceLoader.THREAD_LOAD_FAILED:
				if loading_label:
					loading_label.text = "Failed to load game!"
				if progress:
					progress.value = 0
				is_loading = false

func _on_play_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("Game scene not ready yet!")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _set_buttons_enabled(enabled: bool):
	# Loading 
	grid.visible = not enabled
	loading_label.visible = not enabled
	anime.visible = not enabled
	if anime.visible:
		anime.play("default")

	if progress:
		progress.visible = not enabled

	# menu
	buttons.visible = enabled 
	credits_button.visible = enabled
	for child in buttons.get_children():
		if child is TextureButton:
			child.disabled = not enabled
