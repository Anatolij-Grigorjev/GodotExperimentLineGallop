extends KinematicBody2D

onready var G = get_node("/root/Globals")


func _ready():
	
	position = get_global_mouse_position()
	
	
	pass

func _process(delta):
	#WTF?
	position = get_global_mouse_position()
	move_and_collide(Input.get_last_mouse_speed())
	
	pass
