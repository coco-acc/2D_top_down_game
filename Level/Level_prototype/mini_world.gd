extends SubViewportContainer

@onready var player: Node2D = get_node("/root/Level/Player")
@onready var mini_camera: Camera2D = $SubViewport/mini_world/mini_Camera
@onready var icon = $SubViewport/mini_world/PlayerIcon
@onready var map_drawer = $SubViewport/mini_world/Map_drawer


func _ready() -> void:
	# Make sure MiniCamera is active only for the minimap viewport
	mini_camera.enabled = false
	#mini_camera.current = false
	# mini_camera.make_current()  # for this viewport only
	# mini_camera.zoom = Vector2(0.7, 0.7)
	# pass

func _process(_delta: float) -> void:
	# if not player:
	# 	return
	
	# Follow player position
	# mini_camera.position = player.global_position
	# icon.position = player.global_position
	icon.position = map_drawer.world_to_map(player.global_position)
