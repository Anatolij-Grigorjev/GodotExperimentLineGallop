extends Node2D

onready var G = get_node("/root/Globals")

var largest_empty_area

var stage_blocks = []
var stage_blocks_hash = {}

var current_block_idx = 0
var highlight_color = Color(1.0, 1.0, 0.1)

var highlight_time = 0.25
var current_highlight_time = 0.0

var is_highlighting = false

func _ready():
	
	#calculate the whole area as largest empty
	stage_blocks = []
	init_stage_blocks($StageBlocks)
	print("found %s blocks currently in the stage!" % stage_blocks.size())
	#sort points by polygon ordering
	stage_blocks.sort_custom(self, "sort_by_poly_order")
	largest_empty_area = calc_poly_area(stage_blocks)
	
	#bake poly?
	var polygon = Polygon2D.new()
	add_child(polygon)
	var poly_points = []
	for block in stage_blocks:
		poly_points.append(block.global_position)
	polygon.color = G.COLOR_TRANSPEARANT
	polygon.polygon = PoolVector2Array(poly_points)
	
	
	print("largest poly area: %s" % largest_empty_area)
	
	$Character.connect("wall_ready", self, "got_wall")
	
	set_process(true)
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
	

func _process(delta):
	
	if (not is_highlighting):
		#start highlight process
		if (Input.is_action_just_released("ui_accept")):
			is_highlighting = true
	else:
		#wait for highlight expry
		if (current_highlight_time > 0):
			current_highlight_time -= delta
		else:
			#highlight next block
			if (current_block_idx < stage_blocks.size()):
				print("%s: %s" % [current_block_idx, stage_blocks[current_block_idx].global_position])
				stage_blocks[current_block_idx].modulate = highlight_color
				if (current_block_idx > 0):
					stage_blocks[current_block_idx - 1].modulate = Color(1.0, 1.0, 1.0)
				current_block_idx += 1
				current_highlight_time = highlight_time
			#all blocks done, finish highlight
			else:
				stage_blocks[current_block_idx - 1].modulate = Color(1.0, 1.0, 1.0)
				current_block_idx = 0
				is_highlighting = false
				

	
func got_wall(wall, point_block_A, point_block_B, is_horizontal):
	
	#get correct blocks by polygon order since it made sorted array
	var block_a_idx = point_block_A.polygon_order
	var block_b_idx = point_block_B.polygon_order
	
	
	
	pass
