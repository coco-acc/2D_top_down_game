extends TextureButton
var pause_scene_path = "res://UI/paused.tscn"

func _ready() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.pressed.connect(_pause_pressed)
	_on_resize()

func _pause_pressed() -> void:
	if not get_tree().paused:
		get_tree().paused = true  # Pause all gameplay
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		var pause_scene = load(pause_scene_path)
		var pause_menu_instance = pause_scene.instantiate()
		add_child(pause_menu_instance)

		# Make sure PauseMenu receives input while paused
		# pause_menu_instance.pause_mode = Node.PAUSE_MODE_PROCESS

func _on_resize():
	var screen_size = get_viewport().get_visible_rect().size
	var base_size = Vector2(1920, 1080)
	var scale_factor = abs(screen_size.x / base_size.x)
	
	scale = Vector2(scale_factor, scale_factor) * 0.25

	# Position pause icon at top middle
	var pause_icon_size = self.get_combined_minimum_size() * self.scale
	var pos = (screen_size.x - pause_icon_size.x)/2
	print(screen_size)
	self.position = Vector2(pos, 20)
