extends Node2D

@onready var area: Area2D = $Area2D
@onready var level: Node = get_node("/root/Level/Enemies")
@onready var polygon: Polygon2D = $Polygon

@export var enemy_number: int = 5
var respawn_delay: float = 45.0
var spawn_delay: float = 0.5

var bomber_bot_scene = preload("res://Enemies/bomber_bot/bomber_bot.tscn")

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	polygon.modulate.a = 0.0

func spawn_enemies() -> void:
	if level == null or polygon == null:
		push_warning("Level or Polygon2D not found!")
		return

	for i in range(enemy_number):
		var spawn_point = get_random_point_in_polygon(polygon)
		if spawn_point == Vector2.ZERO:
			continue

		var bomber_bot = bomber_bot_scene.instantiate()
		bomber_bot.set_physics_process(false)
		bomber_bot.global_position = spawn_point
		level.add_child(bomber_bot)
		await get_tree().create_timer(spawn_delay).timeout
		bomber_bot.set_physics_process(true)

func get_random_point_in_polygon(poly: Polygon2D) -> Vector2:
	var poly_points: PackedVector2Array = poly.polygon
	if poly_points.is_empty():
		return Vector2.ZERO

	var aabb = Rect2()
	aabb.position = poly_points[0]
	for p in poly_points:
		aabb = aabb.expand(p)

	var tries = 100
	while tries > 0:
		tries -= 1
		var local_point = Vector2(
			randf_range(aabb.position.x, aabb.position.x + aabb.size.x),
			randf_range(aabb.position.y, aabb.position.y + aabb.size.y)
		)
		if Geometry2D.is_point_in_polygon(local_point, poly_points):
			# Convert to global position (Polygon2D may be offset/rotated)
			return poly.to_global(local_point)
	return Vector2.ZERO

func _on_body_entered(body: Node) -> void:
	if body is Player:
		call_deferred("_deferred_spawn_and_disable")

func _deferred_spawn_and_disable() -> void:
	spawn_enemies()
	area.monitoring = false
	_reactivate_area()

func _reactivate_area() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	area.monitoring = true
