extends KinematicBody2D

onready var G = get_node("/root/Globals")

const SPEED = 500
const FRICTION_COEF = 0.25

var prev_mouse_pos
var curr_mouse_pos

var curr_elem_idx = 0

var point_side_a
var point_side_b

var orientation_LR = true

onready var point_segment_transform = {
	
	$MainBall/POSVTop: {
			"rotate": 270,
			"flip_v": true
		},
	$MainBall/POSVBottom: {
			"rotate": 90
		},
	$MainBall/POSHLeft: {
			"rotate": 180,
			"flip_v": true
		}
}

func _ready():
	
	#is orientation left/right right now for cannons
	orientation_LR = true
	
	point_side_a = $MainBall/POSHLeft
	point_side_b = $MainBall/POSHRight
	
	Input.warp_mouse_position(position)
	
	curr_mouse_pos = position
	prev_mouse_pos = curr_mouse_pos
	
	set_elem_idx(curr_elem_idx)
	
	pass

func _process(delta):
	
	curr_mouse_pos = get_viewport().get_mouse_position()
	var friction = 1
	
	#handle elem change input
	if (Input.is_action_just_released("cycle_elements")):
		set_elem_idx(curr_elem_idx + 1)
	
	var flip_gun_playing = $Animation.current_animation == "flip_line_gun" and $Animation.is_playing()
	
	#only do these things when cannons arent moving
	if (not flip_gun_playing ):
		if (Input.is_action_just_released("flip_line_gun")):
			if (orientation_LR):
				$Animation.play("rotate_cannons")
			else:
				$Animation.play_backwards("rotate_cannons")
			orientation_LR = not orientation_LR
			flip_cannons()
		
		if (Input.is_action_just_released("start_stop_line")):
			#TODO: do the damn shot
			pass
			
	
	#if the mouse stopped moving (within a tolerance)
	#then friciton should be appleid to slow down the player
#	if (G.eq_with_tolerance(curr_mouse_pos.x, prev_mouse_pos.x)
#	and G.eq_with_tolerance(curr_mouse_pos.y, prev_mouse_pos.y)):
#		friction = FRICTION_COEF
	
	var speed = Input.get_last_mouse_speed().normalized() * SPEED * friction
	
	move_and_collide(speed * delta)
	
	prev_mouse_pos = curr_mouse_pos
	
	pass
	
	

func set_elem_idx(var new_idx):
	#clamp new idx just in case
	var idx = new_idx % G.ELEM_COLORS.size()
	#set new color to player elements
	$MainBall/Core.modulate = G.ELEM_COLORS[idx]
	$MainBall/Cannons/CannonA.modulate = G.ELEM_COLORS[idx]
	$MainBall/Cannons/CannonB.modulate = G.ELEM_COLORS[idx]
	#set value to var
	curr_elem_idx = idx
	
func flip_cannons():
	
	if (orientation_LR):
		point_side_a = $MainBall/POSHLeft
		point_side_b = $MainBall/POSHRight
	else:
		point_side_a = $MainBall/POSVTop
		point_side_b = $MainBall/POSVBottom
