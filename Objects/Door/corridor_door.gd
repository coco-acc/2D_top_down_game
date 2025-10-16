extends Node2D

@onready var door_frame = $door_frame
@onready var door = $door_way
@onready var door_way: Area2D = $door_way/Area2D
@onready var Position_A: Marker2D = $door_way/A
@onready var Position_B: Marker2D = $door_way/B
@onready var sprite_A: AnimatedSprite2D = $A
@onready var sprite_B: AnimatedSprite2D = $B
@onready var light_A: AnimatedSprite2D = $Light_A
@onready var light_B: AnimatedSprite2D = $Light_B
@onready var player: Node2D = get_node("/root/Level/Player")
@onready var overlay: ColorRect = player.get_node("OverLay")

# var enterance_input = false
var at_door = false
var open_animation : AnimatedSprite2D
var close_animation : AnimatedSprite2D

func _ready() -> void:
	door_frame.add_to_group("Non_destructables")
	door.add_to_group("Non_destructables")
	door_way.body_entered.connect(_on_body_entered)
	door_way.body_exited.connect(_on_body_exited)
	overlay.modulate = Color(1,1,1,0)
	overlay.show()
	overlay.y_sort_enabled = true
	overlay.z_index = 6

	# Connect animation_finished ONCE for each sprite (avoid duplicate connections) 
	if sprite_A and not sprite_A.is_connected("animation_finished", _on_sprite_A_finished): sprite_A.animation_finished.connect(_on_sprite_A_finished) 
	if sprite_B and not sprite_B.is_connected("animation_finished", _on_sprite_B_finished): sprite_B.animation_finished.connect(_on_sprite_B_finished)

func _process(_delta) -> void:
	if at_door and  Input.is_action_just_pressed("Secondary_action"):
		# enterance_input = true
		move_in(player)
		

func move_in(body: Node2D) -> void:
	if body.has_method("set_movement_enabled"):
		body.set_movement_enabled(false)

	# Calculate distances to A and B
	var dist_to_A = body.global_position.distance_to(Position_A.global_position)
	var dist_to_B = body.global_position.distance_to(Position_B.global_position)

	# Pick the farther marker as the target
	var target_pos: Vector2
	var A: AnimatedSprite2D
	if dist_to_A < dist_to_B:
		target_pos = Position_B.global_position
		open_animation = sprite_A
		close_animation = sprite_B
		A = light_A
	else:
		target_pos = Position_A.global_position
		open_animation = sprite_B
		close_animation = sprite_A
		A = light_B
	close_animation.set_frame_and_progress(39, 0.0)

	# Special fade sequence if it's the player
	if body == player:
		# if enterance_input:
		open_animation.sprite_frames.set_animation_loop("default", false)
		open_animation.play("default", 1.0)
		A.play("default")
		Audio_Player.play_sfx(self, "door")

		if overlay:
			overlay.modulate.a = 0.0
			var fade_tween = get_tree().create_tween()

			# Fade in (darken screen)
			fade_tween.tween_property(overlay, "modulate:a", 1.0, 2.0)

			# After fade-in → move player
			fade_tween.finished.connect(func():
				var move_tween = get_tree().create_tween()
				move_tween.tween_property(body, "global_position", target_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

				move_tween.finished.connect(func():
					# Fade back out
					var fade_back = get_tree().create_tween()
					fade_back.tween_property(overlay, "modulate:a", 0.0, 2.0)

					close_animation.sprite_frames.set_animation_loop("default", false)
					close_animation.frame = 39
					close_animation.play("default", -1.0)
					Audio_Player.play_sfx(self, "door",false,2.0,0.0,"SFX")

					# Re-enable movement when done
					fade_back.finished.connect(func():
						if body.has_method("set_movement_enabled"):
							body.set_movement_enabled(true)
						# enterance_input = false
						# close_animation.sprite_frames.set_animation_loop("default", false)
						# close_animation.frame = 39
						# close_animation.play("default", -1.0)
					)
				)
			)
		else:
			# Enemies or other characters just move normally
			var tween = get_tree().create_tween()
			tween.tween_property(body, "global_position", target_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.finished.connect(func():
				if body.has_method("set_movement_enabled"):
					body.set_movement_enabled(true)
			)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		at_door = true
	# print("Entering doorway: ", body.name)

	
func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		# print("Exiting doorway: ", body.name)
		at_door = false

func _on_sprite_A_finished() -> void:
# Reset sprite_A to frame 0 after it finishes
	if is_instance_valid(sprite_A):
		await get_tree().create_timer(2.5).timeout
		sprite_A.stop()
		sprite_A.frame = 0 
		light_A.stop()
		light_B.stop()

func _on_sprite_B_finished() -> void:
# Reset sprite_B to frame 0 after it finishes
	if is_instance_valid(sprite_B):
		await get_tree().create_timer(2.5).timeout
		sprite_B.stop()
		sprite_B.frame = 0
		light_A.stop()
		light_B.stop() 


#// ---------------->for future reference>------------------------//
		# var movement_enabled: bool = true

		# func set_movement_enabled(enabled: bool) -> void:
		# 	movement_enabled = enabled

		# func _physics_process(delta: float) -> void:
		# 	if not movement_enabled:
		# 		velocity = Vector2.ZERO
		# 		move_and_slide()
		# 		return

		# 	# Normal movement code here
