extends Node2D

onready var G = get_node("/root/Globals")

var largest_empty_area = 0.0
var largest_filled_area = 0.0


var stage_blocks = []

var current_block_idx = 0
var highlight_color1 = Color(1.0, 1.0, 0.1)
var highlight_color2 = Color(0.1, 0.1, 1.0)

var highlight_time = 0.25
var current_highlight_time = 0.0

var fill_level = 0.0

var is_highlighting = false

func _ready():
	
	#calculate the whole area as largest empty
	stage_blocks = []
	init_stage_blocks($StageBlocks)
	print("found %s blocks currently in the stage!" % stage_blocks.size())
	
	sort_poly_blocks(stage_blocks)
	
	largest_empty_area = G.calc_poly_area_nodes(stage_blocks)
	
	#bake initial stage poly
	G.bake_polygon(self, stage_blocks)
	
	set_fill_level(0.0)
	
	print("largest poly area: %s" % largest_empty_area)
	
	$Character.connect("wall_ready", self, "got_wall")
	
	set_process(true)
	pass

func set_fill_level(level):
	fill_level = level
	$FillLevel.text = "FILL: %d%%" % level

func init_stage_blocks(parent_shape):

	if (parent_shape is Sprite):
		if (parent_shape.has_node("Area") and parent_shape.get_node("Area") is StaticBody2D):
			stage_blocks.append(parent_shape)
	elif (parent_shape is Node2D):
		for child in parent_shape.get_children():
			init_stage_blocks(child)
	
	
func sort_by_poly_order(item1, item2):
	return item1.polygon_order < item2.polygon_order 
	

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
	
	var poly_idx = 0
	if (is_horizontal):
		#polygon below line
		var below_poly_blocks = []
		
		#start with new wall blocks
		poly_idx = G.add_wall_blocks(below_poly_blocks, wall, 0)
		
		#because cannon A is on the left in this configuration
		#the idx of that block is higher since the thing goes 
		#clockwise from topmost block
		#add blocks below line
		G.add_from_stage_blocks(below_poly_blocks, 
		stage_blocks, 
		range(block_b_idx, block_a_idx + 1), 
		poly_idx, 
		highlight_color1)
			
		sort_poly_blocks(below_poly_blocks)
		var poly_below = G.bake_polygon(self, below_poly_blocks)
		var poly_below_area = G.calc_poly_area(poly_below.polygon)
		
		#polygon above line
		var above_poly_blocks = []
		poly_idx = 0
		var blocks_diff = block_b_idx + (stage_blocks.size() - block_a_idx)
		#start with blocks above line
		#actually idx will be culled to use this as a ring
		poly_idx = G.add_from_stage_blocks(above_poly_blocks,
		stage_blocks,
		range(block_a_idx + blocks_diff, block_a_idx, -1),
		0,
		highlight_color2)

		#add line
		poly_idx = G.add_wall_blocks(above_poly_blocks, wall, poly_idx)
		
		sort_poly_blocks(above_poly_blocks)
		var poly_above = G.bake_polygon(self, above_poly_blocks)
		var poly_above_area = G.calc_poly_area(poly_above.polygon)
		
		#work with new polygons and their areas:
		#save larger as new empty poly, fill smaller with element
		var large_area = poly_below_area
		var large_poly = poly_below
		var small_area = poly_above_area
		var small_poly = poly_above
		if (poly_below_area < poly_above_area):
			small_area = poly_below_area
			small_poly = poly_below
			large_area = poly_above_area
			large_poly = poly_above
		
		#add smaller poly to fill and put element color
		add_to_fill(small_area)
		small_poly.color = G.ELEM_COLORS[$Character.curr_elem_idx]
		
		#push player into larger polygon
		var offset = $Character.texture_half_height
		if (small_poly == poly_above):
			$Character.global_position.y += offset
		else:
			$Character.global_position.y -= offset
		
		#use nodes of larger poly as new main stage polygon
		if (large_poly == poly_above):
			stage_blocks = above_poly_blocks
		else:
			stage_blocks = below_poly_blocks
		

	pass
	
	

func sort_poly_blocks(blocks):
	#sort points by polygon ordering
	blocks.sort_custom(self, "sort_by_poly_order")
	
func add_to_fill(area):
	largest_filled_area += area
	var fill_prc = (largest_filled_area * 100.0) / largest_empty_area
	set_fill_level(fill_prc)
