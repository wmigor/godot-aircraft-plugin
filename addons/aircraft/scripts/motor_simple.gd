extends Motor
class_name MotorSimple

@export var peak_rpm := 2700.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var peak_power_hp := 160.0

var idle_rpm: float:
	get(): return peak_rpm * 0.2

var max_torque: float:
	get(): return peak_power_hp * HP_TO_W / peak_rpm * TO_RPM


func _calculate_torque() -> float:
	var starter_torque := max_torque * 0.2
	if throttle <= 0 or not enabled:
		return -starter_torque - angular_velocity * 0.1
	if rpm >= idle_rpm:
		return throttle * _get_nominal_engine_torque()
	return starter_torque


func _get_nominal_engine_torque() -> float:
	if rpm > peak_rpm:
		var x := clampf((rpm - peak_rpm) / (peak_rpm * 0.25), 0.0, 1.0)
		return lerpf(max_torque, 0.0, x * x * (3.0 - 2.0 * x))
	var x := 1.0 - rpm / peak_rpm
	x = 1.0 - x * x * x * x
	return lerpf(0.0, max_torque, x)
