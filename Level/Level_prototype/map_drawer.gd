extends Node2D

@onready var level_path: NodePath = "/root/Level/ground"
@onready var line_color: Color = Color(0.9, 0.9, 0.9)
@onready var fill_color: Color = Color(0.2, 0.4, 0.6, 0.3)
@onready var line_width: float = 2.0
@onready var margin: float = 100.0  # extra border space in map
@onready var icon = get_node("/root/Level/UI/HBoxContainer/Mini_map/SubViewport/MarginContainer/mini_world/PlayerIcon")
@onready var player: Node2D = get_node("/root/Level/Player")

var polygons: Array = []
var map_bounds: Rect2
var map_scale: float = 1.0
var map_offset: Vector2 = Vector2.ZERO
var Mini_offset: Vector2 = Vector2(0,0)

func _ready() -> void:
	# Wait one frame so the viewport size is valid
	await get_tree().process_frame
	_collect_polygons()
	_calculate_bounds()
	_compute_transform()

	queue_redraw()

# --- Collect all CollisionPolygon2D shapes from the ground---
func _collect_polygons() -> void:
	polygons.clear()
	var level = get_node_or_null(level_path)
	if not level:
		push_warning("Level not found at path: %s" % level_path)
		return

	for room in level.get_children():
		if room is Node2D:
			_collect_polygons_from_node(room)

	print("Collected polygons:", polygons.size())

# --- Compute total bounds of all polygons ---
func _calculate_bounds() -> void:
	if polygons.is_empty():
		map_bounds = Rect2(Vector2.ZERO, Vector2.ONE)
		return

	var min_x = polygons[0][0].x
	var max_x = min_x
	var min_y = polygons[0][0].y
	var max_y = min_y

	for poly in polygons:
		for p in poly:
			min_x = min(min_x, p.x)
			max_x = max(max_x, p.x)
			min_y = min(min_y, p.y)
			max_y = max(max_y, p.y)

	map_bounds = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

# --- Determine how to fit and center the map into the minimap viewport ---
func _compute_transform() -> void:
	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		push_warning("Viewport size is zero, map not drawn yet.")
		return

	# var scale_x = (viewport_size.x - margin) / map_bounds.size.x
	# var scale_y = (viewport_size.y - margin) / map_bounds.size.y
	# map_scale = min(scale_x, scale_y)

	# var map_center = map_bounds.position + map_bounds.size * 0.5
	# map_offset = viewport_size * 0.5 - map_center * map_scale
	map_scale = 0.01
	map_offset = Vector2(128,-500)  # center in viewport for testing
	queue_redraw()

# --- Draw polygons (filled + outlined) ---
func _draw() -> void:

	for poly in polygons:
		var transformed_poly: Array[Vector2] = []
		for p in poly:
			transformed_poly.append(p * map_scale + map_offset)

		# Fill
		draw_colored_polygon(transformed_poly, fill_color)
		# Outline
		draw_polyline(transformed_poly + [transformed_poly[0]], line_color, line_width)

func _process(_delta: float) -> void:
	if not is_instance_valid(Player):
		return

	var center = get_viewport_rect().size / 2

	# Use the correct variable name 'player' (lowercase)
	var player_map_pos = world_to_map(player.global_position) + Mini_offset

	# Move the map so the player is at the center
	self.position = center - player_map_pos

	# Keep the icon at the center
	icon.position = center




# --- Convert world coordinates to minimap coordinates (for player icon, etc.) ---
func world_to_map(world_pos: Vector2) -> Vector2:
	return world_pos * map_scale + map_offset

func _collect_polygons_from_node(node: Node) -> void:
	# Recursively search for CollisionPolygon2D
	if node is CollisionPolygon2D and node.polygon.size() > 0:
		var global_poly: Array[Vector2] = []
		for p in node.polygon:
			global_poly.append(node.to_global(p))
		polygons.append(global_poly)
	else:
		for child in node.get_children():
			if child is Node:
				_collect_polygons_from_node(child)
