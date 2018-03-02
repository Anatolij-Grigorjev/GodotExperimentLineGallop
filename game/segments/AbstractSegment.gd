extends Sprite

var unit_size = Vector2()

func _ready():

	unit_size = self.texture.get_size()
	pass
	
func change_texture(texture):
	self.texture = texture
	unit_size = self.texture.get_size()
	
	
	
#function to create a segment that will be treated as a wall
#this is why a wall prefab is used with separate texture to set
static func create_segment_at_points(parent, packed_wall, point_from, point_to, direction, unit_size):
	
	var mid_point = (point_from + point_to) / 2
	var diff_v = point_from - point_to
	var diff = max(abs(diff_v.x), abs(diff_v.y))
	var units = int(round(max(diff / unit_size, diff / unit_size)))
	
	var offset = direction * unit_size
	
	var line_parent = Node2D.new()
	parent.add_child(line_parent)
	line_parent.global_position = mid_point
	
	for idx in range(-units / 2, units / 2):
		
		var block = packed_wall.instance()
		line_parent.add_child(block)
		block.position = Vector2() + idx * offset
	
	#return created line
	return line_parent
	
	
	