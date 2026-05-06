@tool
extends VehiclePropeller3D
class_name VehiclePropellerSimple3D

@export var max_engine_rpm := 2700.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var max_engine_power := 160.0
## Velocity at maximum RPM
@export_custom(PROPERTY_HINT_NONE, "suffix:km/h") var max_rpm_velocity := 300.0
## Propeller efficiency
@export_range(0.0, 1.0) var efficiency := 0.85
## takeoff rpm
@export var takeoff_rpm := 0.0
## takeoff power
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var takeoff_power := 0.0

var _lambda_peak: float
var _beta: float
var _base_j0: float
var _f0: float
var _tc_takeoff := 0.0


func _ready() -> void:
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

	var cruise_velocity := max_rpm_velocity / Motor.TO_KMPH
	var cruise_rps := max_engine_rpm / 60.0
	var diameter := 2.0 * radius
	var cruise_power := max_engine_power * HP_TO_W
	var cruise_j := cruise_velocity / (cruise_rps * diameter)
	var j0 := cruise_j * 2.0
	var cruise_cp := cruise_power / (density * pow(cruise_rps, 3) * pow(diameter, 5))
	var cruise_ct := efficiency * cruise_cp / cruise_j
	var cp0 := 1.2 * cruise_cp
	var ct0 := 1.3 * cruise_ct
	var j := velocity / (maxf(1.0, rps) * diameter)
	var cp := cp0 - (cp0 - cruise_cp) * pow(j / cruise_j, 3)
	var eta := absf(4.0 * efficiency * j / cruise_j * (1.0 - j / j0))
	var ct := eta * cp / maxf(0.001, j)
	_power_required_factor = cp
	_thrust_factor = ct
