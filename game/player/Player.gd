extends KinematicBody2D

onready var G = get_node("/root/Globals")

const SPEED = 500
const FRICTION_COEF = 0.25

var prev_mouse_pos
var curr_mouse_pos

var curr_elem_idx = 0

func _ready():
	
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
	#set new color to core
	$MainBall/Core.modulate = G.ELEM_COLORS[idx]
	#set value to var
	curr_elem_idx = idx
