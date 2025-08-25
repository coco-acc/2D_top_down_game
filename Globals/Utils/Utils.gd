extends Node
class_name Utils

## Swaps an object between two specified collision layers
static func swap_collision_layers(obj: CollisionObject2D, layer_a: int, layer_b: int) -> void:
	if !is_instance_valid(obj):
		push_warning("Utils: Invalid object provided")
		return
	
	# Convert layer numbers to bit positions (layer 1 = bit 0, layer 2 = bit 1, etc.)
	var bit_a = layer_a - 1
	var bit_b = layer_b - 1
	
	var current = obj.collision_layer
	var is_on_a = current & (1 << bit_a)
	var is_on_b = current & (1 << bit_b)
	
	if is_on_a:
		# Move from layer A → B
		obj.collision_layer = (current & ~(1 << bit_a)) | (1 << bit_b)
	elif is_on_b:
		# Move from layer B → A
		obj.collision_layer = (current & ~(1 << bit_b)) | (1 << bit_a)
	else:
		# Default to layer A if not on either
		obj.collision_layer |= (1 << bit_a)

## Sets specific collision layer state
static func set_collision_layer(obj: CollisionObject2D, layer: int, enabled: bool) -> void:
	if !is_instance_valid(obj):
		return
	
	var bit = layer - 1
	if enabled:
		obj.collision_layer |= (1 << bit)
	else:
		obj.collision_layer &= ~(1 << bit)

## Same functions for collision_mask (for detection)
static func swap_collision_masks(obj: CollisionObject2D, mask_a: int, mask_b: int) -> void:
	swap_collision_layers(obj, mask_a, mask_b)  # Reuses same logic

static func set_collision_mask(obj: CollisionObject2D, mask: int, enabled: bool) -> void:
	set_collision_layer(obj, mask, enabled)  # Reuses same logic

# # Swap between layer 3 and 5 (now dynamic!)
# Utils.swap_collision_layers($Player, 3, 5)

# # Enable/disable specific layers
# Utils.set_collision_layer($Enemy, 7, true)  # Enable layer 7
# Utils.set_collision_layer($Wall, 2, false)  # Disable layer 2

# # Works with collision masks too!
# Utils.swap_collision_masks($Sensor, 1, 8)


## Applies recoil to a 2D weapon sprite that stays with character
static func recoil(sprite: Node2D, recoil_distance: float, duration: float = 0.1) -> void:
	# Cache original position
	var orig_position := sprite.position

	# Calculate direction vector based on current rotation
	var recoil_offset := Vector2(randf_range(-0.5, 0.5), -1.0).rotated(sprite.rotation)\
	* recoil_distance
	# var recoil_offset := Vector2.UP.rotated(sprite.rotation) * recoil_distance

	# Instantly move back along the facing direction
	sprite.position += recoil_offset

	# Create tween to smoothly return to original posrandf_range(-0.3, 0.3),ition
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "position", orig_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	## How it works!
		#Utils.recoil(sprite, distance, time)
		# time is optional 
		# distance sld be negative for backward recoil 
		#shld be called when the bullet is fired

static func get_hit(stats: Dictionary, damage) -> Dictionary:
	if stats["is_alive"]:
		stats["health"] -= damage

		if stats["health"] <= 0:
			stats["health"] = 0
			stats["is_alive"] = false
			# You can emit a signal here if needed
			# SignalBus.player_died.emit()
	
	return stats

# static func hit_effect(sprite: Node2D, effect_size: float, duration: float = 0.1) -> void:
# 	var orig_position := sprite.position
# 	var offset := Vector2.UP.rotated(sprite.rotation) * effect_size

# 	sprite.position += offset
# 	var tween = sprite.create_tween()
# 	tween.tween_property(sprite, "position", orig_position, duration)\
# 		.set_trans(Tween.TRANS_SINE)\
# 		.set_ease(Tween.EASE_OUT)

static func Levels():
	var difficulty := {
	"1"= 1.0,
	"2"= 1.1,
	"3"= 1.2,
	"4"= 1.3,
	"5"= 1.4,
	"6"= 1.5,
	"7"= 1.6,
	"8"= 1.7,
	"9"= 1.8,
	"10"= 1.9
	}

	return difficulty

static func Bullet_hole(position: Vector2, scene_root: Node2D, scale: float = 0.6, lifetime: float = 20.0) -> void:
	var bullet_hole := Sprite2D.new()
	var rotation: float = randf_range(-90.0, 90.0)

	# Random texture selection
	var textures := [
		preload("res://Img_assests/overlays/bullet_holes/bullet_hole1.png"),
		preload("res://Img_assests/overlays/bullet_holes/bullet_hole2.png"),
		preload("res://Img_assests/overlays/bullet_holes/bullet_hole3.png"),
	]
	bullet_hole.texture = textures.pick_random()

	bullet_hole.global_position = position
	bullet_hole.modulate = Color(0.4, 0.4, 0.4, 0.6)
	bullet_hole.rotation = rotation
	bullet_hole.scale = Vector2(scale, scale) * randf_range(0.6, 1.4)
	bullet_hole.scale.y = bullet_hole.scale.y * 0.6 
	bullet_hole.z_index = 3

	scene_root.add_child(bullet_hole)

	# Timer for lifetime
	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.autostart = true
	timer.one_shot = true
	bullet_hole.add_child(timer)

	# Correct connection using Callable
	timer.timeout.connect(Callable(bullet_hole, "queue_free"))

