extends "../AbstractSegment.gd"


func _ready():

	._ready()
	
	pass
	
func resize_line(var width):
	
	.resize_line(width)
	
	#ensure collider covers entire segment length
	$Area.position = Vector2()
	$Area/Collider.shape.extents = self.region_rect.size / 2
	
	


