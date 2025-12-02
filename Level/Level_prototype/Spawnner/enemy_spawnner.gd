extends Node2D

@onready var area: Area2D = $Area2D
@onready var level: Node = get_node("/root/Level/Enemies")
@onready var polygon: Polygon2D = $Polygon

@export var enemy_number: int = 5
var respawn_delay: float = 45.0
var spawn_delay: float = 0.5

var bomber_bot_scene = preload("res://Enemies/bomber_bot/bomber_bot.tscn")

# Thread for spawning enemies
var spawn_thread: Thread
var spawn_queue: Array = []

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	polygon.modulate.a = 0.0
	
	# Initialize spawn thread
	spawn_thread = Thread.new()
	
	# Start processing spawn queue
	call_deferred("_process_spawn_queue")

func _exit_tree() -> void:
	# Wait for thread to finish if it's running
	if spawn_thread and spawn_thread.is_started():
		spawn_thread.wait_to_finish()

func spawn_enemies() -> void:
	if level == null or polygon == null:
		push_warning("Level or Polygon2D not found!")
		return
	
	# Add spawn job to queue
	var spawn_data = {
		"enemy_number": enemy_number,  # Use class variable
		"polygon_points": polygon.polygon,
		"polygon_transform": polygon.get_global_transform(),
		"spawn_delay": spawn_delay  # Use class variable
	}
	spawn_queue.append(spawn_data)
	
	# Start thread if not already running
	if spawn_thread and not spawn_thread.is_started():
		spawn_thread.start(_thread_spawn_enemies)

func _thread_spawn_enemies() -> void:
	# Process all spawn jobs in the queue
	while spawn_queue.size() > 0:
		var spawn_data = spawn_queue.pop_front()
		_thread_process_spawn(spawn_data)

func _thread_process_spawn(spawn_data: Dictionary) -> void:
	var polygon_points: PackedVector2Array = spawn_data["polygon_points"]
	var polygon_transform: Transform2D = spawn_data["polygon_transform"]
	var current_enemy_number: int = spawn_data["enemy_number"]  # Different name
	var current_spawn_delay: float = spawn_data["spawn_delay"]   # Different name
	
	if polygon_points.is_empty():
		call_deferred("_spawn_completed")
		return
	
	# Calculate AABB in polygon's local space
	var aabb = Rect2()
	aabb.position = polygon_points[0]
	for p in polygon_points:
		aabb = aabb.expand(p)
	
	var spawn_points: Array[Vector2] = []
	var tries_per_enemy = 50  # Max attempts to find a valid point per enemy
	
	for i in range(current_enemy_number):  # Use current_enemy_number
		var found_point = false
		var attempts = tries_per_enemy
		
		while attempts > 0 and not found_point:
			attempts -= 1
			var local_point = Vector2(
				randf_range(aabb.position.x, aabb.position.x + aabb.size.x),
				randf_range(aabb.position.y, aabb.position.y + aabb.size.y)
			)
			
			if Geometry2D.is_point_in_polygon(local_point, polygon_points):
				# Convert to global position using the transform
				var global_point = polygon_transform * local_point
				spawn_points.append(global_point)
				found_point = true
				break
		
		# If no valid point found after max attempts, skip this enemy
		if not found_point:
			spawn_points.append(Vector2.ZERO)
	
	# Use call_deferred to add enemies to the scene tree (must be done on main thread)
	call_deferred("_instantiate_enemies", spawn_points, current_spawn_delay)  # Use current_spawn_delay

func _instantiate_enemies(spawn_points: Array[Vector2], current_spawn_delay: float) -> void:
	if level == null:
		return
	
	for i in range(spawn_points.size()):
		var spawn_point = spawn_points[i]
		if spawn_point == Vector2.ZERO:
			continue
		
		var bomber_bot = bomber_bot_scene.instantiate()
		bomber_bot.set_physics_process(false)
		bomber_bot.global_position = spawn_point
		level.add_child(bomber_bot)
		
		# Add a small delay between spawns (on main thread)
		if i < spawn_points.size() - 1:  # Don't wait after the last one
			await get_tree().create_timer(current_spawn_delay).timeout  # Use current_spawn_delay
		
		bomber_bot.set_physics_process(true)
	
	# Signal that spawning is complete
	call_deferred("_spawn_completed")

func _spawn_completed() -> void:
	# This function can be used to signal completion or trigger other events
	pass

func _process_spawn_queue() -> void:
	# This function runs on the main thread to periodically check if new spawns are needed
	if spawn_queue.size() > 0 and spawn_thread and not spawn_thread.is_started():
		spawn_thread.start(_thread_spawn_enemies)

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