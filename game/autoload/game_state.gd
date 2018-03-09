extends Node


enum ELEMENTS {
	
	FIRE = 0,
	ICE = 1,
	WIND = 2
	
}

var ELEM_COLORS = {
	FIRE: Color(1.0, 0.145, 0.145),
	ICE: Color(0.093, 0.878, 0.839),
	WIND: Color(0.019, 0.988, 0.196)
}

var COLOR_TRANSPEARANT = Color(1.0, 1.0, 1.0, 0.0)


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func eq_with_tolerance(var val1, var val2, var tolerance = val1 * 0.05):
	return abs(val1 - val2) <= tolerance
	
func bake_polygon(parent, blocks, color = COLOR_TRANSPEARANT, print_points = false):

	var polygon = Polygon2D.new()
	parent.add_child_below_node(parent.get_child(0), polygon)
	var poly_points = []
	for block in blocks:
		poly_points.append(block.global_position)
	polygon.color = color
	polygon.polygon = PoolVector2Array(poly_points)
	
	if (print_points):
		print("baking polygon from: %s" % polygon.polygon)
	
	return polygon
	

#add blocks from generated wall to result arra and return modified polygon
#index used to correctly count polygon members in wall
func add_wall_blocks(result_arr, 
wall, 
start_poly_idx):	

	var poly_idx = start_poly_idx
	
	for block in wall.get_children():
		block.polygon_order = poly_idx
		poly_idx += 1
		result_arr.append(block)
		
	return poly_idx

#add blocks from surrounding stage to results array and return modified polygon 
#index used to count polygon members in wall
func add_from_stage_blocks(result_arr, 
from_stage_blocks, 
walk_range,
start_poly_idx,
highlight_color = null):
	
	var poly_idx = start_poly_idx
	
	for idx in walk_range:
		var block = from_stage_blocks[idx % from_stage_blocks.size()]
		block.polygon_order = poly_idx
		poly_idx += 1
		if (highlight_color != null):
			block.modulate = highlight_color
		result_arr.append(block)
	
	return poly_idx
	
func calc_poly_area_nodes(polygon_nodes):
	var globals = []
	for node in polygon_nodes:
		globals.append(node.global_position)
	
	return calc_poly_area(PoolVector2Array(globals))

func calc_poly_area(polygon_points):
	
	var total_area = 0.0
	for idx in range(0, polygon_points.size()):
		var point1 = polygon_points[idx]
		var point2 = polygon_points[(idx + 1) % polygon_points.size()]
		#skip case when X is equal since thats 0 area
		if (point1.x != point2.x):
			var additive = ((point1.y + point2.y) / 2) * (point2.x - point1.x)
			total_area += additive
	
	#according to this algorhit the area should always be positive, but here if all is well
	#it will sometimes be negative since Y axis is pointing down, not up like Descartes
	#sign will ultimately depend on point traversal direction
	return abs(total_area)