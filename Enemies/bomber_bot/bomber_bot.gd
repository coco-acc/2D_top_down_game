class_name Bomber_bot
extends CharacterBody2D

var speed: float = 120.0
var impact_radius: float = 500.0
var explosion_damage: int = 20
var explosion_delay = 0.5
var is_exploding = false
var has_exploded = false
var can_explode = true
var is_disabled = false

#obstacle avoidance
var last_position = global_position
var stuck_check_timer = 0.0
var stuck_check_interval = 0.5
var is_stuck = false
var STUCK_TIME_THRESHOLD := 2.0
var stuck_index = 0
var stuck_timer = 0.0

var is_delayed = false
@onready var delay_timer: Timer

@onready var player: Node2D = get_node("/root/Level/Player")
@onready var explosion_area = $explosion_Area2D

@onready var idle := $idle
@onready var walk := $walk
@onready var explosion := $explosion
@onready var shoot := $shoot
@onready var shadow := $Shadow

@onready var forward = $Nav/forward
@onready var right_side = $Nav/right_side
@onready var left_side = $Nav/left_side
@onready var forward_left = $Nav/forward_left
@onready var forward_right = $Nav/forward_right
@onready var raycasts = $Nav
@onready var recalc_timer = Timer.new()
@onready var NavAget = $NavigationAgent2D
var bot_stats = {
	"health": 100,
	"speed": 0,
	"heat_up": 0.0,
	"is_alive": true,
}

func _ready() -> void:
	#Delay timer 
	delay_timer = Timer.new()
	delay_timer.wait_time = explosion_delay
	delay_timer.one_shot = true
	add_child(delay_timer)
	delay_timer.timeout.connect(_on_delay_timer_timeout)

	recalc_timer.wait_time = 0.1
	recalc_timer.autostart = true
	add_child(recalc_timer)
	recalc_timer.timeout.connect(_recalc_timer_timeout)

	NavAget.path_desired_distance = 8.0
	NavAget.target_desired_distance = 4.0
	NavAget.avoidance_enabled = true
	NavAget.avoidance_layers = 1
	NavAget.avoidance_mask = 3	

	call_deferred("_setup")

	if player == null:
		push_error("player not found")
	explosion_area.body_entered.connect(_on_explosion_body_entered)
	explosion_area.body_exited.connect(_on_explosion_body_exited)
	idle.show()
	walk.hide()
	explosion.hide()
	shoot.hide()

	apply_dissolve(idle, 0.0)

	#spawn effect
	dissolve_effect(idle, 0.0, 1.0, 0.5)

	# Disable behavior for 1.2 seconds
	is_disabled = true
	await get_tree().create_timer(1.2).timeout
	is_disabled = false

func _physics_process(delta: float) -> void:
	if is_disabled or not (player is Player) or is_exploding:
		return

	# Stuck detection
	stuck_check_timer += delta
	if stuck_check_timer >= stuck_check_interval:
		stuck_check_timer = 0.0
		if global_position.distance_to(last_position) < 5.0:
			stuck_timer += stuck_check_interval
			if stuck_timer >= STUCK_TIME_THRESHOLD:
				is_stuck = true
		else:
			stuck_timer = 0.0
			is_stuck = false
		last_position = global_position
		# print("is stuck: ", is_stuck)

	var target_dir: Vector2 = Vector2.ZERO

	# get avoidance direction
	# var avoid_dir = detect_obstacle()
	# var avoid_dir = detect_obstacle(target_dir)

	if is_stuck and stuck_timer > STUCK_TIME_THRESHOLD * 2:
		target_dir = target_dir.rotated(randf_range(-PI/2, PI/2))
		stuck_timer = 0.0 

	# 1) If we have an avoidance direction → PRIORITY
	# if avoid_dir != Vector2.ZERO:
	# 	target_dir = avoid_dir

	# elif not NavAget.is_navigation_finished():
	# 	var target_pos = NavAget.get_next_path_position()
	# 	target_dir = global_position.direction_to(target_pos)
		
	if not NavAget.is_navigation_finished():
		var target_pos = NavAget.get_next_path_position()
		target_dir = global_position.direction_to(target_pos)

	# 3) If stuck for too long, try a random direction
	# elif is_stuck and stuck_timer > STUCK_TIME_THRESHOLD * 2:
	# 	target_dir = target_dir.rotated(randf_range(-PI/2, PI/2))
	# 	stuck_timer = 0.0

	# 4) fallback
	else:
		target_dir = (player.global_position - global_position).normalized()

	var target_angle: float = target_dir.angle()

	# Smoothly rotate toward player
	var angle_diff: float = wrapf(target_angle - rotation, -PI, PI)
	var rotate_speed: float = 2.0  # how fast it turns
	if abs(angle_diff) > 0.05:
		# Rotate but don't move forward yet
		rotation += sign(angle_diff) * rotate_speed * delta
		velocity = Vector2.ZERO
	else:
		# Aligned — move forward
		rotation = target_angle
	velocity = target_dir * speed

	var coll = move_and_collide(velocity * delta)
	if coll:
		velocity = Vector2.ZERO  # stop on impact

	# --- Animation logic ---
	if is_exploding:
		return

	if velocity.length() > 0.1:
		# Either moving or turning → play walking animation
		idle.hide()
		walk.show()
		if not walk.is_playing():
			walk.speed_scale = 1.0
			walk.play("default")
	elif velocity.length() < 0.1 and  abs(angle_diff) > 0.01:
		idle.hide()
		walk.show()
		if not walk.is_playing():
			walk.speed_scale = 1.0
			walk.play("default")
	else:
		# Fully idle (not rotating or moving)
		idle.show()
		walk.hide()

