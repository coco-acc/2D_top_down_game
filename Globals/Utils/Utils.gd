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
	var recoil_offset := Vector2(randf_range(-0.3, 0.3), -1.0).rotated(sprite.rotation) * recoil_distance

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

static func get_hit(stats: Dictionary) -> Dictionary:
	if stats["is_alive"]:
		stats["health"] -= 10

		if stats["health"] <= 0:
			stats["health"] = 0
			stats["is_alive"] = false
            # You can emit a signal here if needed
            # SignalBus.player_died.emit()
    
	return stats

static func hit_effect(sprite: Node2D, effect_size: float, duration: float = 0.1) -> void:
	var orig_position := sprite.position
	var offset := Vector2.UP.rotated(sprite.rotation) * effect_size

	sprite.position += offset
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "position", orig_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

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

	