class_name Bomber_bot
extends CharacterBody2D

var speed: float = 120.0
var impact_radius: float = 500.0
var explosion_damage: int = 20
var is_exploding = false
var has_exploded = false
var can_explode = true
var is_disabled = false

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
	"is_alive": true
}

func _ready() -> void:
	
	if player == null:
		push_error("player not found")
	explosion_area.body_entered.connect(_on_explosion_body_entered)
	idle.show()
	walk.hide()
	explosion.hide()
	shoot.hide()

	if idle.material:
		idle.material = idle.material.duplicate(true)
		idle.material.set("shader_parameter/Dissolve_value_",0.0)

	#spawn effect
	spawn_effect()

	# Disable behavior for 20 seconds
	is_disabled = true
	# self.set_physics_process(false)
	await get_tree().create_timer(1.2).timeout
	# self.set_physics_process(true)
	is_disabled = false
	

func _physics_process(_delta: float) -> void:
	if is_disabled:
		return
	if not player is Player:
		return
	if is_exploding:
		return
	
	# Move towards the player
	var direction: Vector2 = (player.global_position - global_position).normalized()

	velocity = direction * speed
	move_and_slide()

	rotation = direction.angle()

	# Detect movement
	if velocity.length() > 0.2:  # 0.1 = small threshold so tiny floating errors don’t count
		idle.hide()
		walk.show()
		# walk.sprite_frames.set_animation_("default", 24)
		walk.speed_scale = 1.0
		walk.play("default")
		
	else:
		idle.show()
		walk.hide()
	
	# Check if close enough damage the player
	# if global_position.distance_to(player.global_position) <= impact_radius and is_exploding:
		
func _on_explosion_body_entered(body: Node) -> void:
	if body == player and body is CharacterBody2D:
		explode()
		if body.has_method("hit"):
			body.hit(explosion_damage)


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
	queue_free()

func spawn_effect() -> void:
	var tween = self.create_tween()
	tween.tween_method( func(value):
		idle.material.set("shader_parameter/Dissolve_value_", value), 0.0, 1.0, 0.5		
		)
