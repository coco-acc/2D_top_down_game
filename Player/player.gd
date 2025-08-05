extends CharacterBody2D
class_name Player

# Movement properties
var speed = 400
var jump_velocity = 1000
var is_jumping := false
var is_crouching := false
var can_crouch := false
var crouched := false
# var can_Jump := false

# Combat properties
var shoot: bool = true
var attack: bool = true
# signal shoot_bullet(pos)
# signal secondary_attack(pos)

# Camera properties
@onready var camera := $Camera2D
@export var camera_offset_distance: int = 100
var direction_to = Vector2()
var aspect_ratio: float = 16.0 / 9.0

# State machine
enum State { IDLE, JUMP, CROUCH, MOVE, ATTACK, MELE_ATTACK, DIA }
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

#stats
var stats = {
	"health": 100,
	"speed": speed,
	"is_alive": true,
	"ammo": 124
}

# @onready var jump_delay := $jumpDelay
@onready var jump_timer := $jumpTimer
@onready var shoot_delay := $shootDelay
@onready var secondary_delay := $secondaryDelay
@onready var idle := $idle
@onready var jump := $jump
@onready var attac := $attack
@onready var crouch := $crouch
@onready var move := $move2
@onready var node := $"."

@onready var bullet = preload("res://Globals/bullets/Bullet_1.tscn")

func _ready():
	#camera setup
	camera.make_current()  # Force this camera to be active
	camera.rotation_smoothing_enabled = true  # Smoother camera follow
	camera.rotation_smoothing_speed = 5.0  # Adjust smoothness (higher = faster follow)

	# Connect signals
	# $jumpDelay.timeout.connect(_on_jump_delay_timeout)
	jump_timer.wait_time = 0.05

func _physics_process(delta: float):
	# if not player_stats["is_alive"]:
	# 	return
	 # Handle crouch detection
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	if get_last_slide_collision() and  direction.length() < 0.1:
		var collision = get_last_slide_collision()
		# print("Collided with:", collision.get_collider().name)
		var collider = collision.get_collider()
		
		if collider.is_in_group("obstacles") and !is_crouching:
			can_crouch = true
			is_crouching = true
		elif !collider.is_in_group("obstacles"):
			can_crouch = false
			is_crouching = false
	else:
		can_crouch = false
		is_crouching = false


	handle_state(delta)
	move_and_slide()

func handle_state(delta: float):
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	
	match current_state:
		State.IDLE:
			idle_state(direction)
			idle.show()
			jump.hide()
			attac.hide()
			move.hide()
			crouch.hide()
		State.MOVE:
			move_state(direction, delta)
			idle.hide()
			jump.hide()
			attac.hide()
			move.show()
			crouch.hide()
		State.JUMP:
			jump_state(direction)
			idle.hide()
			jump.show()
			attac.hide()
			move.hide()
			crouch.hide()
		State.CROUCH:
			crouch_state(direction)
			idle.hide()
			jump.hide()
			attac.hide()
			move.hide()
			crouch.show()
		State.ATTACK:
			attack_state(direction)
			idle.hide()
			jump.hide()
			attac.show()
			move.hide()
			crouch.hide()
		State.MELE_ATTACK:
			mele_attack_state()
		State.DIA:
			dia_state()
	
	# Handle camera rotation
	if direction.length() > 0:
		rotation = lerp_angle(rotation, direction.angle() + PI/2, 10 * delta)
	
	var facing_direction = Vector2(cos(rotation - PI/2), sin(rotation - PI/2))
	direction_to = facing_direction
	var target_offset = facing_direction * camera_offset_distance
	camera.offset = camera.offset.lerp(target_offset, 2.0 * delta)
	  

