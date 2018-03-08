extends Node2D

onready var G = get_node("/root/Globals")

var largest_empty_area

var stage_blocks = []

var current_block_idx = 0
var highlight_color1 = Color(1.0, 1.0, 0.1)
var highlight_color2 = Color(0.1, 0.1, 1.0)

var highlight_time = 0.25
var current_highlight_time = 0.0

var is_highlighting = false

func _ready():
	
	#calculate the whole area as largest empty
	stage_blocks = []
	init_stage_blocks($StageBlocks)
	print("found %s blocks currently in the stage!" % stage_blocks.size())
	
	sort_poly_blocks(stage_blocks)
	
	largest_empty_area = calc_poly_area(stage_blocks)
	
	#bake initial stage poly
	G.bake_polygon(self, stage_blocks)
	
	
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
				stage_blocks[current_block_idx].modulate = highlight_color1
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
	
	print("A idx: %s | B idx: %s" % [block_a_idx, block_b_idx])
	
	#create 2 polygons - one with line as one side other as line on other side
	var poly_blocks = []
	var poly_idx = 0
	if (is_horizontal):
		#polygon below line
		#start with new wall blocks
		poly_idx = G.add_wall_blocks(poly_blocks, wall, 0)
		
		#because cannon A is on the left in this configuration
		#the idx of that block is higher since the thing goes 
		#clockwise from topmost block
		#add blocks below line
		G.add_from_stage_blocks(poly_blocks, 
		stage_blocks, 
		range(block_b_idx, block_a_idx + 1), 
		poly_idx, 
		highlight_color1)
			
		sort_poly_blocks(poly_blocks)
		G.bake_polygon(self, poly_blocks, highlight_color1)
		
		#polygon above line
		poly_blocks = []
		poly_idx = 0
		var blocks_diff = block_b_idx + (stage_blocks.size() - block_a_idx)
		#start with blocks above line
		#actually idx will be culled to use this as a ring
		poly_idx = G.add_from_stage_blocks(poly_blocks,
		stage_blocks,
		range(block_a_idx + blocks_diff, block_a_idx, -1),
		0,
		highlight_color2)

		#add line
		poly_idx = G.add_wall_blocks(poly_blocks, wall, poly_idx)
		
		sort_poly_blocks(poly_blocks)
		G.bake_polygon(self, poly_blocks, highlight_color2)
		
	pass
	
	

func sort_poly_blocks(blocks):
	#sort points by polygon ordering
	blocks.sort_custom(self, "sort_by_poly_order")
