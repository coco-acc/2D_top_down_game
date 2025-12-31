extends Node2D
class_name Obstacles

@onready var player: Node2D = get_node("/root/Level/Player")  # Direct reference to player node
var obstacle_children: Array[Node]
var timer := Timer.new()
var obstacle_swap_states := {}  # Dictionary to track swap states per obstacle
var obstacle_swap_groups := {}
var was_crouching := false  # Track previous crouch state

func _ready() -> void:
	# Create and configure the timer
	timer.wait_time = player.jump_await
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)

	# Get all direct children that have collision
	obstacle_children = get_children().filter(
		func(child): return child is CollisionObject2D
	)
	
	# Initialize collision layers and swap states
	for obstacle in obstacle_children:
		Utils.set_collision_layer(obstacle, 3, true)
		obstacle_swap_states[obstacle] = false
		obstacle_swap_groups[obstacle] = false

		if not is_in_group("obstacles"):
			obstacle.add_to_group("obstacles")

		obstacle.z_index = -4

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	for obstacle in obstacle_children:
		if player.is_jumping:
			if not obstacle_swap_states[obstacle]:  # Only swap if not already swapped for this obstacle
				Utils.set_collision_layer(obstacle, 3, false)
				Utils.set_collision_layer(obstacle, 6, true)
				obstacle_swap_states[obstacle] = true
				timer.start()

				# if not obstacle.is_in_group("Non_destructables"):
				# 	obstacle.add_to_group("Non_destructables")
		else:
			obstacle_swap_states[obstacle] = false  # Reset swap state when not jumping
			# obstacle.remove_from_group("Non_destructables")


	# Handle crouch state changes
	for obstacle in obstacle_children:
		if player.crouched:
			if not obstacle_swap_groups[obstacle]:
				obstacle.add_to_group("Non_destructables")
		else:
			obstacle_swap_groups[obstacle] = false
			obstacle.remove_from_group("Non_destructables") 


	

func _on_timer_timeout() -> void:
	for obstacle in obstacle_children:
		Utils.set_collision_layer(obstacle, 6, false)
		Utils.set_collision_layer(obstacle, 3, true)
