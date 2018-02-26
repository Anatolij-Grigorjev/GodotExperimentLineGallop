extends KinematicBody2D

onready var G = get_node("/root/Globals")

#abstract segment handle for static functions
onready var AbstractSegment = preload("res://segments/AbstractSegment.gd")

const SPEED = 200
const GROUP_CURR_LINES = "curr_lines"
const SEGMENT_COOLDOWN_SEC = 1.0

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

#fire segment scene
var segment_fire_packed = preload("res://segments/fire_segment/FireSegment.tscn")

enum LINE_ORIENTATIONS {
	LO_LEFT = 180,
	LO_TOP = 270,
	LO_RIGHT = 0,
	LO_BOTTOM = 90
}


onready var point_segment_transform = {
	
	$MainBall/POSVTop: {
			"rotate": LO_TOP,
			"flip_v": true
		},
	$MainBall/POSVBottom: {
			"rotate": LO_BOTTOM
		},
	$MainBall/POSHLeft: {
			"rotate": LO_LEFT,
			"flip_v": true
		}
}


#when wall was added, inform level
signal wall_created(wall)

func _ready():
	
	$ExpandTimer.wait_time = SEGMENT_COOLDOWN_SEC
	
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
	
	var flip_gun_playing = $Animation.current_animation == "flip_line_gun" and $Animation.is_playing()
	
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
					make_line_at_point(segment_fire_packed, point)
				pass
			else:
				#cancel lines
				stop_firing()
				pass
			pass
	
	pass
	
func expand_curr_lines():
	#account for stopped firing before timeout
	if (is_firing_line):
		for line in curr_lines():
			if (not line.done_growing):
				line.resize_line(line.line_width + 1)
				add_line_position_unit(line)
		$ExpandTimer.wait_time = SEGMENT_COOLDOWN_SEC
		$ExpandTimer.start()
	

func curr_lines():
	return get_tree().get_nodes_in_group(GROUP_CURR_LINES)


func make_line_at_point(packed_line, point):
	var line = packed_line.instance()
	line.position = point.position
	#transform line appearnce as required
	if (point_segment_transform.has(point)):
		var transform = point_segment_transform[point]
		if (transform.has("rotate")):
			line.rotation_degrees = transform["rotate"]
		if (transform.has("flip_v")):
			line.flip_v = transform["flip_v"]
		
	add_child(line)
	#set initial line size
	line.resize_line(1)
	add_line_position_unit(line)
	line.add_to_group(GROUP_CURR_LINES)
	line.connect("connected_wall", self, "line_connected")

	
func add_line_position_unit(line):
	if (orientation_LR):
		line.position.x += (line.unit_size.x / 2) * sign(line.position.x)
	else:
		line.position.y += (line.unit_size.y / 2) * sign(line.position.y)

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
	
func line_connected(line, wall):
	var lines_done = all_lines_grown()
	if (lines_done):
		#finish new wall segment
		var lines = curr_lines()
		var connect_point_1 = get_line_connect_point(lines[0])
		var connect_point_2 = get_line_connect_point(lines[1])
		
		#create the new line to add
		var parent = get_parent().get_node("Segments")
		var new_wall = AbstractSegment.create_segment_at_points(
		parent,
		segment_fire_packed, 
		connect_point_1, 
		connect_point_2,
		orientation_LR)
		
		#tell level about it
		emit_signal("wall_created", new_wall)
		
		#stop firing lines
		stop_firing()
		
		pass
	
#find global position of line business end	
func get_line_connect_point(line):
	var middle = line.global_position
	var half_length = line.unit_size.x * line.line_width * 0.5
	
	if (line.rotation_degrees == LO_RIGHT):
		return Vector2(middle.x + half_length, middle.y)
		
	if (line.rotation_degrees == LO_BOTTOM):
		return Vector2(middle.x, middle.y + half_length)
		
	if (line.rotation_degrees == LO_LEFT):
		return Vector2(middle.x - half_length, middle.y)
		
	if (line.rotation_degrees == LO_TOP):
		return Vector2(middle.x, middle.y - half_length)
	else:
		print("weird rotation %s for line %s!" % [line.rotation_degrees, line])
		breakpoint
		
		
	
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
