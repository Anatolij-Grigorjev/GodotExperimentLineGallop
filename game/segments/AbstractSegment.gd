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
	var diff_v = point_from - point_to
	var diff = max(abs(diff_v.x), abs(diff_v.y))
	var segment = create_add_segment(parent, packed_line)
	segment.global_position = mid_point
	
	var units = int(round(max(diff / segment.unit_size.x, diff / segment.unit_size.y)))
	segment.resize_line(units)
	var line_area = segment.get_node("Area")
	line_area.position = segment.position
	line_area.get_node("Collider").shape.extents = (segment.unit_size / 2) * units
	
	#return created line
	return segment


static func create_add_segment(parent, packed_line):
	
	var line = packed_line.instance()
	parent.add_child(line)
	line.is_wall = true
	
	return line
	
	
	