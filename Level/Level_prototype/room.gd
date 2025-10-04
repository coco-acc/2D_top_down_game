extends Node2D
@onready var area := $Area2D
@onready var cover := $cover

func _ready() -> void:
	cover.show()
	cover.z_index = 6
	cover.y_sort_enabled = true
	cover.z_as_relative = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body) -> void:
	if body is Player:
		cover.hide()

func _on_body_exited(body) -> void:
	if body is Player:
		cover.show()
