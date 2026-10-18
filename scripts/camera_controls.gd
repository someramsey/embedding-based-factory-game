extends Camera2D

@export var world_bounds_min : Vector2
@export var world_bounds_max : Vector2
@export var min_zoom := 0.5
@export var max_zoom := 3.0
@export var wheel_zoom_factor := 1.1

@export var build_mode := false


@export var pan_smoothing := 18.0      
@export var pan_friction := 6.0        
@export var max_pan_velocity := 4000.0 

var _touches := {}
var _mouse_panning := false

var _target_position : Vector2
var _pan_velocity := Vector2.ZERO
var _last_pan_velocity := Vector2.ZERO


func _ready() -> void:
	_target_position = position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		if _mouse_panning and _touches.is_empty():
			_pan_by_screen(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


func _process(delta: float) -> void:
	if not _mouse_panning and _touches.is_empty():
		# apply inertia
		_target_position += _pan_velocity * delta
		_pan_velocity = _pan_velocity.lerp(Vector2.ZERO, clampf(pan_friction * delta, 0.0, 1.0))

	_target_position = _clamped(_target_position)
	position = position.lerp(_target_position, 1.0 - exp(-pan_smoothing * delta))


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if _mouse_panning and not event.pressed:
				_pan_velocity = _last_pan_velocity
			_mouse_panning = event.pressed and not build_mode
		MOUSE_BUTTON_MIDDLE:
			if _mouse_panning and not event.pressed:
				_pan_velocity = _last_pan_velocity
			_mouse_panning = event.pressed
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_zoom_at(event.position, wheel_zoom_factor)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_zoom_at(event.position, 1.0 / wheel_zoom_factor)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return

	if _touches.size() == 1:
		_touches[event.index] = event.position
		if not build_mode:
			_pan_by_screen(event.relative)
	elif _touches.size() == 2:
		var old_points := _touches.values()
		var old_mid: Vector2 = (old_points[0] + old_points[1]) * 0.5
		var old_dist: float = old_points[0].distance_to(old_points[1])

		_touches[event.index] = event.position

		var new_points := _touches.values()
		var new_mid: Vector2 = (new_points[0] + new_points[1]) * 0.5
		var new_dist: float = new_points[0].distance_to(new_points[1])

		if old_dist > 1.0:
			_zoom_at(new_mid, new_dist / old_dist)
		_pan_by_screen(new_mid - old_mid)


func _pan_by_screen(screen_delta: Vector2) -> void:
	var world_delta := screen_delta / zoom.x
	_target_position -= world_delta
	_target_position = _clamped(_target_position)

	var instant_velocity := -world_delta / maxf(get_process_delta_time(), 1e-4)
	_last_pan_velocity = instant_velocity.limit_length(max_pan_velocity)
	_pan_velocity = _pan_velocity.lerp(_last_pan_velocity, 0.25)


func _zoom_at(screen_point: Vector2, factor: float) -> void:
	var half_viewport := get_viewport_rect().size * 0.5
	var world_before := position + (screen_point - half_viewport) / zoom.x
	
	var effective_min_zoom := _effective_min_zoom();
	
	zoom = Vector2(
		clampf(zoom.x * factor, effective_min_zoom, max_zoom),
		clampf(zoom.y * factor, effective_min_zoom, max_zoom)
	)

	var world_after := position + (screen_point - half_viewport) / zoom.x
	var shift := world_before - world_after
	position += shift
	_target_position += shift
	_target_position = _clamped(_target_position)
	_pan_velocity = Vector2.ZERO


func _effective_min_zoom() -> float:
	var viewport_size := get_viewport_rect().size
	var fit := maxf(viewport_size.x / world_bounds_max.x, viewport_size.y / world_bounds_max.y)
	return maxf(min_zoom, fit)


func _clamp_to_bounds() -> void:
	position = _clamped(position)
	_target_position = _clamped(_target_position)


func _clamped(p: Vector2) -> Vector2:
	var half_view := get_viewport_rect().size / zoom * 0.5
	var low := world_bounds_min + half_view
	var high := world_bounds_max - half_view
	
	return Vector2(
		clampf(p.x, low.x, maxf(low.x, high.x)),
		clampf(p.y, low.y, maxf(low.y, high.y))
	)
