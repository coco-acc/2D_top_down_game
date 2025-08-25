class_name Turret
extends CharacterBody2D

# Turret settings
var rotation_speed: float = 10.0  # How fast the turret rotates (radians/sec)
var fire_rate: float = 10.83       # Shots per second during active phase
var bullet_scene = preload("res://Globals/bullets/Bullet_1.tscn")   # Preload your bullet scene here

# Firing cycle variables
var fire_duration: float = 0.0  # Seconds of continuous firing
var cooldown_duration: float = 0.0  # Seconds of cooldown
var is_in_cooldown: bool = false
var cycle_timer: Timer

var rotate_clockwise := randi() % 2 == 0  # Random initial direction
var idle_rotation_speed := deg_to_rad(20)  # 20 degrees/sec

# Internal variables
var target: Node2D = null               # Current target (player)
var can_shoot: bool = true              # Cooldown flag for individual shots
var attack_angle: float = 0.0           # Angle to face toward target
var direction := Vector2.RIGHT

var turret_stats = {
	"health": 100,
	"speed": 0,
	"is_alive": true,
	"ammo": 124,
	"heat_up": 0.0
}

var level = Utils.Levels()
var current_level: float

#states
enum TurretState { FIRING, COOLDOWN }
var state: TurretState = TurretState.FIRING

@onready var gun_sprite := $GunSprite  # Assuming you have a sprite for the gun
@onready var attack_zone := $AttackZone  # Detection area
@onready var shoot_timer := $ShootTimer   # Timer for firing rate
@onready var bulletPos := $GunSprite/BulletPos
@onready var cartridge := $GunSprite/cartridge
@onready var muzzle := $GunSprite/glow

func _ready():
	current_level = level["1"]

	# Configure the shoot timer
	shoot_timer.wait_time = 1.0 / fire_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Create and configure cycle timer
	cycle_timer = Timer.new()
	add_child(cycle_timer)
	cycle_timer.timeout.connect(_on_cycle_timer_timeout)
	start_firing_phase()
	
	# Connect attack zone signals
	attack_zone.body_entered.connect(_on_attack_zone_body_entered)
	attack_zone.body_exited.connect(_on_attack_zone_body_exited)

func _physics_process(delta):
	match state:
		TurretState.FIRING:
			if target:
				direction = (target.global_position - global_position).normalized()
				attack_angle = direction.angle() + deg_to_rad(90)
				gun_sprite.rotation = lerp_angle(gun_sprite.rotation, attack_angle, rotation_speed * delta)
			
				# if can_shoot and abs(gun_sprite.rotation - attack_angle) < 0.2:
					# shoot()
				if can_shoot:
					shoot()
					Utils.recoil(gun_sprite, -8, shoot_timer.wait_time)
					Utils.bullet_cartridge(cartridge.global_position, get_tree()\
					.current_scene, gun_sprite.rotation)
					#Utils.sfx(self, "MG1", 0.3)
					turret_stats["ammo"] -= 1
					if turret_stats["heat_up"] < 10:
						turret_stats["heat_up"] += 0.01
					# print("heat: ", turret_stats["heat_up"])
					Audio_Player.play_sfx(self, "MG2", true)
			else:
				start_cooldown_phase()
				Audio_Player.stop_sfx("MG2")
		TurretState.COOLDOWN:
			var rotation_change = idle_rotation_speed * delta
			if rotate_clockwise:
				gun_sprite.rotation += rotation_change
			else:
				gun_sprite.rotation -= rotation_change
			if turret_stats["heat_up"] > 0:
				turret_stats["heat_up"] -= 0.0025
	# if turret_stats["ammo"] < 0:
	# 	start_cooldown_phase()
	muzzle.material.set("shader_parameter/emission_strength", turret_stats["heat_up"])

func shoot():
	if not bullet_scene:
		push_warning("No bullet scene assigned to turret!")
		return
	
	can_shoot = false
	shoot_timer.start()
	
	# Create and fire bullet
	var bullet = bullet_scene.instantiate()
	bullet.z_index = -1
	get_tree().current_scene.add_child(bullet)

	# Utils.recoil(gun_sprite, -8)
	
	# Set bullet position and direction
	bullet.global_position = bulletPos.global_position
	bullet.rotation = gun_sprite.rotation - deg_to_rad(90)
	bullet.direction = direction

func hit(damage):
	damage = 10
	Utils.get_hit(turret_stats, damage)
	if not turret_stats["is_alive"]:
		print('Turret is distroyed')
		queue_free()

func start_firing_phase():
	state = TurretState.FIRING
	can_shoot = true
	fire_duration = randf_range(8.0, 15.0) * current_level  # default range, will change for difficulty later
	shoot_timer.start()
	cycle_timer.start(fire_duration)

func start_cooldown_phase():
	state = TurretState.COOLDOWN
	cooldown_duration = randf_range(5.0, 12.0)  # default range, will change for difficulty later
	cycle_timer.start(cooldown_duration)

func _on_shoot_timer_timeout():
	can_shoot = true

func _on_cycle_timer_timeout():
	if state == TurretState.COOLDOWN:
		start_firing_phase()
	else:
		start_cooldown_phase()

func _on_attack_zone_body_entered(body):
	if  body is Player:
		target = body

func _on_attack_zone_body_exited(body):
	if body == target:
		target = null
