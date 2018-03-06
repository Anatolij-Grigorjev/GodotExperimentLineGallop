extends Node


enum ELEMENTS {
	
	FIRE = 0,
	ICE = 1,
	WIND = 2
	
}

var ELEM_COLORS = {
	FIRE: Color(1.0, 0.145, 0.145),
	ICE: Color(0.093, 0.878, 0.839),
	WIND: Color(0.019, 0.988, 0.196)
}

var COLOR_TRANSPEARANT = Color(1.0, 1.0, 1.0, 0.0)


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func eq_with_tolerance(var val1, var val2, var tolerance = val1 * 0.05):
	return abs(val1 - val2) <= tolerance
	