func detect_obstacle() -> Vector2:
	# Check all rays for collisions
	for ray in raycasts.get_children():
		if ray.is_colliding():
			var normal = ray.get_collision_normal()
			
			# Apply the quadrant multiplier to produce avoidance vector
			var perpendicular = Vector2(-normal.y, normal.x).normalized()
			return perpendicular
	return Vector2.ZERO

# func detect_obstacle(dir: Vector2) -> Vector2:
# 	forward.force_raycast_update()
# 	left.force_raycast_update()
# 	right.force_raycast_update()
	
# 	var avoidance = Vector2.ZERO
	
# 	# Check each ray and add avoidance force based on collisions
# 	if forward.is_colliding():
# 		var forward_dist = global_position.distance_to(forward.get_collision_point())
# 		var forward_strength = 1.0 - (forward_dist / forward.target_position.length())
# 		# Push away from forward obstacle (perpendicular)
# 		avoidance += Vector2(-dir.y, dir.x) * forward_strength * ray_weights.forward
	
# 	if left.is_colliding():
# 		var left_dist = global_position.distance_to(left.get_collision_point())
# 		var left_strength = 1.0 - (left_dist / left.target_position.length())
# 		# Push away from left obstacle (to the right)
# 		avoidance += dir.rotated(PI/2) * left_strength * ray_weights.left
	
# 	if right.is_colliding():
# 		var right_dist = global_position.distance_to(right.get_collision_point())
# 		var right_strength = 1.0 - (right_dist / right.target_position.length())
# 		# Push away from right obstacle (to the left)
# 		avoidance += dir.rotated(-PI/2) * right_strength * ray_weights.right
	
# 	# If we have avoidance force, combine it with original direction
# 	if avoidance != Vector2.ZERO:
# 		# Normalize and blend with original direction
# 		avoidance = avoidance.normalized()
# 		# Return a blended direction (70% avoidance, 30% original direction)
# 		return (dir * 0.3 + avoidance * 0.7)
	
# 	return Vector2.ZERO

# func detect_obstacle(dir: Vector2) -> Vector2:
# 	forward.force_raycast_update()
# 	forward_left.force_raycast_update()
# 	forward_right.force_raycast_update()
# 	left_side.force_raycast_update()
# 	right_side.force_raycast_update()

# 	var normal: Vector2
# 	if forward.is_colliding() and forward.enabled:
# 		# print('print forward is colliding')
# 		forward_left.enabled = false
# 		forward_right.enabled = false
# 		if right_side.is_colliding():
# 			dir = (left_side.target_position - left_side.global_position).normalized()
# 			return dir
# 		elif left_side.is_colliding():
# 			dir = (right_side.target_position - right_side.global_position).normalized()
# 			return dir
# 		else:
# 			normal = forward.get_collision_normal()
# 			var collider = forward.get_collider()
# 			var collider_center: Vector2 = Vector2.ZERO

# 			if collider is CollisionShape2D:
# 				collider_center = collider.global_position
# 			elif collider is PhysicsBody2D:
# 				collider_center = collider.global_position

