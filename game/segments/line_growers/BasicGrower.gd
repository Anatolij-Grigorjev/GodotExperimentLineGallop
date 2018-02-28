extends Node2D


export(PackedScene) var tail_blocks
export(Vector2) var block_size

var last_block_pos



func _ready():
	
	block_size = $Head.texture.get_size().x
	last_block_pos = $Head.position
	
	pass
	
func add_block():
	add_blocks(1)

#adds amount blocks to tail of grower
func add_blocks(amount):
	for idx in range(0, amount):
		var block = tail_blocks.instance()
		add_child(block)
		block.position = last_block_pos.x - block_size
		last_block_pos = block.position
