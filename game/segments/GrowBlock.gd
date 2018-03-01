extends Sprite


signal reached_wall(wall)


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#only wall has aea as static body
func body_is_wall( body ):
	if (body is Sprite):
		return body.has_node("Area") and body.get_node("Area") is StaticBody2D
	else:
		 return false


func collided_body( body ):
	if (body_is_wall(body)):
		emit_signal("reached_wall", body)
