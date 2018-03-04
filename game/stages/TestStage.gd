extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var largest_empty_area

var stage_blocks = []

func _ready():
	
	#calculate the whole area as largest empty
	stage_blocks = []
	init_stage_blocks($StageBlocks)
	print("found %s blocks currently in the stage!" % stage_blocks.size())
	#sort points by polygon ordering
	stage_blocks.sort_custom(self, "sort_by_poly_order")
	largest_empty_area = calc_poly_area(stage_blocks)
	
	print("largest poly area: %s" % largest_empty_area)
	
	$Character.connect("wall_ready", self, "got_wall")
	
	pass


func init_stage_blocks(parent_shape):

	if (parent_shape is Sprite):
		if (parent_shape.has_node("Area") and parent_shape.get_node("Area") is StaticBody2D):
			stage_blocks.append(parent_shape)
	elif (parent_shape is Node2D):
		for child in parent_shape.get_children():
			init_stage_blocks(child)
	
	
func sort_by_poly_order(item1, item2):
	return item1.polygon_order < item2.polygon_order 


func calc_poly_area(polygon_nodes):
	
	var total_area = 0.0
	for idx in range(0, polygon_nodes.size()):
		var point1 = polygon_nodes[idx].global_position
		var point2 = polygon_nodes[(idx + 1) % polygon_nodes.size()].global_position
		#skip case when X is equal since thats 0 area
		if (point1.x != point2.x):
			var additive = ((point1.y + point2.y) / 2) * (point2.x - point1.x)
			total_area += additive
			
	return abs(total_area)
	


	
func got_wall(wall, is_horizontal):
	pass
