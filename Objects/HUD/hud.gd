extends CanvasLayer

@onready var ammo_label = $HBoxContainer/MarginContainer/Ammo
@onready var health_bar = $Health_and_Stamina/MarginContainer2/Health
@onready var scrap = $Scrap/MarginContainer4/Scrap
@onready var stamina = $stamina/StaminaContainer/stamina

func _ready() -> void:
	_on_resize()
	# DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	

func set_health(value: int) -> void:
	health_bar.value = value

func set_ammo(value: int) -> void:
	ammo_label.text = "Ammo: %d" % value

func set_stamina(value: int) -> void:
	stamina.value = value
	# stamina.max_value = max_val

func set_currency(value: int) -> void:
	# print("Updating HUD scrap to:", value)
	scrap.text = "%d" % value

func _on_resize():
	var screen_size = get_viewport().get_visible_rect().size
	var base_size = Vector2(1920, 1080)
	var scale_factor = abs(screen_size.x / base_size.x)
	scale = Vector2(scale_factor, scale_factor)
