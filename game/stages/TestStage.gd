extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	

	$Character.connect("wall_ready", self, "got_wall")
	
	pass
	
	
func got_wall(wall, is_horizontal):
	pass
