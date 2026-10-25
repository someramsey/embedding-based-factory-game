class_name CardDeck
extends Control
signal card_pulled(card: BuildingDef)

@export var coverage := 0.7        
@export var visible_count := 5
@export var drop := 40.0           
@export var tilt := 0.1            
@export var min_scale := 0.7
@export var slop := 14.0           
@export var pull_angle_deg := 45.0 
@export var commit_distance := 160.0
@export var dock_distance := 120.0 
@export var card_template : PackedScene

enum Mode { IDLE, UNDECIDED, SCROLLING, PULLING }

var scroll := 0.0                 
var spacing := 150.0
var pull_offset := Vector2.ZERO
var dock := 0.0

var _mode := Mode.IDLE
var _press_pos := Vector2.ZERO
var _press_card: Control
var _pull_card: Control
var _tween: Tween

func _ready() -> void:
	for buildingDef in BuildingCatalogue.buildings:
		var card = card_template.instantiate();
		card.def = buildingDef
		add_child(card)

func set_docked(on: bool) -> void:
	create_tween().tween_property(self, "dock", dock_distance if on else 0.0, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _cards() -> Array[Control]:
	var out: Array[Control] = []
	for c in get_children():
		if c is Control and c.visible:
			out.append(c)
	return out

func _process(_delta: float) -> void:
	var cards := _cards()
	if cards.is_empty():
		return
	spacing = maxf(40.0, (coverage * size.x - cards[0].size.x) / float(visible_count - 1))
	for i in cards.size():
		var c := cards[i]
		var d := i - scroll
		var a := absf(d)
		var p := Vector2(
			size.x / 2.0 - c.size.x / 2.0 + d * spacing,
			size.y - c.size.y + a * a * drop + dock)
		if c == _pull_card:
			p += pull_offset
		c.position = p
		c.rotation = d * tilt
		c.scale = Vector2.ONE * clampf(1.0 - a * 0.15, min_scale, 1.0)
		c.z_index = 100 if c == _pull_card else -int(a * 10.0)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press(e.global_position)
		else:
			_release()
	elif e is InputEventMouseMotion and _mode != Mode.IDLE:
		_motion(e)

func _press(pos: Vector2) -> void:
	_mode = Mode.UNDECIDED
	_press_pos = pos
	_press_card = _card_at(pos)
	if _tween:
		_tween.kill()

func _motion(e: InputEventMouseMotion) -> void:
	var delta := e.global_position - _press_pos
	if _mode == Mode.UNDECIDED:
		if delta.length() < slop:
			return
		var steep := -delta.y > absf(delta.x) * tan(deg_to_rad(pull_angle_deg))
		if _press_card and steep:
			_mode = Mode.PULLING
			_pull_card = _press_card
		else:
			_mode = Mode.SCROLLING
			_drag_scroll(delta.x) 
			return
	if _mode == Mode.SCROLLING:
		_drag_scroll(e.relative.x)
	elif _mode == Mode.PULLING:
		var up := maxf(0.0, -delta.y)
		pull_offset = Vector2(delta.x * 0.3, -up * 0.5) 
		if up >= commit_distance:
			_commit()

func _release() -> void:
	if _mode == Mode.SCROLLING:
		var v := -Input.get_last_mouse_velocity().x / spacing  # cards per second
		_snap(roundi(scroll + v * 0.12))
	elif _mode == Mode.UNDECIDED:
		_snap(roundi(scroll))
	elif _mode == Mode.PULLING:
		_spring_back()
	_mode = Mode.IDLE
	_press_card = null

func _commit() -> void:
	var card := _pull_card
	_mode = Mode.IDLE 
	_spring_back()
	card_pulled.emit(card.def)

func _spring_back() -> void:
	var t := create_tween()
	t.tween_property(self, "pull_offset", Vector2.ZERO, 0.15)
	t.finished.connect(func():
		if _mode != Mode.PULLING:
			_pull_card = null)

func _drag_scroll(px: float) -> void:
	scroll = clampf(scroll - px / spacing, -0.4, _cards().size() - 0.6)  

func _snap(i: int) -> void:
	i = clampi(i, 0, maxi(_cards().size() - 1, 0))
	_tween = create_tween()
	_tween.tween_property(self, "scroll", float(i), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _card_at(pos: Vector2) -> Control:
	var best: Control = null
	var best_d := INF
	var cards := _cards()
	for i in cards.size():
		var c := cards[i]
		var local := c.get_global_transform().affine_inverse() * pos
		if Rect2(Vector2.ZERO, c.size).has_point(local):
			var d := absf(i - scroll)
			if d < best_d:
				best_d = d
				best = c
	return best
