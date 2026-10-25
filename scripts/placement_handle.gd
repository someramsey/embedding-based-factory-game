extends TextureRect

const GRID := 96.0

@onready var sprite: Sprite2D = get_parent()

var dragging := false
var drag_offset := Vector2.ZERO

func _ready() -> void:
	pivot_offset = size / 2.0

func _process(_delta: float) -> void:
	scale = Vector2.ONE / sprite.get_global_transform_with_canvas().get_scale()
	position = sprite.get_rect().end - size / 2.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			drag_offset = get_global_mouse_position() - sprite.global_position
	elif event is InputEventMouseMotion and dragging:
		var target := get_global_mouse_position() - drag_offset
		sprite.global_position = target.snapped(Vector2.ONE * GRID)
