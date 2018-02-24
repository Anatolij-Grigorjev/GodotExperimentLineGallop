extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	
	$Character.connect("wall_created", self, "wall_created")
	
	
	pass



func wall_created(wall):
	breakpoint
	pass
