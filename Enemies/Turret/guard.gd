extends StaticBody2D

var stats := {
	"health": 100,
	"is_alive": true
}

var chunks:int = 2            # grid (3x3, 4x4, …)
var scatter_force:float = 420.0
var torque_force:float = 100.0
var debris_ttl:float = 0.5    # seconds before debris auto-despawn
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
	var forward := Vector2.RIGHT.rotated(base_rot)

	var step := source_rect.size / float(chunks)
	var jitter := 1.0 # Max offset in pixels for irregularity
	var scale_variation := 0.3 # ±30% size variation

	for ix in range(chunks):
		for iy in range(chunks):
			var rb := RigidBody2D.new()
			rb.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
			rb.freeze = false
			rb.gravity_scale = 0.0
			rb.linear_damp = 5.0
			rb.angular_damp = 0.0
			parent.add_child(rb)

			# Random offset per piece
			var offset_jitter := Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
			var local_offset := (Vector2(ix, iy) * step + step * 0.5 + offset_jitter) * base_scale
			var world_offset := local_offset.rotated(base_rot) + forward * spawn_offset
			rb.global_position = base_pos + world_offset
			rb.global_rotation = base_rot

			var piece := Sprite2D.new()
			piece.texture = tex
			piece.region_enabled = true

			# Slightly randomize piece size
			var size_jitter := step * randf_range(1.0 - scale_variation, 1.0 + scale_variation)
			piece.region_rect = Rect2(source_rect.position + Vector2(ix, iy) * step, size_jitter)

			# Random scale and rotation for more irregular look
			piece.scale = base_scale * randf_range(0.8, 1.2)
			piece.rotation_degrees = randf_range(0, 360)

			piece.position = Vector2.ZERO
			rb.add_child(piece)

			# Scatter outward
			var radial_dir := (world_offset).normalized()
			if radial_dir == Vector2.ZERO:
				radial_dir = Vector2.RIGHT.rotated(randf() * TAU)

			var random_dir := Vector2.RIGHT.rotated(randf() * TAU)
			var dir := (radial_dir * 0.5 + random_dir * 1.0).normalized()
			var impulse := dir * randf_range(scatter_force * 0.6, scatter_force * 1.2)
			rb.apply_impulse(impulse)
			rb.apply_torque_impulse(randf_range(-torque_force, torque_force))

			# Auto-remove debris
			if debris_ttl > 0.0:
				var timer := Timer.new()
				timer.one_shot = true
				timer.wait_time = debris_ttl
				rb.add_child(timer)
				timer.start()
				timer.timeout.connect(func():
					Utils.dissolve_effect(parent, piece, 0.5)
					var cleanup_timer := Timer.new()
					cleanup_timer.one_shot = true
					cleanup_timer.wait_time = 0.5
					rb.add_child(cleanup_timer)
					cleanup_timer.timeout.connect(func():
						if is_instance_valid(rb):
							rb.queue_free()))

	queue_free()