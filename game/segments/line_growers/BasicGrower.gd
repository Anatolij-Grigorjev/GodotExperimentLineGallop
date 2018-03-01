extends Node2D


export(PackedScene) var tail_blocks
export(float) var block_size

var last_block_pos

var done_growing

signal grower_done(grower, wall)

var at_wall_global_pos = null

func _ready():
	
	block_size = $Head.texture.get_size().x
	last_block_pos = $Head.position
	done_growing = false
	
	$Head.connect("reached_wall", self, "head_reached_wall")
	
	pass
	

func head_reached_wall(wall):
	done_growing = true
	at_wall_global_pos = $Head.global_position
	
	emit_signal("grower_done", self, wall)
	
	
	
func add_block():
	add_blocks(1)

#adds amount blocks to tail of grower
func add_blocks(amount):
	for idx in range(0, amount):
		var block = tail_blocks.instance()
		add_child(block)
		block.position = Vector2(last_block_pos.x - block_size, last_block_pos.y)
		last_block_pos = block.position
