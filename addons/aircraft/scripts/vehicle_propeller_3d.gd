@tool
extends VehicleThruster3D
class_name VehiclePropeller3D

## Maximum RPM
@export var max_rpm := 2900.0
## Velocity at maximum RPM
@export_custom(PROPERTY_HINT_NONE, "suffix:km/h") var max_rpm_velocity := 300.0
## Peak engine power at maximum RPM
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var max_engine_power := 360.0
## Propeller intertia
@export var inertia := 10.0
## Propeller efficiency
@export_range(0.0, 1.0) var efficiency := 0.85
## Constant-speed propeller
@export var constant_speed := false
## Apply engine torque to body
@export var apply_engine_torque := false
## Apply gyroscopic torque to body
@export var apply_gyroscopic_torque := false
## Reverse rotation
@export var reverse := false
## Propeller radius
@export var radius := 1.0

var min_rpm: float:
	get(): return max_rpm * 0.2

var max_torque: float:
	get(): return max_engine_power * HP_TO_W / max_rpm * TO_RPM

var _lambda_peak: float
var _beta: float
var _base_j0: float
var _f0: float
var _pitch := 0.5
var _debug_view: Node3D


func  _ready() -> void:
	var velocity := max_rpm_velocity / TO_KMPH
	var angular_velocity := max_rpm / TO_RPM
	var power := max_engine_power * HP_TO_W
	var v2 := pow(velocity, 2) + pow(radius * angular_velocity, 2)
	_lambda_peak = pow(5.0, -1.0 / 4.0)
	_beta = 1.0 / (pow(5.0, -1.0 / 4.0) - pow(5.0, -5.0 / 4.0))
	_base_j0 = velocity / (angular_velocity * _lambda_peak)
	_f0 = 2.0 * efficiency * power / (density * velocity * v2)


func _physics_process(delta: float) -> void:
	if _body == null or not visible or Engine.is_editor_hint():
		return
	var forward := -_body.basis.z
	var velocity := _body.linear_velocity.dot(forward)
	var engine_torque := _get_engine_torque()
	if constant_speed:
		_process_pitch(delta)
	_calculate(velocity)
	var force := thrust * forward
	_body.apply_force(force, global_position - _body.global_position)
	if apply_engine_torque:
		_apply_engine_torque(forward)
	if apply_gyroscopic_torque:
		_apply_gyroscopic_torque(forward)
	angular_velocity += (engine_torque - torque) / inertia * delta
	if angular_velocity	 < 0.0:
		angular_velocity = 0.0


func _calculate(velocity: float) -> void:
	if velocity < 0.0:
		velocity = 0.0

	var angular_velocity := angular_velocity
	var j0 := _base_j0 * pow(2.0, 2.0 - 4.0 * _pitch) if _pitch != 0.5 else _base_j0
	var tipspd := radius * angular_velocity
	var v2 := velocity * velocity + tipspd * tipspd
	var j := velocity / angular_velocity if absf(angular_velocity) > 0.1 else velocity / 0.1
	var lambda := j / j0
	var l4 := lambda * lambda * lambda * lambda
	var gamma := (efficiency * _beta / j0) * (1.0 - l4)
	var tc := (1.0 - lambda) / (1.0 - _lambda_peak)
	thrust = 0.5 * density * v2 * _f0 * tc
	torque = thrust / gamma
	wind = _calc_wind(velocity, density)
	if lambda > 1.0:
		var tau0 := (0.25 * j0) / (efficiency * _beta * (1.0 - _lambda_peak))
		var lambda_wm = 1.2
		torque = tau0 - tau0 * (lambda - 1.0) / (lambda_wm - 1.0)
		torque *= 0.5 * density * v2 * _f0


func _get_engine_torque() -> float:
	if rpm >= min_rpm:
		return throttle * _get_nominal_engine_torque()
	var starter_torque := max_torque * 0.2
	if throttle > 0.0:
		return starter_torque
	return -starter_torque - angular_velocity * 0.1


func _get_nominal_engine_torque() -> float:
	if rpm > max_rpm:
		var x := clampf((rpm - max_rpm) / (max_rpm * 0.25), 0.0, 1.0)
		return lerpf(max_torque, 0.0, x * x * (3.0 - 2.0 * x))
	var x := 1.0 - rpm / max_rpm
	x = 1.0 - x * x * x * x
	return lerpf(0.0, max_torque, x)


func _apply_engine_torque(forward: Vector3) -> void:
	var direction := 1.0 if reverse else -1.0
	_body.apply_torque(direction * forward * torque)


func _apply_gyroscopic_torque(forward: Vector3) -> void:
	var direction := -1.0 if reverse else 1.0
	var gyro_torque := direction * forward * angular_velocity * inertia
	_body.apply_torque(gyro_torque.cross(_body.angular_velocity))


func _process_pitch(delta: float) -> void:
	var target_rpm := lerpf(min_rpm, max_rpm, throttle)
	var rpm_delta := target_rpm - rpm
	_pitch = clampf(_pitch + (rpm_delta) * delta * delta, 0.5, 0.7)


func _calc_wind(velocity: float, density: float) -> float:
	var area := radius * radius * PI
	var vel2sum := velocity * absf(velocity) + 2.0 * thrust / (density * area)
	if vel2sum > 0.0:
		return -velocity + sqrt(vel2sum)
	return -velocity - sqrt(-vel2sum)


var VehiclePropeller3DDebugView := preload("uid://bi5f3pjnf633x")
func _update_debug_view() -> void:
	if _debug_view != null:
		_debug_view.queue_free()
		_debug_view = null
	if debug:
		_debug_view = VehiclePropeller3DDebugView.new()
		add_child(_debug_view)
