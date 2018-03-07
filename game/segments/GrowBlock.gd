extends Sprite


signal reached_wall(wall)

var sent_signal = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#only wall has aea as static body
func body_is_wall( body ):
	return body is StaticBody2D


func collided_body( body ):
	if (body_is_wall(body) and not sent_signal):
		emit_signal("reached_wall", body)
		sent_signal = true