func idle_state(direction: Vector2):
	if direction.length() > 0.1 and current_state != State.ATTACK:
		change_state(State.MOVE)
	elif Input.is_action_just_pressed("Secondary_action") and direction:
		change_state(State.JUMP)
	elif Input.is_action_just_pressed("Primary_action") and shoot:
		change_state(State.ATTACK)
	elif can_crouch:
		change_state(State.CROUCH)

func move_state(direction: Vector2, delta: float):
	var animation = $move2/legs
	var base = $move2/base
	var angle = 3

	var switch_time = 0.5  # Time in seconds between switches (adjust for faster/slower)

	if Input.is_action_pressed("run") and direction:
		speed = 650
		switch_time = 0.2
		animation.sprite_frames.set_animation_speed("default", 24)
	else:
		speed = 350
		switch_time = 0.5
		animation.sprite_frames.set_animation_speed("default", 12)
		angle = 1
	animation.play()
	# Continuous rotation effect while moving
	if direction.length() > 0.1:
		 # Switch between angles based on time
		var target_angle = -angle if fmod(Time.get_ticks_msec() * 0.001, switch_time * 2) < switch_time else angle
		
		# Snap most of the way quickly, leaving just a little smoothing
		base.rotation_degrees = move_toward(base.rotation_degrees, target_angle, 500 * delta)
	else:
		# Reset rotation when not moving
		base.rotation_degrees = move_toward(base.rotation_degrees, 0, 500 * delta)
		change_state(State.IDLE)
	if Input.is_action_just_pressed("Secondary_action") and direction:
		change_state(State.JUMP)
	elif Input.is_action_just_pressed("Primary_action") and shoot:
		change_state(State.ATTACK)
	elif can_crouch:
		change_state(State.CROUCH)

	velocity = direction * speed

func jump_state(direction: Vector2):
	if not is_jumping:
		jump_timer.start()
		velocity = jump_velocity * direction
		is_jumping = true
		# can_Jump = false
		# secondary_delay.start()
	else:
		velocity = jump_velocity * direction

func crouch_state(direction):
	crouched = true
	if not can_crouch:
		crouched = false
		# change_state(previous_state) #---> possible bug
		change_state(State.IDLE)
	elif Input.is_action_just_pressed("Primary_action") and shoot:
		crouched = false
		change_state(State.ATTACK)
	elif Input.is_action_just_pressed("Secondary_action") and direction:
		crouched = false
		change_state(State.JUMP)

func attack_state(direction):
	if shoot:
		var bullet_position = $BulletPosition
		# shoot_bullet.emit(bullet_position.global_position)
		var bullet_instance = bullet.instantiate()
		bullet_instance.global_position = bullet_position.global_position
		bullet_instance.rotation = (rotation - deg_to_rad(90))
		get_tree().current_scene.add_child(bullet_instance)
		Utils.recoil(attac, -6)

		shoot = false
		shoot_delay.start()

	if Input.is_action_just_released("Primary_action"):
		if previous_state:
			change_state(previous_state)
		else:
			change_state(State.IDLE)
	elif Input.is_action_just_pressed("Secondary_action") and direction:
		change_state(State.JUMP)

func mele_attack_state():
	# Implement male attack logic here
	change_state(State.IDLE)

func dia_state():
	# Implement DIA state logic here
	change_state(State.IDLE)

func change_state(new_state):
	if new_state != current_state:
		previous_state = current_state
		current_state = new_state

func hit():
	Utils.get_hit(stats)
	if stats["health"] <= 0:
		print("Player is dead.")
		# You can trigger death animation, game over screen, etc. here

func _on_shoot_delay_timeout() -> void:
	shoot = true

func _on_secondary_delay_timeout() -> void:
	attack = true
	# print('jump timeout')
	# can_Jump = true

func _on_jump_timer_timeout() -> void:
	is_jumping = false  # Reset jumping flag when timer ends
	change_state(State.IDLE)

# func _on_jump_delay_timeout() -> void:
# 	can_Jump = true
# 	print('jump timeout')


func _on_gun_collider_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_gun_collider_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
