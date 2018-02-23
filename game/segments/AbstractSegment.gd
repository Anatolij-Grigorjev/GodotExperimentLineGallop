extends Sprite


export (int) var line_width = 3

var unit_size = Vector2()

func _ready():

	unit_size = self.texture.get_size()
	self.region_enabled = true
	resize_line(line_width)
	
	pass
	
func resize_line(var width):
	
	line_width = width
	self.region_rect = Rect2(Vector2(), Vector2(unit_size.x * width, unit_size.y))
	
func create_segment_at_points(parent, point_from, point_to):
	
	var mid_point = (point_from + point_to) / 2
	var diff = abs(point_from - point_to)
	var units = max(diff.x / unit_size.x, diff.y / unit_size.y)
	
	var segment = create_add_segment(parent, units)
	segment.position = mid_point


func create_add_segment(parent, units):
	#TODO: implemnet in subclasses
	breakpoint
	
	
	
	