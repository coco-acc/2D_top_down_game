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

var is_delayed = false
@onready var delay_timer: Timer

@onready var player: Node2D = get_node("/root/Level/Player")
@onready var explosion_area = $explosion_Area2D

@onready var idle := $idle
@onready var walk := $walk
@onready var explosion := $explosion
@onready var shoot := $shoot
@onready var shadow := $Shadow

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
	
	if player == null:
		push_error("player not found")
	explosion_area.body_entered.connect(_on_explosion_body_entered)
	explosion_area.body_exited.connect(_on_explosion_body_exited)
	idle.show()
	walk.hide()
	explosion.hide()
	shoot.hide()

	# if idle.material:
	# 	idle.material = idle.material.duplicate(true)
	# 	idle.material.set("shader_parameter/Dissolve_value_",0.0)
	apply_dissolve(idle, 0.0)

	#spawn effect
	dissolve_effect(idle, 0.0, 1.0, 0.5)

	# Disable behavior for 20 seconds
	is_disabled = true
	# self.set_physics_process(false)
	await get_tree().create_timer(1.2).timeout
	# self.set_physics_process(true)
	is_disabled = false

func _physics_process(delta: float) -> void:
	# if is_disabled:
	# 	return
	# if not player is Player:
	# 	return
	# if is_exploding:
	# 	return
	
	# # Move towards the player
	# var direction: Vector2 = (player.global_position - global_position).normalized()

	# velocity = direction * speed
	# move_and_slide()

	# rotation = direction.angle()

	# # Detect movement
	# if velocity.length() > 0.1:  # 0.1 = small threshold so tiny floating errors don’t count
	# 	idle.hide()
	# 	walk.show()
	# 	# walk.sprite_frames.set_animation_("default", 24)
	# 	walk.speed_scale = 1.0
	# 	walk.play("default")
		
	# else:
	# 	idle.show()
	# 	walk.hide()
	if is_disabled or not (player is Player) or is_exploding:
		return

	var target_dir: Vector2 = (player.global_position - global_position).normalized()
	var target_angle: float = target_dir.angle()

	# if get_last_slide_collision():
	# 	var collision = get_last_slide_collision()
	# 	var collider = collision.get_collider()
	# 	if not collider == null:
	# 		# print("collider:", collider)
	# 		if collider is CharacterBody2D:
	# 			var target_dir_b = (player.global_position - collider.global_position).normalized()
	# 			if target_dir > target_dir_b:
	# 				velocity =  target_dir * speed
	# 			else:
	# 				velocity = Vector2.ZERO

	# Smoothly rotate toward player
	var angle_diff: float = wrapf(target_angle - rotation, -PI, PI)
	var rotate_speed: float = 5.0  # how fast it turns
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

	if velocity.length() > 0.1 or abs(angle_diff) > 0.05:
		# Either moving or turning → play walking animation
		idle.hide()
		walk.show()
		if not walk.is_playing():
			walk.speed_scale = 1.0
			walk.play("default")
	else:
		# Fully idle (not rotating or moving)
		idle.show()
		walk.hide()
		
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

func hit(damage) -> void:
	# Ignore hits if already exploding or exploded
	if is_exploding or has_exploded:
		return  

	damage = 10
	Utils.get_hit(bot_stats, damage)
	if bot_stats["health"] <= 0 and not has_exploded:
		explode()

func explode() -> void:
	if has_exploded:
		return
	is_exploding = true
	if explosion_area:
		explosion_area.queue_free()
		
	#play SFX
	Audio_Player.play_sfx(self, "explosion", 5.0, true, 0.0, "Explosion")
	# Damage player (if it has a health variable or method)

	# Remove collision from physics world (bullets can't hit anymore)
	set_collision_layer(0)
	set_collision_mask(0)

	explosion.show()
	shadow.hide()
	idle.hide()
	walk.hide()

	# Queue free after short delay
	# can_explode = false
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