# 			var collision_point = forward.get_collision_point()
# 			var normal_plus_90 = normal.rotated(deg_to_rad(90))
# 			var normal_minus_90 = normal.rotated(deg_to_rad(-90))

# 			var to_center = collider_center - collision_point

# 			# Project onto rotated normals
# 			var dist_plus_90 = to_center.dot(normal_plus_90)
# 			var dist_minus_90 = to_center.dot(normal_minus_90)

# 			if dist_plus_90 > dist_minus_90:
# 				print("+90 side is farther: ", dist_plus_90)
# 				dir = normal_plus_90
# 			elif dist_minus_90 == dist_minus_90:
# 				if randf() < 0.5:
# 					dir = normal_minus_90	
# 				else:
# 					dir = normal_minus_90
# 			else:
# 				print("-90 side is farther: ", dist_minus_90)
# 				dir = normal_minus_90
# 			return dir
# 	else:
# 		forward_left.enabled = true
# 		forward_right.enabled = true

# 	if forward_left.is_colliding() and forward_left.enabled:
# 		forward.enabled = false
# 		forward_right.enabled = false
# 		# print('print forward_left is colliding')
# 		normal = forward_left.get_collision_normal() 
# 		dir = Vector2(normal.y, -normal.x)
# 		return dir
# 	else:
# 		forward.enabled = true
# 		forward_right.enabled = true

# 	if forward_right.is_colliding() and forward_right.enabled:
# 		forward.enabled = false
# 		forward_left.enabled = false
# 		# print('print forward_right is colliding')
# 		normal = forward_right.get_collision_normal()
# 		dir = Vector2(-normal.y, normal.x)
# 		return dir
# 	else:
# 		forward.enabled = true
# 		forward_left.enabled = true

# 	return Vector2.ZERO

func _setup() -> void:
	await get_tree().physics_frame
	set_target_position(player.global_position)

func set_target_position(pos: Vector2) -> void:
	NavAget.target_position = pos
		
func _on_explosion_body_entered(body: Node2D) -> void:
	if body == player and body is CharacterBody2D:
		delay_timer.start()  # Start the countdown


func _on_explosion_body_exited(body: Node2D) -> void:
	if body == player and body is CharacterBody2D:
		delay_timer.stop()
		is_delayed = false

func _on_delay_timer_timeout() -> void:
	is_delayed = true
	# Check if the player is still in the area before exploding
	for body in explosion_area.get_overlapping_bodies():
		if body == player and body is CharacterBody2D:
			explode()
			if body.has_method("hit"):
				body.hit(explosion_damage)
			break

func _recalc_timer_timeout() -> void:
	set_target_position(player.global_position)

func hit(damage) -> void:
	# Ignore hits if already exploding or exploded
	if is_exploding or has_exploded:
		return  

	damage = 10
	Utils.get_hit(bot_stats, damage)
	if bot_stats["health"] <= 0 and not has_exploded:
		Utils.spawn_item(global_position, get_tree().current_scene)
		explode()

func explode() -> void:
	if has_exploded:
		return
	is_exploding = true
	if explosion_area:
		explosion_area.queue_free()
		
	
	Audio_Player.play_sfx(self, "explosion", 5.0, true, 0.0, "Explosion")
	
	# Remove collision from physics world (bullets can't hit anymore)
	set_collision_layer(0)
	set_collision_mask(0)

	explosion.show()
	shadow.hide()
	idle.hide()
	walk.hide()

	# Queue free after short delay
	explosion.sprite_frames.set_animation_loop("default", false)
	explosion.play("default")
	shoot.show()
	
	await explosion.animation_finished
	explosion.hide()
	has_exploded = true

	# Disable collisions
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
			

	#Wait for more seconds before freeing
	await get_tree().create_timer(20.0).timeout
	Utils.dissolve_effect(self, shoot, 0.5)
	await get_tree().create_timer(1.0).timeout
	queue_free()

func dissolve_effect(sprite: Sprite2D, start: float, end: float, time: float) -> void:
	if sprite.material == null:
		push_warning("%s has no material; skipping dissolve effect." % sprite.name)
		return
	var tween = create_tween()
	tween.tween_method(func(value):
		sprite.material.set("shader_parameter/Dissolve_value_", value), start, end, time)


func apply_dissolve(sprite: Sprite2D, value: float):
	if sprite.material:
		sprite.material = sprite.material.duplicate(true)
		sprite.material.set("shader_parameter/Dissolve_value_", value)
