class_name Bullet
extends Area2D

var speed: int = 10000
var direction: Vector2 = Vector2.RIGHT  # Default direction (will be updated)
var damage := 2
var shooter: Node = null 

@onready var player: Node2D = get_node("/root/Level/Player")

func _ready():
	# Set the movement direction based on the laser's rotation
	direction = Vector2.RIGHT.rotated(rotation)
	$SelfDestructTimer.start()
	z_index = -1
	print("shooter:", shooter)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	# if body == shooter:
	# 	return
	if shooter is Player:
		if body.has_method("hit"):
			body.hit(damage)
			queue_free()
		elif body is Bomber_bot:
			if body.is_exploding or body.has_exploded:
				return  #don't trigger damage if bomber is exploding
			body.hit(damage)
			queue_free()
	else:
		if body is Player:
			player.hit(damage)
			queue_free()
		else:
			pass
			#or queue_free()  ---> if bullets are to be distroyed, wen enemy hits an enemy

	if body.is_in_group("Non_destructables"):
		Utils.Bullet_hole(global_position, get_tree().current_scene)
		Utils.spawn_particles(global_position, get_tree().current_scene, 0.25, 2.5)
		queue_free()

func _on_self_destruct_timer_timeout() -> void:
	queue_free()
