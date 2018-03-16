extends Node2D

onready var G = get_node("/root/Globals")

var largest_empty_area = 0.0
var largest_filled_area = 0.0


var stage_blocks = []
#either 1 or -1
#signifies indices direction from top blocks to bottom blocks
#rotation indices can be clockwise, or CCW
onready var stage_blocks_direction = G.CW

var current_block_idx = 0
var highlight_color1 = Color(1.0, 1.0, 0.1)
var highlight_color2 = Color(0.1, 0.1, 1.0)

var highlight_time = 0.15
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
#				print("%s: %s" % [current_block_idx, stage_blocks[current_block_idx].global_position])
				stage_blocks[current_block_idx].modulate = highlight_color1
				if (current_block_idx > 0):
					stage_blocks[current_block_idx - 1].modulate = G.COLOR_SOLID
				current_block_idx += 1
				current_highlight_time = highlight_time
			#all blocks done, finish highlight
			else:
				stage_blocks[current_block_idx - 1].modulate = G.COLOR_SOLID
				current_block_idx = 0
				is_highlighting = false
				

	
func got_wall(wall, point_block_A, point_block_B, is_horizontal):
	
	#get correct blocks by polygon order since it made sorted array
	var block_a_idx = point_block_A.polygon_order
	var block_b_idx = point_block_B.polygon_order
	
	#test which index is larger since thats the second dimension
	#impactin proper poly indices calculation (first is index rotation)
	var larger_a = block_a_idx > block_b_idx
	
	#depedning on current wall polygon order rotation, A might be bigger or smaller
	#than B, so both need to be accounted for
	print("A idx: %s | B idx: %s | ROT: %s | SIZE: %s" % [
	block_a_idx, 
	block_b_idx,
	stage_blocks_direction,
	stage_blocks.size()])
	
	var small_area
	var small_poly
	var poly_idx = 0
	var player_offset
	#create 2 polygons - one with line as one side other as line on other side
	
	#HORIZONTAL
	if (is_horizontal):
		print("polygon BELOW line")
		#set correct player offset
		player_offset = $Character.texture_extents.y
		var the_range
		#polygon before line
		#wall goes top to bottom
		var diff 
		#polygon below line
	
		if (stage_blocks_direction == G.CW):
			#rotation CW and A is smaller so 
			#make point B go forward till looped to A
			if (not larger_a):
				the_range = range(block_b_idx, stage_blocks.size() + block_a_idx)
				print("ROT: CW, A < B")
			#rotation CW A is larger than B
			#so B simply moves along
			else:
				the_range = range(block_b_idx, block_a_idx + 1)
				print("ROT: CW, A > B")
		else:
			#rotation CCW and A is smaller than B
			#so B simply moves backwards till A
			if (not larger_a):
				the_range = range(block_b_idx, block_a_idx - 1, -1)
				print("ROT: CCW, A < B")
			#A is larger than B, so B must loop over start back to A 
			else:
				diff = stage_blocks.size() - block_a_idx
				the_range = range(block_b_idx, -diff - 1, -1)
				print("ROT: CCW, A > B")
			
		var poly_below_map = do_polygon_creation(
		wall, 
		the_range) 

		
		#polygon above line
		
		if (stage_blocks_direction == G.CW):
			
			#if going CW and A is smaller than B then 
			#above is natural progression from A to B, 
			#so B to A is same but negative
			if (not larger_a):
				the_range = range(block_b_idx, block_a_idx - 1, -1)
				print("ROT: CW, A < B")
			#A is larger than B and going CW
			#so from B to A we loop over 0 poly idx and go beyond
			else:
				diff = stage_blocks.size() - block_a_idx
				the_range = range(block_b_idx, -diff - 1, -1)
				print("ROT: CW, A > B")
		else:
			#A is smaller and going CCW
			#need to grwo B big enough to loop over 0 and get to A
			if (not larger_a):
				the_range = range(block_b_idx, stage_blocks.size() + block_a_idx)
				print("ROT: CCW, A < B")
			#A is larger and going CCW
			#B moves natural direction to A
			else:
				the_range = range(block_b_idx, block_a_idx + 1)
				print("ROT: CCW, A > B")
		
		var poly_above_map = do_polygon_creation(
		wall,
		the_range)
		
		#work with new polygons and their areas:
		#save larger as new empty poly, fill smaller with element
		#push player into empty polygon
		if (poly_below_map.area < poly_above_map.area):
			$Character.global_position.y -= player_offset
			stage_blocks = poly_above_map.blocks
			#blocks now go CCW
			stage_blocks_direction = G.CCW
			small_area = poly_below_map.area
			small_poly = poly_below_map.polygon
		else:
			$Character.global_position.y += player_offset
			stage_blocks = poly_below_map.blocks
			#blocks now go CW
			stage_blocks_direction = G.CW
			small_area = poly_above_map.area
			small_poly = poly_above_map.polygon
		
	#VERTICAL
	else:
		print("polygon BEFORE line!")
		#set correct player offset
		player_offset = $Character.texture_extents.x
		var the_range
		#polygon before line
		#wall goes top to bottom
		var diff 
		#if poly rotation is CW then bottom can
		#"behind" wall by increasing till we loop up to top idx
		if (stage_blocks_direction == G.CW):
			#with b being larger it just increases index until it loops
			#behind the wall to reach lower a
			if (not larger_a):
				diff = stage_blocks.size() - block_b_idx + block_a_idx 
				the_range = range(block_b_idx, block_b_idx + diff)
				print("ROT: CW, A < B")
			#if b is smaller, looping behind wall going clockwise means 
			#simple increase in indices
			else:
				the_range = range(block_b_idx, block_a_idx + 1)
				print("ROT: CW, A > B")
		#if poly rotation is CCW then bottom indices 
		#go "behind" wall by decreasing from bottom indices to 0 
		#and looping to top
		else:
			#B is larger, so going CCW behind wall means 
			#decreasing B by diff
			if (not larger_a):
				diff = stage_blocks.size() - block_a_idx
				the_range = range(block_b_idx, -diff - 1, -1)
				print("ROT: CCW, A < B")
			#a is larger, so when indices rotate CCW
			#going from b to a means looping from B backwards
			# over 0 polies to make it to A
			else:
				diff = (stage_blocks.size() - block_a_idx)
				the_range = range(block_b_idx, -diff, -1)
				print("ROT: CCW, A > B")
				
		var poly_before_map = do_polygon_creation(
		wall, 
		the_range)
		
		print("polygon AFTER line!")
		#polyon after line
		#after wall calculated top to bottom 
		#if stage was rotated CW then in front of wall natural 
		#progression backwards via -1 from B to A (when B is larger)
		if (stage_blocks_direction == G.CW):
			if (not larger_a):
				the_range = range(block_b_idx, block_a_idx - 1, -1)
				print("ROT: CW, A < B")
			#A is larger so when indices going CW, rotation to 
			#after wall is reaching 0 from B and keep 
			#moving back till we hit A
			else:
				diff = (stage_blocks.size() - block_a_idx)
				the_range = range(block_b_idx, -diff, -1)
				print("ROT: CW, A > B")
				
		#if stage is rotated CCW then progression front of wall
		#is positive direction from B to A
		else:
			#natural rotation direction if A larger than B
			if (larger_a):
				the_range = range(block_b_idx, block_a_idx + 1)
				print("ROT: CCW, A < B")
			else:
				#if B larger than A,  progress backwards naturally
				the_range = range(block_b_idx, block_a_idx, -1)
				print("ROT: CCW, A > B")
				
		var poly_after_map = do_polygon_creation(
		wall, 
		the_range
		)
		
		#work with new polygons and their areas:
		#save larger as new empty poly, 
		#fill smaller with element
		#push player into empty polygon
		if (poly_before_map.area < poly_after_map.area):
			$Character.global_position.x += player_offset
			stage_blocks = poly_after_map.blocks
			stage_blocks_direction = G.CCW
			small_area = poly_before_map.area
			small_poly = poly_before_map.polygon
		else:
			$Character.global_position.x -= player_offset
			stage_blocks = poly_before_map.blocks
			stage_blocks_direction = G.CW
			small_area = poly_after_map.area
			small_poly = poly_after_map.polygon
		
	#add smaller poly to fill and put element color
	add_to_fill(small_area)
	small_poly.color = G.ELEM_COLORS[$Character.curr_elem_idx]
	
	print("POLY IDX ROT: %s" % stage_blocks_direction)
	pass
	
	
