extends Node3D
class_name Motor

@export var max_rpm := 2900.0
@export var max_engine_power_hp := 360.0
@export var velocity_max_kmph := 300.0
@export var diameter := 2.4
@export var inertia := 10.0
@export var density := 1.2255
@export_range(0.0, 1.0) var efficiency := 0.85

@onready var aircraft := get_parent() as Aircraft

const TO_KMPH = 3.6
const TO_RPM := 60.0 / TAU
const HP_TO_W := 745.7

var throttle := 1.0
var thrust := 0.0
var torque := 0.0
var pitch := 0.5
var rpm := 0.0
var rps: float:
	get(): return rpm / 60.0

var _lambda_peak: float
var _beta: float
var _base_j0: float
var _f0: float


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
	var forward := -aircraft.basis.z
	var velocity := aircraft.linear_velocity.dot(forward)
	var engine_power := _get_engine_power()
	var angular_velocity := rpm / TO_RPM
	var engine_torque := 0.0
	if rpm < 200:
		engine_torque = inertia * 10 if throttle > 0 else 0.0
	else:
		engine_torque = engine_power / angular_velocity
	_calculate(velocity)
	aircraft.apply_force(thrust * forward, global_position - aircraft.global_position)
	angular_velocity += (engine_torque - torque) / inertia * delta
	rpm = angular_velocity * TO_RPM
	rotation.z += angular_velocity * delta


func _calculate(velocity: float) -> void:
	if velocity < 0.0:
		velocity = 0.0

	var radius := diameter * 0.5
	var omega := rpm / TO_RPM
	if omega < 0.1:
		omega = 0.1

	var j0 := _base_j0 * pow(2.0, 2.0 - 4.0 * pitch)
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


func _get_engine_power() -> float:
	var max_engine_power := max_engine_power_hp * HP_TO_W
	if rpm > max_rpm:
		return throttle * lerpf(max_engine_power, 0.0, (rpm - max_rpm) / (max_rpm * 0.2))
	var min_engine_power := max_engine_power * 0.01
	var engine_power := throttle * minf(max_engine_power, maxf(min_engine_power, lerpf(min_engine_power, max_engine_power, rpm / max_rpm)))
	return throttle * engine_power
