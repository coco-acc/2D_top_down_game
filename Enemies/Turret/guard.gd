extends StaticBody2D

var stats := {
	"health": 100,
	"is_alive": true
}

var chunks:int = 2            # grid (3x3, 4x4, …)
var scatter_force:float = 320.0
var torque_force:float = 8.0
var debris_ttl:float = 2.5    # seconds before debris auto-despawn
var spawn_offset:float = 12.0 # push fractured pieces forward from gun

var _fracturing := false

func hit(damage:int) -> void:
	Utils.get_hit(stats, damage)
	if !stats["is_alive"] and !_fracturing:
		_fracturing = true
		call_deferred("_fracture_runtime")


func _fracture_runtime() -> void:
	var spr: Sprite2D = $Sprite2D
	if spr == null or spr.texture == null:
		queue_free()
		return

	var parent := get_parent()
	var tex: Texture2D = spr.texture

	var source_rect: Rect2
	if spr.region_enabled:
		source_rect = spr.region_rect
	else:
		source_rect = Rect2(Vector2.ZERO, tex.get_size())

	var base_pos := global_position
	var base_rot := global_rotation
	var base_scale := global_scale
	var forward := Vector2.RIGHT.rotated(base_rot) # "gun facing" direction

	var step := source_rect.size / float(chunks)

	for ix in range(chunks):
		for iy in range(chunks):
			# var rb := Sprite2D.new()
			var rb := RigidBody2D.new()
			rb.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
			rb.freeze = false
			rb.gravity_scale = 0.0  # no gravity in top-down
			rb.linear_damp = 2.0    # slow down drift
			rb.angular_damp = 2.0
			parent.add_child(rb)

			# Offset slightly forward so debris appears in front of the "gun"
			var local_offset := (Vector2(ix, iy) * step + step * 0.5) * base_scale
			var world_offset := local_offset.rotated(base_rot) + forward * spawn_offset
			rb.global_position = base_pos + world_offset
			rb.global_rotation = base_rot

			var piece := Sprite2D.new()
			piece.texture = tex
			piece.region_enabled = true
			piece.region_rect = Rect2(source_rect.position + Vector2(ix, iy) * step, step)
			piece.position = Vector2.ZERO
			piece.scale = base_scale
			rb.add_child(piece)

			# Scatter outward with a little randomness
			var radial_dir := (world_offset).normalized()
			if radial_dir == Vector2.ZERO:
				radial_dir = Vector2.RIGHT.rotated(randf() * TAU)

			# Random direction
			var random_dir := Vector2.RIGHT.rotated(randf() * TAU)

			# Combine and normalize
			var dir := (radial_dir * 0.5 + random_dir * 1.0).normalized() - Vector2(deg_to_rad(180),deg_to_rad(180))  # weighted more toward randomness
			var impulse := dir * randf_range(scatter_force * 0.6, scatter_force * 1.2)
			rb.apply_impulse(impulse)
			rb.apply_torque_impulse(randf_range(-torque_force, torque_force))


			# Auto-remove debris after some time
			if debris_ttl > 0.0:
				var timer := Timer.new()
				timer.one_shot = true
				timer.wait_time = debris_ttl
				rb.add_child(timer)
				timer.start()
				timer.timeout.connect(func():
					if is_instance_valid(rb):
						rb.queue_free())

	# Finally remove original guard
	queue_free()
