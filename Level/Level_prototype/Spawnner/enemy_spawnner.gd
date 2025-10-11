extends Node2D

@onready var area = $Area2D
@onready var level = get_node("/root/Level/Enemies")

var markers: Array[Marker2D] = []
var enemy_number: int = 5
var respawn_delay: float = 45.0

var bomber_bot_scene = preload("res://Enemies/bomber_bot/bomber_bot.tscn")

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	for child in get_children():
		if child is Marker2D:
			markers.append(child)

func spawn_enemies() -> void:
	if markers.is_empty() or level == null:
		return

	for i in range(enemy_number):
		var spawn_point = markers.pick_random()
		var bomber_bot = bomber_bot_scene.instantiate()
		bomber_bot.global_position = spawn_point.global_position
		level.add_child(bomber_bot)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		# Defer everything that modifies the scene or physics
		call_deferred("_deferred_spawn_and_disable")

func _deferred_spawn_and_disable() -> void:
	spawn_enemies()
	area.monitoring = false
	_reactivate_area()

func _reactivate_area() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	area.monitoring = true