static func spawn_particles(spawn_pos: Vector2, scene_root, lifetime = 0.25, speed_scale = 2.5):
	var particles := preload("res://Globals/Particles/Explosion_particles.tscn")
	var p = particles.instantiate()
	p.global_position = spawn_pos
	scene_root.add_child(p)
	var s = p.get_child(0)
	s.emitting = true
	s.lifetime = lifetime
	s.speed_scale = speed_scale
	# s.amount = amount

	# Queue free after particle lifetime
	var t := Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	t.connect("timeout", Callable(p, "queue_free"))
	p.add_child(t)
	t.start()
	
static func bullet_cartridge(position: Vector2, scene_root: Node2D, facing_rotation) -> void:
	var cartridge := Sprite2D.new()
	var sprite = [
		preload("res://Img_assests/overlays/cartridges/mg1.png"),
		preload("res://Img_assests/overlays/cartridges/9mm.png"),
		preload("res://Img_assests/overlays/cartridges/shotgun.png")
	]

	# Initial settings
	cartridge.global_position = position
	cartridge.texture = sprite[0] # Pick cartridge type
	cartridge.rotation_degrees = randf_range(0, 360) # Random start rotation
	cartridge.scale = Vector2(1,1) * 0.05
	cartridge.z_index = 1
	cartridge.modulate = Color(0.82, 0.82, 0.82)
	scene_root.add_child(cartridge)

	# Add tween for movement & rotation
	var tween = cartridge.create_tween()

	# Random ejection angle relative to player facing
	# This makes it eject slightly to the right/back of the player
	var eject_angle = facing_rotation + deg_to_rad(randf_range(-40, -20))
	var eject_dir = Vector2.RIGHT.rotated(eject_angle)
	var eject_distance = randf_range(40, 70)
	var target_pos = position + eject_dir * eject_distance

	# Move
	tween.tween_property(cartridge, "global_position", target_pos, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Spin
	var spin_amount = randf_range(720, 1440)
	tween.parallel().tween_property(cartridge, "rotation_degrees", cartridge.rotation_degrees + spin_amount, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# # Drop
	# tween.tween_property(cartridge, "position:y", cartridge.position.y + randf_range(-10, -25), 0.3)\
	# 	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# THEN drop **in world-space** (add a positive Y offset)
	# var drop_amount = randf_range(10, 25)
	# tween.tween_property(cartridge, "global_position", target_pos + Vector2(0, drop_amount), 0.3)\
	# 	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fade out
	tween.tween_interval(10.0)
	tween.tween_property(cartridge, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): cartridge.queue_free())

static var player: AudioStreamPlayer2D = null
static var time: Timer = null

# Preload sounds into a dictionary
# static var sfx_audio := {
# 		"step": preload("res://Audio_assests/sfx/Step_rock_02.wav"),
# 		"gunshot1": preload("res://Audio_assests/sfx/gunshot1.mp3"),
# 		"gunshot2": preload("res://Audio_assests/sfx/gunshot2.mp3"),
# 		"MG1" : preload("res://Audio_assests/sfx/machin-gun-mg34-double-sound.mp3"),
# 		"MG2" : preload("res://Audio_assests/sfx/mg1.wav")
# 	}

# static func sfx(scene_root: Node, file: String, duration: float = -1.0, continuous: bool = false, start: float = 0.0) -> void:
# 	# Create the player only once
# 	if player == null:
# 		player = AudioStreamPlayer2D.new()
# 		scene_root.add_child(player)

# 	# Create a timer only once
# 	if time == null:
# 		time = Timer.new()
# 		time.one_shot = true
# 		scene_root.add_child(time)

# 	# Validate
# 	if not sfx_audio.has(file):
# 		push_warning("Invalid SFX name: %s" % file)
# 		return

# 	# Play only if not already playing
# 	if continuous:
# 		if not player.playing:
# 			player.stream = sfx_audio[file]
# 			player.play(start)
# 	else:
# 		player.stream = sfx_audio[file]
# 		player.play(start)

# 	# If duration > 0, stop after that time
# 	if duration > 0.0:
# 		time.start(duration)
# 		time.timeout.connect(
# 			func():
# 				if player.playing:
# 					player.stop(),
# 			CONNECT_ONE_SHOT
# 		)

# 	# Play only if not already playing
# 	if continuous:
# 		if not player.playing:
# 			player.stream = sfx_audio[file]
# 			player.play()

# Plays full sound normally
# Utils.sfx(self, "step")

# Plays only 0.3s of the gunshot then stops
# Utils.sfx(self, "gunshot", 0.3)
# static func Bg_Music_Manager() -> void:
# 	var Bg_player = AudioStreamPlayer.new()
