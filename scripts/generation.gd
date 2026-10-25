extends TileMapLayer

@export var size := Vector2i(256, 256)
@export var source_id := 0 
@export var variant_chance := 0.1

var variants: Array[Vector2i] = []

func _ready() -> void:
	for y in 6:
		if y != 0:
			variants.append(Vector2i(0, y))

	var rng := RandomNumberGenerator.new()
	clear()
	for x in size.x:
		for y in size.y:
			var atlas := Vector2i.ZERO
			if rng.randf() < variant_chance:
				atlas = variants[rng.randi() % variants.size()]
			set_cell(Vector2i(x, y), source_id, atlas)
