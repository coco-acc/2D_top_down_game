extends Area2D

signal dialogue_script
@export var dialogue_text: String = ""
var has_shown: bool = false

func _ready() -> void:
	# self.add_to_group("dialogue_triggers")
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and not has_shown:
		dialogue_script.emit(dialogue_text)
		has_shown = true 