class_name Bomber_bot
extends CharacterBody2D

var speed: float = 120.0
var explosion_radius: float = 100.0
var explosion_damage: int = 20
var is_exploding = false
var has_exploded = false

@onready var player: Node2D = get_node("/root/Level/Player")
@onready var explosion_area = $explosion_Area2D

@onready var idle := $idle
@onready var walk := $walk
@onready var explosion := $explosion
@onready var shoot := $shoot

var bot_stats = {
	"health": 100,
	"speed": 0,
	"is_alive": true,
	"heat_up": 0.0
}

func _ready() -> void:
	
	if player == null:
		push_error("player not found")
	explosion_area.body_entered.connect(_on_explosion_body_entered)
	idle.show()
	walk.hide()
	explosion.hide()
	shoot.hide()

func _physics_process(_delta: float) -> void:
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
	if velocity.length() > 0.1:  # 0.1 = small threshold so tiny floating errors don’t count
		idle.hide()
		walk.show()
		# walk.sprite_frames.set_animation_("default", 24)
		walk.speed_scale = 1.5
		walk.play("default")
		
	else:
		idle.show()
		walk.hide()
	
	# Check if close enough to explode
	if global_position.distance_to(player.global_position) <= explosion_radius:
		explode()
		
func _on_explosion_body_entered(body: CharacterBody2D) -> void:
	if body == player: # only explode if it's the player
		explode()

		if player.has_method("hit"):
			player.hit(explosion_damage)

func hit(damage) -> void:
	damage = 10
	Utils.get_hit(bot_stats, damage)
	if bot_stats["health"] <= 0:
		explode()

func explode() -> void:
	if has_exploded:
		return
	is_exploding = true
	# Damage player (if it has a health variable or method)
	explosion.show()
	idle.hide()
	walk.hide()

	# Queue free after short delay
	explosion.sprite_frames.set_animation_loop("default", false)
	explosion.play("default")
	shoot.show()
	Audio_Player.play_sfx(self, "explosion", 5.0)
	await explosion.animation_finished

	explosion.hide()
	# explosion_area.body_entered.disconnect(_on_explosion_body_entered)
	explosion_area.queue_free()
	has_exploded = true

	# Disable collisions
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
			

	#Wait 6 more seconds before freeing
	await get_tree().create_timer(20.0).timeout
	queue_free()


