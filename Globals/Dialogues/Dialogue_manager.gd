extends Area2D

@onready var area = $"."
@onready var dialogue = $Layer/Container
@onready var label = $Layer/Container/RichTextLabel
@onready var text = get_node("/root/Level/Dialogue")
@onready var hide_timer: Timer 

var text_timeout: float = 20.0
var has_shown: bool = false 

@export var dialogue_text = "Welcome to the mining station, Commander!"

func _ready() -> void:
	dialogue.visible = false  # hide at start

	hide_timer = Timer.new()
	hide_timer.wait_time = text_timeout
	hide_timer.one_shot = true
	add_child(hide_timer)
	hide_timer.timeout.connect(_on_hide_timer_timeout)

	for trigger in text.get_children():
		if trigger.has_signal("dialogue_script"):
			trigger.dialogue_script.connect(_display_text)

	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and not has_shown:
		has_shown = true 
		print_message(dialogue_text)

func _display_text(message) -> void:
	print_message(message)

func print_message(txt) -> void:
	dialogue.visible = true

	# Reset timer if new message or new entry
	if label.text != txt:
		label.text = txt
		hide_timer.stop()
		hide_timer.start()
	else:
		hide_timer.start()
		
func _on_hide_timer_timeout() -> void:
	dialogue.visible = false