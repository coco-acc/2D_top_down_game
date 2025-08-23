extends Area2D

var speed: int = 10000
var direction: Vector2 = Vector2.RIGHT  # Default direction (will be updated)

func _ready():
	# Set the movement direction based on the laser's rotation
	direction = Vector2.RIGHT.rotated(rotation)
	$SelfDestructTimer.start()
	z_index = -1

func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit"):
		body.hit()

	if body.is_in_group("Non_destructables"):
		Utils.Bullet_hole(global_position, get_tree().current_scene)
		Utils.spawn_particles(global_position, get_tree().current_scene, 0.25, 2.5)

	if body.is_in_group("Non_destructables") or body is CharacterBody2D:
		queue_free()

func _on_self_destruct_timer_timeout() -> void:
	queue_free()
