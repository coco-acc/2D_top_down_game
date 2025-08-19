extends CanvasLayer

@onready var health_label = $HBoxContainer2/MarginContainer2/Health
@onready var ammo_label = $HBoxContainer/MarginContainer/Ammo
@onready var health_bar = $MarginContainer3/ProgressBar
# @onready var score_label = $MarginContainer/VBoxContainer/ScoreLabel

func set_health(value: int) -> void:
	health_label.text = "Health: %d" % value
	health_bar.value = value

func set_ammo(value: int) -> void:
	ammo_label.text = "Ammo: %d" % value

# func set_score(value: int) -> void:
#     score_label.text = "Score: %d" % value
