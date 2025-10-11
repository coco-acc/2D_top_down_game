extends Node
class_name Audio_Player

# static var player: AudioStreamPlayer2D = null
# static var time: Timer = null
static var active_players := {}

# Dictionary of preloaded SFX (set this up elsewhere)
static var sfx_audio := {
	"step": preload("res://Audio_assets/sfx/Step_rock_02.wav"),
	"gunshot1": preload("res://Audio_assets/sfx/gunshot1.mp3"),
	"gunshot2": preload("res://Audio_assets/sfx/gunshot2.mp3"),
	"MG1" : preload("res://Audio_assets/sfx/machin-gun-mg34-double-sound.mp3"),
	"MG2" : preload("res://Audio_assets/sfx/mg1.wav"),

	"explosion" : preload("res://Audio_assets/sfx/explosion-fx.mp3"),
	"door" : preload("res://Audio_assets/sfx/door/1/3.wav"),
	"door2" : preload("res://Audio_assets/sfx/door/1/door2.wav")
}

static func play_sfx(scene_root: Node, file: String, duration: float = -1.0, continuous: bool = false, start: float = 0.0, bus: String = "SFX") -> void:
	# Validate SFX
	if not sfx_audio.has(file):
		push_warning("Invalid SFX name: %s" % file)
		return

	# Create player once
	# if player == null:
	var player = AudioStreamPlayer2D.new()
	scene_root.add_child(player)

	# Assign bus (fallback to Master if invalid)
	if AudioServer.get_bus_index(bus) != -1:
		player.bus = bus
	else:
		player.bus = "Master"

	# Create timer once
	# if time == null:
	var time = Timer.new()
	time.one_shot = true
	scene_root.add_child(time)

	# Validate SFX
	if not sfx_audio.has(file):
		push_warning("Invalid SFX name: %s" % file)
		return

	# Configure player
	# Play only if not already playing
	if continuous:
		if not player.playing:
			player.stream = sfx_audio[file]
			player.play(start)
	else:
		player.stream = sfx_audio[file]
		player.play(start)


	active_players[file] = player

	# Continuous (loop-like) playback
	# if continuous:
	# 	player.stream.loop_mode = AudioStream.LOOP_FORWARD
	# else:
	# 	player.stream.loop_mode = AudioStream.LOOP_DISABLED


	# If duration > 0, stop after that time
	if duration > 0.0:
		time.start(duration)
		time.timeout.connect(
			func():
				if player.playing:
					player.stop()
				player.queue_free()
				time.queue_free(),
			CONNECT_ONE_SHOT
		)
	else:
		# Auto cleanup when playback finishes (non-continuous only)
		if not continuous:
			player.finished.connect(
				func():
					player.queue_free()
					time.queue_free(),
				CONNECT_ONE_SHOT
			)

static func stop_sfx(file: String) -> void:
	if active_players.has(file):
		var player = active_players[file]
		if player and player.playing:
			player.stop()
			# player.queue_free()
		active_players.erase(file)


# Play a gunshot once
#----------------> Audio_player.play_sfx(self, "gunshot")

# Play footsteps continuously until stopped
# ----------------> Audio_player.play_sfx(self, "step", continuous = true)

# Stop manually
# ----------------> Audio_player.stop_sfx()

# Play an explosion but auto-stop after 0.5s
# ----------------> Audio_player.sfx(self, "explosion", duration = 0.5)
