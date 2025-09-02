class_name Bullet
extends Area2D

var speed: int = 10000
var direction: Vector2 = Vector2.RIGHT  # Default direction (will be updated)
var damage: int
var shooter: Node = null 

@onready var player: Node2D = get_node("/root/Level/Player")

func _ready():
	# Set the movement direction based on the laser's rotation
	direction = Vector2.RIGHT.rotated(rotation)
	$SelfDestructTimer.start()
	z_index = -1
	# print("shooter:", shooter)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if shooter != null and is_instance_valid(shooter) and body == shooter:
		return

	if shooter != null and is_instance_valid(shooter) and shooter is Player:
		if body.has_method("hit") and !(body is Bomber_bot):
			body.hit(damage)
			Utils.Bullet_hole(global_position, body)
			queue_free()
		elif body is Bomber_bot and is_instance_valid(body):
			if body.is_exploding or body.has_exploded:
				return  #don't trigger damage if bomber is exploding
			body.hit(damage)
			# Utils.Bullet_hole(global_position, body)

			#Ensure we always hit the actual Bomber_bot, not its Area2D
			if body is Area2D:
				body = body.get_parent()
				Utils.Bullet_hole(global_position, body)
			queue_free()
	else:
		if is_instance_valid(body) and body is Player:
			player.hit(damage)
			queue_free()
		else:
			pass
			#or queue_free()  ---> if bullets are to be distroyed, wen enemy hits an enemy

	if is_instance_valid(body) and body.is_in_group("Non_destructables"):
		Utils.Bullet_hole(global_position, body as Node2D)
		Utils.spawn_particles(global_position, get_tree().current_scene, 0.25, 2.5)
		queue_free()

func _on_self_destruct_timer_timeout() -> void:
	queue_free()
