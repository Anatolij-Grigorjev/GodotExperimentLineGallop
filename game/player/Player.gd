extends KinematicBody2D

onready var G = get_node("/root/Globals")

#abstract segment handle for static functions
onready var AbstractSegment = preload("res://segments/AbstractSegment.gd")

const SPEED = 200
const GROUP_CURR_GROWERS = "curr_growers"
const SEGMENT_COOLDOWN_SEC = 0.5

var curr_mouse_pos

#index of current walls element
var curr_elem_idx = 0

#sides A and B of cannon direction
var point_side_a
var point_side_b

#are cannons left-right oriented? might be top-bottom
var orientation_LR = true

#i the character firing a line right now? cant move and flip cannons
var is_firing_line = false

#half height of texture to push out of line when its done
var texture_half_height

enum LINE_ORIENTATIONS {
	LO_LEFT = 180,
	LO_TOP = 270,
	LO_RIGHT = 0,
	LO_BOTTOM = 90
}

const SCALE_FLIP_V = Vector2(1, -1)

onready var point_segment_transform = {
	$MainBall/POSHRight: {
			"growth_vector": Vector2(1, 0)
		},
	$MainBall/POSVTop: {
			"rotate": LO_TOP,
			"scale": SCALE_FLIP_V,
			"growth_vector": Vector2(0, -1)
		},
	$MainBall/POSVBottom: {
			"rotate": LO_BOTTOM,
			"growth_vector": Vector2(0, 1)
		},
	$MainBall/POSHLeft: {
			"rotate": LO_LEFT,
			"scale": SCALE_FLIP_V,
			"growth_vector": Vector2(-1, 0)
		}
}

onready var element_growers = {
	
	G.ELEMENTS.FIRE: preload("res://segments/line_growers/FireGrower.tscn")
}

onready var element_blocks = {
		G.ELEMENTS.FIRE: preload("res://segments/stage_segments/FireStageBlock.tscn")
	}


signal wall_ready(wall, point_block_A, point_block_B, is_horizontal)


func _ready():
	
	$ExpandTimer.wait_time = SEGMENT_COOLDOWN_SEC
	
	texture_half_height = $MainBall.texture.get_height() / 2
	
	#is orientation left/right right now for cannons
	orientation_LR = true
	
	point_side_a = $MainBall/POSHLeft
	point_side_b = $MainBall/POSHRight
	
	Input.warp_mouse_position(position)
	
	curr_mouse_pos = position
	
	set_elem_idx(curr_elem_idx)
	
	set_process(true)
	set_physics_process(true)
	
	pass


#process player movement in fixed update
func _physics_process(delta):
	
	#skip this if line is being fired
	if (is_firing_line):
		return

	curr_mouse_pos = get_viewport().get_mouse_position()
	var friction = 1
	
	#if the mouse and player position is different enough, then
	#move player to mouse
	if (not (G.eq_with_tolerance(curr_mouse_pos.x, global_position.x)
	and G.eq_with_tolerance(curr_mouse_pos.y, global_position.y))):
		
		#end of path - start of path to get vector poitning from start to end
		var direction = (curr_mouse_pos - global_position).normalized()
		
		var velocity = direction * SPEED * delta
		
		#this already takes delta into account when performed, 
		#so no need for extra
		move_and_collide(velocity)
	

	pass


func _process(delta):
	
	#handle elem change input
	if (Input.is_action_just_released("cycle_elements") and not is_firing_line):
		set_elem_idx(curr_elem_idx + 1)
	
	var flip_gun_playing = $Animation.current_animation == "rotate_cannons" and $Animation.is_playing()
	
	#only do these things when cannons arent moving
	if (not flip_gun_playing):
		if (not is_firing_line and Input.is_action_just_released("flip_line_gun")):
			if (orientation_LR):
				$Animation.play("rotate_cannons")
			else:
				$Animation.play_backwards("rotate_cannons")
			orientation_LR = not orientation_LR
			flip_cannons()
		
		if (Input.is_action_just_released("start_stop_line")):
			#start firing
			if (not is_firing_line):
				is_firing_line = true
				$ExpandTimer.wait_time = SEGMENT_COOLDOWN_SEC
				$ExpandTimer.start()
				$Animation.play("firing")
				
				for point in [point_side_a, point_side_b]:
					make_grower_at_point(point)
				pass
			else:
				#cancel lines
				stop_firing()
				pass
			pass
	
	pass
	
	
func grow_current_lines():
	for grower in curr_lines():
		if (not grower.done_growing):
			#add one block to grower
			grower.add_block()
			var growth_dir = point_segment_transform[grower.get_parent()]["growth_vector"]
			#move grower to accommodate new block
			grower.position += (grower.block_size * growth_dir)
	pass
	

func curr_lines():
	return get_tree().get_nodes_in_group(GROUP_CURR_GROWERS)
	
func make_grower_at_point(point):
	#get correct grower packed
	var packed_grower = element_growers[curr_elem_idx]
	var new_grower = packed_grower.instance()
	point.add_child(new_grower)
	new_grower.position = point_segment_transform[point]["growth_vector"] * (new_grower.block_size / 2)
	#transform grower
	var transform = point_segment_transform[point]
	if (transform.has("rotate")):
		new_grower.rotation_degrees = transform["rotate"]
	if (transform.has("scale")):
		new_grower.scale = transform["scale"]
	
	new_grower.add_to_group(GROUP_CURR_GROWERS)
	new_grower.connect("grower_done", self, "line_connected")


func set_elem_idx(var new_idx):
	#clamp new idx just in case
	var idx = new_idx % G.ELEM_COLORS.size()
	#set new color to player elements
	$MainBall/Core.modulate = G.ELEM_COLORS[idx]
	$MainBall/Cannons/CannonA.modulate = G.ELEM_COLORS[idx]
	$MainBall/Cannons/CannonB.modulate = G.ELEM_COLORS[idx]
	#set value to var
	curr_elem_idx = idx
	pass
	
func all_lines_grown():
	var all_done = true
	for line in curr_lines():
		if (not line.done_growing):
			return false
	return all_done
	
	
	
func line_connected(grower, wall):
	var lines_done = all_lines_grown()
	if (lines_done):
		
		var growerA = point_side_a.get_child(0)
		var growerB = point_side_b.get_child(0)
		
		var point1 = growerA.at_wall_global_pos
		var point2 = growerB.at_wall_global_pos
		
		var parent = get_parent()
		
		#create a static body line that will remain in the stage
		var line_parent = AbstractSegment.create_segment_at_points(
		parent, #parent
		element_blocks[curr_elem_idx], #packed wall block
		point1, #point from
		point2, #point to
		(point2 - point1).normalized(), #line direction
		32) #size of single block
		 
		
		#tell stage about it via signal
		emit_signal("wall_ready", line_parent, growerA.wall_node.get_parent(), growerB.wall_node.get_parent(), orientation_LR)
		
		#stop firing lines
		stop_firing()
		
		pass
	
#find global position of line business end	
func get_line_connect_point(line):
	pass
		
		
	
func stop_firing():
	for line in curr_lines():
		line.queue_free()
	
	$Animation.seek(0.0, true)
	$Animation.stop(true)
	$ExpandTimer.stop()
	is_firing_line = false
	

	
func flip_cannons():
	
	if (orientation_LR):
		point_side_a = $MainBall/POSHLeft
		point_side_b = $MainBall/POSHRight
	else:
		point_side_a = $MainBall/POSVTop
		point_side_b = $MainBall/POSVBottom
	pass
