extends MarginContainer

@export var scalar_strip: Control
@export var d1_strip: Control
@export var d2_strip: Control
@export var e1_strip: Control
@export var e2_strip: Control
@export var e3_strip: Control
@export var card_height: int

@export var stiffness := 180.0
@export var damping := 18.0
@export var max_speed := 6000.0


class Spring:
	var control: Control
	var target := 0.0
	var velocity := 0.0

	func _init(p_control: Control) -> void:
		control = p_control

	func update(dt: float, stiffness_val: float, damping_val: float, max_spd: float) -> void:
		var pos := control.position.y
		var accel := -stiffness_val * (pos - target) - damping_val * velocity
		velocity += accel * dt
		velocity = clampf(velocity, -max_spd, max_spd)
		control.position.y = pos + velocity * dt

var _scalar_spring: Spring
var _d1_spring: Spring
var _d2_spring: Spring
var _e1_spring: Spring
var _e2_spring: Spring
var _e3_spring: Spring


func _ready() -> void:
	_scalar_spring = Spring.new(scalar_strip)
	_d1_spring = Spring.new(d1_strip)
	_d2_spring = Spring.new(d2_strip)
	_e1_spring = Spring.new(e1_strip)
	_e2_spring = Spring.new(e2_strip)
	_e3_spring = Spring.new(e3_strip)
	
var moneh: int = 999;
func _process(dt: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		moneh+=10000
		set_money(moneh)

	_scalar_spring.update(dt, stiffness, damping, max_speed)
	_d1_spring.update(dt, stiffness, damping, max_speed)
	_d2_spring.update(dt, stiffness, damping, max_speed)
	_e1_spring.update(dt, stiffness, damping, max_speed)
	_e2_spring.update(dt, stiffness, damping, max_speed)
	_e3_spring.update(dt, stiffness, damping, max_speed)
	
func set_money(value: int) -> void:
	var tier := 0
	var scaled := float(value)
	while scaled >= 1000.0:
		scaled /= 1000.0
		tier += 1

	var scaled_value := int(scaled * 100.0 + 1e-6)

	_e3_spring.target = _get_target(scaled_value, 4)
	_e2_spring.target = _get_target(scaled_value, 3)
	_e1_spring.target = _get_target(scaled_value, 2)
	_d2_spring.target = _get_target(scaled_value, 1)
	_d1_spring.target = _get_target(scaled_value, 0)
	_scalar_spring.target = float(-card_height * (tier + 1))


func _get_target(n: int, place: int) -> float:
	var card_index := floori(n / pow(10.0, place)) % 10
	return float(-card_height * (card_index + 1))
