@tool
extends VehiclePropeller3D
class_name VehiclePropellerSimple3D

## Velocity at maximum RPM
@export_custom(PROPERTY_HINT_NONE, "suffix:km/h") var max_rpm_velocity := 300.0
## Propeller efficiency
@export_range(0.0, 1.0) var efficiency := 0.85
## Constant-speed propeller
@export var constant_speed := false## takeoff rpm
@export var takeoff_rpm := 0.0
## takeoff power
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var takeoff_power := 0.0

var _lambda_peak: float
var _beta: float
var _base_j0: float
var _f0: float
var _tc_takeoff := 0.0


func  _ready() -> void:
	super._ready()
	var velocity := max_rpm_velocity / TO_KMPH
	var angular_velocity := max_engine_rpm / TO_RPM
	var power := max_engine_power * HP_TO_W
	var v2 := pow(velocity, 2) + pow(radius * angular_velocity, 2)
	_lambda_peak = pow(5.0, -1.0 / 4.0)
	_beta = 1.0 / (pow(5.0, -1.0 / 4.0) - pow(5.0, -5.0 / 4.0))
	_base_j0 = velocity / (angular_velocity * _lambda_peak)
	_f0 = 2.0 * efficiency * power / (density * velocity * v2)
	_setup_takeoff()


func _setup_takeoff() -> void:
	if takeoff_rpm <= 0.0 or takeoff_power <= 0.0:
		_tc_takeoff = 0.0
		return
	var takeoff_av := takeoff_rpm / TO_RPM
	var v2 := radius * takeoff_av * radius * takeoff_av
	var gamma := efficiency * _beta / _base_j0
	var takeoff_torque := takeoff_power * HP_TO_W / takeoff_av
	_tc_takeoff = takeoff_torque * gamma / (0.5 * density * v2 * _f0)



func _calculate_factors(velocity: float) -> void:
	if velocity < 0.0:
		velocity = 0.0

	var j0 := _base_j0 * pow(2.0, 2.0 - 4.0 * _pitch) if _pitch != 0.5 else _base_j0
	var tipspd := radius * angular_velocity
	var v2 := velocity * velocity + tipspd * tipspd
	var j := velocity / angular_velocity if absf(angular_velocity) > 0.1 else velocity / 0.1
	var lambda := j / j0
	var l4 := lambda * lambda * lambda * lambda
	var gamma := (efficiency * _beta / j0) * (1.0 - l4)
	var tc := (1.0 - lambda) / (1.0 - _lambda_peak)
	if _tc_takeoff > 0.0 and tc > _tc_takeoff:
		tc = _tc_takeoff
	var thrust_required := 0.5 * density * v2 * _f0 * tc
	var torque_required := thrust_required / gamma
	if lambda > 1.0 and not feather:
		var tau0 := (0.25 * j0) / (efficiency * _beta * (1.0 - _lambda_peak))
		var lambda_wm = 1.2
		torque_required = tau0 - tau0 * (lambda - 1.0) / (lambda_wm - 1.0)
		torque_required *= 0.5 * density * v2 * _f0
	var power_required := torque_required * angular_velocity
	var diameter := radius * 2.0
	var safe_rps := maxf(0.01, absf(rps))
	_thrust_factor = thrust_required / (pow(safe_rps, 2.0) * pow(diameter, 4.0) * density)
	_power_required_factor = power_required / (pow(safe_rps, 3.0) * pow(diameter, 5.0) * density)
