extends Node
class_name Audio_Player

static var player: AudioStreamPlayer2D = null
static var time: Timer = null

# Dictionary of preloaded SFX (set this up elsewhere)
static var sfx_audio := {
	"step": preload("res://Audio_assests/sfx/Step_rock_02.wav"),
	"gunshot1": preload("res://Audio_assests/sfx/gunshot1.mp3"),
	"gunshot2": preload("res://Audio_assests/sfx/gunshot2.mp3"),
	"MG1" : preload("res://Audio_assests/sfx/machin-gun-mg34-double-sound.mp3"),
	"MG2" : preload("res://Audio_assests/sfx/mg1.wav"),

	"explosion" : preload("res://Audio_assests/sfx/explosion-fx.mp3")
}

static func play_sfx(scene_root: Node, file: String, duration: float = -1.0, continuous: bool = false, start: float = 0.0) -> void:
	# Create player once
	if player == null:
		player = AudioStreamPlayer2D.new()
		scene_root.add_child(player)

	# Create timer once
	if time == null:
		time = Timer.new()
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
					player.stop(),
			CONNECT_ONE_SHOT
		)

static func stop_sfx() -> void:
	if player != null and player.playing:
		player.stop()


# Play a gunshot once
#----------------> Audio_player.play_sfx(self, "gunshot")

# Play footsteps continuously until stopped
# ----------------> Audio_player.play_sfx(self, "step", continuous = true)

# Stop manually
# ----------------> Audio_player.stop_sfx()

# Play an explosion but auto-stop after 0.5s
# ----------------> Audio_player.sfx(self, "explosion", duration = 0.5)
