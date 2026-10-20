@tool
class_name ClipWidthContainer
extends Container

func _init() -> void:
	clip_contents = true
	size_flags_horizontal = SIZE_SHRINK_BEGIN
	size_flags_vertical = SIZE_EXPAND_FILL

func _get_minimum_size() -> Vector2:
	var w := 0.0
	for child in get_children():
		if child is Control and child.visible:
			w = maxf(w, child.get_combined_minimum_size().x)
	return Vector2(w, 0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		for child in get_children():
			if child is Control and child.visible:
				var h : float = child.get_combined_minimum_size().y
				fit_child_in_rect(child, Rect2(0, 0, size.x, h))
