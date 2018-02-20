extends "../AbstractSegment.gd"


func _ready():
	._ready()
	pass


func resize_line(var width):
	
	.resize_line(width)
	#ensure collider covers exactly one last block
	$Area/Collider.shape.extents = unit_size
	#special case - if only 1 block, the area covers it
	if (width == 1):
		$Area.position = Vector2()
	#if many blocks, area goes on the last one
	else:
		#ensure collider area is at last block 
		#(should be 1/2 of one length + all others away from center)
		$Area.position = Vector2(line_width - 1 * unit_size.x + unit_size.x / 2, 0)
	
