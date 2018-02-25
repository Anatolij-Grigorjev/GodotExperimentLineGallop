extends "../AbstractSegment.gd"

#did the line connect with a wall
var done_growing = false

#is this segment actually a static wall
var is_wall = false

signal connected_wall(line, wall)

func _ready():
	._ready()
	
	done_growing = false
	is_wall = false
	pass


func resize_line(var width):
	
	.resize_line(width)
	#ensure collider covers exactly one last block
	$Area/Collider.shape.extents = unit_size / 2
	#special case - if only 1 block, the area covers it
	if (width == 1):
		$Area.position = Vector2()
	#if many blocks, area goes on the last one
	else:
		#ensure collider area is at last block 
		#(should be 1/2 of one length + all others away from center)
		$Area.position = Vector2((line_width - 1) * unit_size.x / 2, 0)
	

func body_is_wall(body):
	return body is StaticBody2D and body.get_parent() is preload("res://segments/stage_segment/StageSegment.gd")


func _on_Area_body_entered( body ):
	if (not is_wall):
		if (body_is_wall(body)):
			done_growing = true
			emit_signal("connected_wall", self, body)
		
		

	
