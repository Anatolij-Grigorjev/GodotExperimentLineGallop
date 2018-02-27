extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	
	$Character.connect("wall_created", self, "wall_created")
	
	print("RIDs:")
	for segment in $Segments.get_children():
		print("%s rid: %s" % [segment, segment.get_node("Area/Collider").shape.get_rid().get_id()])
	
	pass



func wall_created(wall):
	wall.show_behind_parent = true
	print("new RID: %s" % RID(wall).get_id())
	print("wall RID: %s" % wall.get_node("Area/Collider").shape.get_rid().get_id())
	pass
