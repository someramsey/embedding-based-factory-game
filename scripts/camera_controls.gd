extends Camera2D

@export var min_zoom := 0.5
@export var max_zoom := 1.0
@export var wheel_zoom_factor := 1.1
@export var build_mode := false

@export var pan_smoothing := 18.0
@export var pan_friction := 6.0
@export var max_pan_velocity := 4000.0
@export var drag_threshold := 8.0

@export var world_bounds_min := Vector2.ZERO
@export var world_bounds_max := Vector2(4096, 4096)

var _touches := {}
var _pressed := false
var _dragging := false
var _drag_distance := 0.0
var _frame_delta := Vector2.ZERO
var _target_position: Vector2
var _velocity := Vector2.ZERO

func _ready() -> void:
	_target_position = position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		if _pressed and _touches.is_empty():
			_drag(event.relative)
	elif event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)

func _process(delta: float) -> void:
	if _pressed:
		if _dragging:
			var world_delta := -_frame_delta / zoom.x
			_target_position += world_delta
			var instant := (world_delta / maxf(delta, 1e-4)).limit_length(max_pan_velocity)
			_velocity = _velocity.lerp(instant, 0.35)
		_frame_delta = Vector2.ZERO
	else:
		_target_position += _velocity * delta
		_velocity = _velocity.lerp(Vector2.ZERO, clampf(pan_friction * delta, 0.0, 1.0))

	_target_position = _clamped(_target_position)
	position = position.lerp(_target_position, 1.0 - exp(-pan_smoothing * delta))


func _on_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if not _touches.is_empty():
				return
			if event.pressed and not build_mode:
				_begin_pan()
			elif not event.pressed:
				_end_pan()
		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_begin_pan()
			else:
				_end_pan()
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_zoom_at(event.position, wheel_zoom_factor)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_zoom_at(event.position, 1.0 / wheel_zoom_factor)

func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
		if _touches.size() == 1 and not build_mode:
			_begin_pan()
		elif _touches.size() == 2:
			_pressed = true
			_dragging = true
	else:
		_touches.erase(event.index)
		if _touches.is_empty():
			_end_pan()

func _on_screen_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return

	if _touches.size() == 1:
		_touches[event.index] = event.position
		if _pressed:
			_drag(event.relative)
	elif _touches.size() == 2:
		var old_pts := _touches.values()
		var old_mid: Vector2 = (old_pts[0] + old_pts[1]) * 0.5
		var old_dist: float = old_pts[0].distance_to(old_pts[1])

		_touches[event.index] = event.position

		var new_pts := _touches.values()
		var new_mid: Vector2 = (new_pts[0] + new_pts[1]) * 0.5
		var new_dist: float = new_pts[0].distance_to(new_pts[1])

		if old_dist > 1.0:
			_zoom_at(new_mid, new_dist / old_dist)
		_frame_delta += new_mid - old_mid


func _begin_pan() -> void:
	_pressed = true
	_dragging = false
	_drag_distance = 0.0
	_frame_delta = Vector2.ZERO
	_velocity = Vector2.ZERO


func _end_pan() -> void:
	if not _dragging:
		_velocity = Vector2.ZERO
	_pressed = false
	_dragging = false

func _drag(screen_delta: Vector2) -> void:
	_drag_distance += screen_delta.length()
	if not _dragging and _drag_distance >= drag_threshold:
		_dragging = true
		return
	if _dragging:
		_frame_delta += screen_delta


func _zoom_at(screen_point: Vector2, factor: float) -> void:
	var half_viewport := get_viewport_rect().size * 0.5
	var world_before := position + (screen_point - half_viewport) / zoom.x

	var z := clampf(zoom.x * factor, _effective_min_zoom(), max_zoom)
	zoom = Vector2(z, z)

	var world_after := position + (screen_point - half_viewport) / zoom.x
	var shift := world_before - world_after
	position += shift
	_target_position += shift
	_target_position = _clamped(_target_position)
	_velocity = Vector2.ZERO


func _effective_min_zoom() -> float:
	var vp := get_viewport_rect().size
	var span := world_bounds_max - world_bounds_min
	return maxf(min_zoom, maxf(vp.x / span.x, vp.y / span.y))


func _clamped(p: Vector2) -> Vector2:
	var half_view := get_viewport_rect().size / zoom * 0.5
	var low := world_bounds_min + half_view
	var high := world_bounds_max - half_view
	return Vector2(
		clampf(p.x, low.x, maxf(low.x, high.x)),
		clampf(p.y, low.y, maxf(low.y, high.y))
	)