func do_polygon_creation(wall, stage_idx_range, highlight_color = G.COLOR_SOLID):
	
	var range_string = G.range_to_string(stage_idx_range)
	
	print("create polygon from idx range: %s (size %s)" % [range_string, stage_idx_range.size()])
	
	var poly_idx = 0
	var poly_blocks = []
	
	#add new wall blocks, always goes from first to last
	poly_idx = G.add_wall_blocks(poly_blocks, wall, 0)
	
	#add blocks from stage, using supplied range
	G.add_from_stage_blocks(poly_blocks,
	stage_blocks,
	stage_idx_range,
	poly_idx,
	highlight_color)
	
	#sort blocks one last time
	sort_poly_blocks(poly_blocks)
	var polygon = G.bake_polygon(self, poly_blocks)
	var poly_area = G.calc_poly_area(polygon.polygon)
	print("polygon area: %s" % poly_area)
	#return the polygon info map
	return {
		"blocks": poly_blocks,
		"polygon": polygon,
		"area": poly_area
	}
	

func sort_poly_blocks(blocks):
	#sort points by polygon ordering
	blocks.sort_custom(self, "sort_by_poly_order")
	
func add_to_fill(area):
	largest_filled_area += area
	var fill_prc = (largest_filled_area * 100.0) / largest_empty_area
	set_fill_level(fill_prc)
