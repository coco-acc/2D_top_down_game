class_name Player
extends CharacterBody2D

# Movement properties
var speed = 400
var jump_velocity = 1000
var is_jumping := false
var is_crouching := false
var can_crouch := false
var crouched := false
var hold := false

# Combat properties
var shoot: bool = true
var attack: bool = true

# Camera properties
@onready var camera := $Camera2D
@export var camera_offset_distance: int = 100
var direction_to = Vector2()
var aspect_ratio: float = 16.0 / 9.0

# State machine
enum State { IDLE, JUMP, CROUCH, MOVE, ATTACK, RELOAD, MELE_ATTACK, DIA }
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

#stats
var stats = {
	"health": 100,
	"speed": speed,
	"is_alive": true,
	"ammo": 30,
	"reload": 5.0
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

@onready var reload_timer = Timer.new()
# @onready var sfx = AudioStreamPlayer2D.new()

@onready var bullet = preload("res://Globals/bullets/Bullet_1.tscn")
@onready var HUD_scene = preload("res://Objects/HUD/hud.tscn")
var HUD = null

func _ready():
	#camera setup
	camera.make_current()  # Force this camera to be active
	camera.rotation_smoothing_enabled = true  # Smoother camera follow
	camera.rotation_smoothing_speed = 5.0  # Adjust smoothness (higher = faster follow)

	# Connect signals
	jump_timer.wait_time = 0.05
	jump_timer.one_shot = true
	reload_timer.wait_time = stats["reload"]
	reload_timer.one_shot = true
	node.add_child(reload_timer)
	# node.add_child(sfx)

	HUD = HUD_scene.instantiate()
	node.add_child(HUD)
	HUD.set_ammo(stats["ammo"])
	HUD.set_health(stats["health"])

func _physics_process(delta: float):
	# if not player_stats["is_alive"]:
	# 	return
	 # Handle crouch detection
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	if get_last_slide_collision() and  direction.length() < 0.1:
		var collision = get_last_slide_collision()
		# print("Collided with:", collision.get_collider().name)
		var collider = collision.get_collider()
		if not collider == null:
			if collider.is_in_group("obstacles") and !is_crouching:
				can_crouch = true
				is_crouching = true
			elif !collider.is_in_group("obstacles"):
				can_crouch = false
				is_crouching = false
		else:
			pass
	else:
		can_crouch = false
		is_crouching = false

	if Input.is_action_pressed("Mouse_shoot"):
		 # Get mouse position in world coordinates
		var mouse_pos = get_global_mouse_position()
	
		# Calculate direction from player to mouse
		direction = (mouse_pos - global_position)
	
		# Calculate angle in radians and convert to degrees + 90 degrees
		var angle = direction.angle() + PI/2
	
		# Apply rotation to the player
		rotation = angle


	handle_state(delta)
	move_and_slide()

func handle_state(delta: float):
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	# if Input.is_action_pressed("Left") or Input.is_action_pressed("Right")\
	# or Input.is_action_pressed("Up") or Input.is_action_pressed("Down"):
	# 	Audio_Player.play_sfx(self, "step", true)
	
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
		State.RELOAD:
			reload_state()
	
	# Handle camera rotation
	if direction.length() > 0:
		rotation = lerp_angle(rotation, direction.angle() + PI/2, 10 * delta)
	
	var facing_direction = Vector2(cos(rotation - PI/2), sin(rotation - PI/2))
	direction_to = facing_direction
	var target_offset = facing_direction * camera_offset_distance
	camera.offset = camera.offset.lerp(target_offset, 2.0 * delta)

	# if current_state != State.ATTACK:
		# Audio_Player.stop_sfx("MG2")
	  

func idle_state(direction: Vector2):
	if direction.length() > 0.1 and current_state != State.ATTACK:
		change_state(State.MOVE)
	elif Input.is_action_just_pressed("Secondary_action") and direction:
		change_state(State.JUMP)
	elif (Input.is_action_just_pressed("Primary_action") or Input.is_action_just_pressed("Mouse_shoot")) and shoot:
		change_state(State.ATTACK)
	elif can_crouch:
		change_state(State.CROUCH)

func move_state(direction: Vector2, delta: float):
	var animation = $move2/legs
	var img1 = $move2/base
	var img2 = $move2/base2
	var base: Sprite2D
	# Utils.sfx(node, "step")
	# Audio_Player.play_sfx(self, "step", true)

	if hold:
		img1.hide()
		img2.show()
		base = img2
	else:
		img2.hide()
		img1.show()
		base = img1

	var angle = 3

	var switch_time = 0.5  # Time in seconds between switches (adjust for faster/slower)

	if Input.is_action_pressed("walk") and direction:
		speed = 350
		switch_time = 0.2
		animation.sprite_frames.set_animation_speed("default", 24)
	else:
		speed = 450
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
	elif (Input.is_action_just_pressed("Primary_action") or Input.is_action_just_pressed("Mouse_shoot")) and shoot:
		change_state(State.ATTACK)
	elif can_crouch:
		change_state(State.CROUCH)

	velocity = direction * speed

func jump_state(direction: Vector2):
	if not is_jumping:
		jump_timer.start()
		velocity = jump_velocity * direction
		is_jumping = true
		camera.zoom = Vector2(0.52, 0.52)
	else:
		velocity = jump_velocity * direction

func crouch_state(direction):
	crouched = true
	if not can_crouch:
		crouched = false
		# change_state(previous_state) #---> possible bug
		change_state(State.IDLE)
	elif (Input.is_action_just_pressed("Primary_action") or Input.is_action_just_pressed("Mouse_shoot")) and shoot:
		crouched = false
		change_state(State.ATTACK)
	elif Input.is_action_just_pressed("Secondary_action") and direction:
		crouched = false
		change_state(State.JUMP)

func attack_state(direction):
	if stats["ammo"] < 1:
		change_state(State.RELOAD)
	elif shoot and not stats["ammo"] < 1:
		var bullet_position = $BulletPosition
		var bullet_instance = bullet.instantiate()
		bullet_instance.global_position = bullet_position.global_position
		bullet_instance.rotation = (rotation - deg_to_rad(90))
		bullet_instance.shooter = self
		bullet_instance.damage = 10
		get_tree().current_scene.add_child(bullet_instance)
		Utils.recoil(attac, -6)
		# Utils.spawn_particles($particlepos.global_position, get_tree().current_scene, 0.8, 2.5)
		Utils.bullet_cartridge($cartridgepos.global_position, get_tree().current_scene, rotation)
		# Utils.sfx(node, "MG2", 0.555)

		# sfx.stream = Utils.sfx_audio["MG2"]
		# sfx.stream.loop = true
		# if not sfx.playing:
		# 	sfx.play()
		Audio_Player.play_sfx(self, "MG2", 0.1, false, 0.0, "SFX")
		# Audio_Player.play_sfx(self, "explosion", 0.5, false, 0.0, "SFX")

		shoot = false
		stats["ammo"] -= 1
		HUD.set_ammo(stats["ammo"])
		shoot_delay.start()

	if Input.is_action_just_released("Primary_action") or Input.is_action_just_released("Mouse_shoot"):
		# sfx.stop()
		Audio_Player.stop_sfx("MG2")
		if previous_state:
			change_state(previous_state)
		else:
			change_state(State.IDLE)

	elif Input.is_action_just_pressed("Secondary_action") and direction:
		change_state(State.JUMP)
		Audio_Player.stop_sfx("MG2")

func reload_state():
	reload_timer.start()
	# sfx.stop()
	Audio_Player.stop_sfx("MG2")

	# Disconnect first to avoid duplicate connections
	if reload_timer.is_connected("timeout", Callable(self, "reload_mag")):
		pass
	else:
		reload_timer.connect("timeout", Callable(self, "reload_mag"))
	change_state(State.IDLE)

func reload_mag():
	stats["ammo"] = 30
	HUD.set_ammo(stats["ammo"])
	change_state(State.IDLE)

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

func hit(damage):
	# Utils.get_hit(stats)
	if stats["is_alive"]:
		stats["health"] -= damage

		if stats["health"] <= 0:
			stats["health"] = 0
			stats["is_alive"] = false
	HUD.set_health(stats["health"])
	if stats["health"] <= 0:
		print("Player is dead.")

func _on_shoot_delay_timeout() -> void:
	shoot = true

func _on_secondary_delay_timeout() -> void:
	attack = true

func _on_jump_timer_timeout() -> void:
	is_jumping = false  # Reset jumping flag when timer ends
	camera.zoom = Vector2(0.5, 0.5)
	change_state(State.IDLE)

func _on_gun_collider_body_entered(body: Node2D) -> void:
	if body.is_in_group("Non_destructables"):
		hold = true

func _on_gun_collider_body_exited(body: Node2D) -> void:
	if body.is_in_group("Non_destructables"):
		hold = false
