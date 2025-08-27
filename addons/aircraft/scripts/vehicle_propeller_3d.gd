@tool
extends VehicleThruster3D
class_name VehiclePropeller3D

@export var max_rpm := 2900.0
@export var max_engine_power_hp := 360.0
@export var velocity_max_kmph := 300.0
@export var diameter := 2.4
@export var inertia := 10.0
@export var density := 1.2255
@export_range(0.0, 1.0) var efficiency := 0.85
@export var auto_rpm := false

var _lambda_peak: float
var _beta: float
var _base_j0: float
var _f0: float
var _pitch := 0.5
var _debug_view: Node3D


func  _ready() -> void:
	var velocity := velocity_max_kmph / TO_KMPH
	var angular_velocity := max_rpm / TO_RPM
	var power := max_engine_power_hp * HP_TO_W
	var radius := diameter * 0.5
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
	var engine_torque := throttle * _get_engine_torque()
	if rpm < max_rpm * 0.1:
		engine_torque = inertia * 10.0 if throttle > 0.0 else 0.0
	if auto_rpm:
		_process_pitch(delta)
	_calculate(velocity)
	_body.apply_force(thrust * forward, global_position - _body.global_position)
	angular_velocity += (engine_torque - torque) / inertia * delta


func _process_pitch(delta: float) -> void:
	var min_rpm := max_rpm * 0.1
	var target_rpm := lerpf(min_rpm, max_rpm, throttle)
	var rpm_delta := target_rpm - rpm
	_pitch = clampf(_pitch + (rpm_delta) * delta * delta, 0.3, 0.7)


func _calculate(velocity: float) -> void:
	if velocity < 0.0:
		velocity = 0.0

	var radius := diameter * 0.5
	var omega := angular_velocity
	if omega < 0.1:
		omega = 0.1

	var j0 := _base_j0 * pow(2.0, 2.0 - 4.0 * _pitch) if _pitch != 0.5 else _base_j0
	var tipspd := radius * omega
	var v2 := velocity * velocity + tipspd * tipspd

	var j := velocity / omega
	var lambda := j / j0

	if lambda == 1.0:
		lambda = 0.9999

	var l4 := lambda * lambda
	l4 = l4 * l4
	var gamma := (efficiency * _beta / j0) * (1 - l4)
	var tc := (1.0 - lambda) / (1.0 - _lambda_peak)
	thrust = 0.5 * density * v2 * _f0 * tc
	torque = thrust / gamma
	if lambda > 1.0:
		var tau0 := (0.25 * j0) / (efficiency * _beta * (1 - _lambda_peak))
		var lambda_wm = 1.2
		torque = tau0 - tau0 * (lambda - 1) / (lambda_wm - 1)
		torque *= 0.5 * density * v2 * _f0


func _get_engine_torque() -> float:
	var max_torque := max_engine_power_hp * HP_TO_W / max_rpm * TO_RPM
	var x := rpm / max_rpm
	if x > 1.0:
		return max_torque
	if x < 0.2:
		x /= 0.2
		return lerpf(0.0, max_torque * 0.4, x)
	if x < 0.5:
		x = (x - 0.2) / 0.5
		return lerpf(max_torque * 0.4, max_torque * 0.98, x)
	x = (x - 0.5) / 0.5
	return lerpf(max_torque * 0.98, max_torque, x)


var VehiclePropeller3DDebugView := preload("uid://bi5f3pjnf633x")
func _update_debug_view() -> void:
	if _debug_view != null:
		_debug_view.queue_free()
		_debug_view = null
	if debug:
		_debug_view = VehiclePropeller3DDebugView.new()
		add_child(_debug_view)
