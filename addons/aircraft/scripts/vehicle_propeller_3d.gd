@tool
@abstract
extends VehicleThruster3D
class_name VehiclePropeller3D

@export var radius := 0.953
@export var apply_gyroscopic_torque: bool
@export var feather: bool
## Target RPM of constant-speed propeller
@export var constant_speed_rpm := 0.0

var _thrust_factor: float
var _power_required_factor: float
var _pitch := 0.5
var _debug_view: Node3D

var reverse: float:
	get: return _motor != null && _motor.reverse


func _ready() -> void:
	var motors := find_children("*", "PistonMotor")
	motor = motors[0] if len(motors) > 0 else null


func _physics_process(delta: float) -> void:
	_process_pitch(delta)


func calculate() -> void:
	if _body == null or not visible or Engine.is_editor_hint():
		return
	var forward := -_body.basis.z
	var velocity := _body.linear_velocity.dot(forward)
	_calculate(velocity, forward)
	var force := thrust * forward
	_body.apply_force(force, global_position - _body.global_position)
	if apply_gyroscopic_torque:
		_apply_gyroscopic_torque(forward)


func _calculate(velocity: float, forward: Vector3) -> void:
	if velocity < 0.0:
		velocity = 0.0
	_calculate_factors(velocity)
	var diameter := radius * 2
	thrust = _thrust_factor * pow(rps, 2.0) * pow(diameter, 4.0) * density
	var power_required := _power_required_factor * pow(maxf(0.01, absf(rps)), 3.0) * pow(diameter, 5.0) * density
	var torque_required := (power_required / angular_velocity) if absf(angular_velocity) > 0.1 else power_required
	torque = torque_required
	wind_induced = -forward * _calc_wind_induced(velocity, density)
	if feather:
		thrust = 0.0


@abstract
func _calculate_factors(velocity: float) -> void


func _apply_gyroscopic_torque(forward: Vector3) -> void:
	var direction := -1.0 if reverse else 1.0
	var gyro_torque := direction * forward * angular_velocity * inertia
	_body.apply_torque(gyro_torque.cross(_body.angular_velocity))


func _process_pitch(delta: float) -> void:
	if constant_speed_rpm <= 0.0:
		return
	var rpm_delta := constant_speed_rpm - rpm
	_pitch = clampf(_pitch + (rpm_delta) * delta * delta, 0.5, 0.8)


func _calc_wind_induced(velocity: float, density: float) -> float:
	if feather:
		return 0.0
	var area := radius * radius * PI
	var vel2sum := velocity * absf(velocity) + 2.0 * thrust / (density * area)
	if vel2sum > 0.0:
		return 0.5 * (-velocity + sqrt(vel2sum))
	return 0.5 * (-velocity - sqrt(-vel2sum))


func get_radius() -> float:
	return radius


func toggle_mode() -> void:
	feather = not feather


var VehiclePropeller3DDebugView := preload("uid://bi5f3pjnf633x")
func _update_debug_view() -> void:
	if _debug_view != null:
		_debug_view.queue_free()
		_debug_view = null
	if debug:
		_debug_view = VehiclePropeller3DDebugView.new()
		add_child(_debug_view)
