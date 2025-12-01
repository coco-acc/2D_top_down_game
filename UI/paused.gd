extends Node2D

@onready var background = $PausedBg
@onready var resume = $PausedBg/VBoxContainer/resume

func _ready() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var bg_size = background.texture.get_size()
	var target_scale = abs(screen_size.x / bg_size.x)

	background.scale = Vector2(target_scale, target_scale)

	resume.pressed.connect(_resume_pressed)

func _resume_pressed() -> void:
	get_tree().paused = false
	self.queue_free()
