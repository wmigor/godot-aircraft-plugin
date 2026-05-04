extends Motor
class_name MotorSimple

@export var peak_rpm := 2700.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var peak_power_hp := 160.0
@export var torque_curve_power := 0.185
@export var throttle_curve_power := 0.5
@export var static_friction := 50.0
@export var viscosity_friction_factor := 0.1
@export var back_torque_factor := 0.1

var idle_rpm: float:
	get(): return peak_rpm * 0.2

var max_torque: float:
	get(): return peak_power_hp * HP_TO_W / peak_rpm * TO_RPM

var peak_friction: float:
	get(): return static_friction + viscosity_friction_factor * peak_rpm / TO_RPM


func _calculate_torque() -> float:
	var engine_torque := _get_engine_torque()
	var back_torque := _get_back_torque()
	var viscosity_friction := viscosity_friction_factor * angular_velocity
	return engine_torque - back_torque - static_friction - viscosity_friction


func _get_back_torque() -> float:
	var rpm_normalized := maxf(0.0, rpm) / peak_rpm
	return max_torque * (1.0 - (throttle if enabled else 0.0)) * rpm_normalized * back_torque_factor


func _get_engine_torque() -> float:
	if throttle <= 0 or not enabled:
		return 0.0
	if rpm >= idle_rpm:
		return pow(throttle, throttle_curve_power) * _get_nominal_engine_torque()
	var starter_torque := max_torque * 0.2 + static_friction
	return starter_torque


func _get_nominal_engine_torque() -> float:
	var rpm_normalized := maxf(0.0, rpm) / peak_rpm
	if rpm_normalized < 1.0:
		return (max_torque + peak_friction) * pow(rpm_normalized, torque_curve_power)
	var phase := (rpm_normalized - 1.0) / (1.2 - 1.0)
	var fade := 0.5 + 0.5 * cos(PI * phase)
	return (max_torque + peak_friction) * pow(rpm_normalized, torque_curve_power) * fade
