extends "../AbstractSegment.gd"


func _ready():

	._ready()
	
	pass
	
func resize_line(var width):
	
	.resize_line(width)
	#ensure collider covers entire segment length
	$Area/Collider.shape.extents = region_rect.size / 2
	
	


