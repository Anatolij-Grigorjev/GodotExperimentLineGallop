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
	
	var small_area
	var small_poly
	var poly_idx = 0
	var player_offset
	#create 2 polygons - one with line as one side other as line on other side
	
	#HORIZONTAL
	if (is_horizontal):
		#set correct player offset
		player_offset = $Character.texture_extents.y
		#polygon below line
		#create polygon below line, 
		#starting at line from left to right
		var poly_below_map = do_polygon_creation(
		wall, 
		range(block_b_idx, block_a_idx),
		highlight_color1)

		
		#polygon above line
		#range goes into negative indices 
		#this will loop around the back of the stage
		var poly_above_map = do_polygon_creation(
		wall,
		range(block_b_idx, block_a_idx - stage_blocks.size(), -1),
		highlight_color2)
		
		#work with new polygons and their areas:
		#save larger as new empty poly, fill smaller with element
		#push player into empty polygon
		if (poly_below_map.area < poly_above_map.area):
			$Character.global_position.y += player_offset
			stage_blocks = poly_above_map.blocks
			small_area = poly_below_map.area
			small_poly = poly_below_map.polygon
		else:
			$Character.global_position.y -= player_offset
			stage_blocks = poly_below_map.blocks
			small_area = poly_above_map.area
			small_poly = poly_above_map.polygon
		
	#VERTICAL
	else:
		#set correct player offset
		player_offset = $Character.texture_extents.x
		
		#polygon before line
		#wall goes top to bottom, at bottom indices are higher
		#need to add enough range offset to loop the stage
		var diff = stage_blocks.size() - block_b_idx + block_a_idx
		var poly_before_map = do_polygon_creation(
		wall, 
		range(block_b_idx, block_b_idx + diff),
		highlight_color1)
		
		#polyon after line
		#after wall calculated top to bottom, 
		#the bottom indices are higher but they move back to top
		var poly_after_map = do_polygon_creation(
		wall, 
		range(block_b_idx, block_a_idx + 1, -1),
		highlight_color2)
		
		#work with new polygons and their areas:
		#save larger as new empty poly, 
		#fill smaller with element
		#push player into empty polygon
		if (poly_before_map.area < poly_after_map.area):
			$Character.global_position.x -= player_offset
			stage_blocks = poly_after_map.blocks
			small_area = poly_before_map.area
			small_poly = poly_before_map.polygon
		else:
			$Character.global_position.x += player_offset
			stage_blocks = poly_before_map.blocks
			small_area = poly_after_map.area
			small_poly = poly_after_map.polygon
		
	#add smaller poly to fill and put element color
	add_to_fill(small_area)
	small_poly.color = G.ELEM_COLORS[$Character.curr_elem_idx]
	pass
	
	
func do_polygon_creation(wall, stage_idx_range, highlight_color):
	
	var poly_idx = 0
	var poly_blocks = []
	
	#add new wall blocks, always goes from first to last
	poly_idx = G.add_wall_blocks(poly_blocks, wall, 0)
	
	#add blocks from stage, using supplied range
	G.add_from_stage(poly_blocks,
	stage_blocks,
	stage_idx_range,
	poly_idx,
	highlight_color)
	
	#sort blocks one last time
	sort_poly_blocks(poly_blocks)
	var polygon = G.bake_polygon(self, poly_blocks)
	#return the polygon info map
	return {
		"blocks": poly_blocks,
		"polygon": polygon,
		"area": G.calc_poly_area(polygon.polygon)
	}
	

func sort_poly_blocks(blocks):
	#sort points by polygon ordering
	blocks.sort_custom(self, "sort_by_poly_order")
	
func add_to_fill(area):
	largest_filled_area += area
	var fill_prc = (largest_filled_area * 100.0) / largest_empty_area
	set_fill_level(fill_prc)
