extends Motor
class_name MotorSimple

@export var peak_rpm := 2700.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var peak_power_hp := 160.0
@export var static_friction := 5.0
@export var dynamic_friction_factor := 0.1
@export var back_torque_factor := 0.0

var idle_rpm: float:
	get(): return peak_rpm * 0.2

var max_torque: float:
	get(): return peak_power_hp * HP_TO_W / peak_rpm * TO_RPM

var peak_friction: float:
	get: return static_friction + dynamic_friction_factor * peak_rpm / TO_RPM


func _calculate_torque() -> float:
	var engine_torque := _get_engine_torque()
	var friction_torque := static_friction
	var dynamic_friction := angular_velocity * dynamic_friction_factor
	var back_torque := back_torque_factor * max_torque * (1.0 - (throttle if enabled else 0.0))
	return engine_torque - static_friction - dynamic_friction - back_torque

func _get_engine_torque() -> float:
	if throttle <= 0 or not enabled:
		return 0.0
	if rpm >= idle_rpm:
		return throttle * _get_nominal_engine_torque()
	var starter_torque := max_torque * 0.2
	return starter_torque


func _get_nominal_engine_torque() -> float:
	if rpm > peak_rpm:
		var x := clampf((rpm - peak_rpm) / (peak_rpm * 0.25), 0.0, 1.0)
		return lerpf(max_torque + peak_friction, 0.0, x * x * (3.0 - 2.0 * x))
	var x := 1.0 - rpm / peak_rpm
	x = 1.0 - x * x * x * x
	return lerpf(0.0, max_torque + peak_friction, x)
