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
	
static func create_segment_at_points(parent, packed_line, point_from, point_to):
	
	var mid_point = (point_from + point_to) / 2
	var diff = abs(point_from - point_to)
	var segment = create_add_segment(parent, packed_line)
	segment.position = mid_point
	
	var units = max(diff.x / segment.unit_size.x, diff.y / segment.unit_size.y)
	var line_area = segment.get_node("Area")
	line_area.position = segment.position
	line_area.get_node("Collider").shape.extents = segment.unit_size * units
	segment.resize_line(units)
	
	#return created line
	return segment


static func create_add_segment(parent, packed_line):
	
	var line = packed_line.instance()
	parent.add_child(line)
	line.is_wall = true
	
	return line
	
	
	