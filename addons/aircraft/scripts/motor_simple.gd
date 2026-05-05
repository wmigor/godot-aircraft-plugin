extends Motor
class_name MotorSimple

@export var peak_rpm := 2700.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var peak_power_hp := 160.0
@export var start_rpm := 500.0
@export_range(0.1, 0.9, 0.01) var peak_torque_rpm_ratio := 0.7
@export var throttle_curve_power := 0.75
@export var static_friction := 5.0
@export var viscosity_friction_factor := 0.01
@export var not_running_friction := 100.0

var _angle: float

var max_torque: float:
	get(): return peak_power_hp * HP_TO_W / peak_rpm * TO_RPM

var peak_friction: float:
	get(): return static_friction + viscosity_friction_factor * peak_rpm / TO_RPM


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_angle = wrapf(_angle + angular_velocity * delta, 0.0, TAU)


func _calculate_torque() -> float:
	var engine_torque := _get_engine_torque()
	var viscosity_friction := viscosity_friction_factor * angular_velocity
	var friction := static_friction + viscosity_friction
	if throttle <= 0.0 or not enabled or rpm < start_rpm:
		friction += _get_not_running_friction()
	return engine_torque - friction


func _get_not_running_friction() -> float:
	var friction := not_running_friction
	if rpm < start_rpm:
		friction *= max(10.0 * sin(_angle * 2.0), 0.0)
	return friction


func _get_engine_torque() -> float:
	if throttle <= 0 or not enabled:
		return 0.0
	if rpm >= start_rpm:
		return pow(throttle, throttle_curve_power) * _get_nominal_torque()
	var starter_torque := max_torque * 0.2 + static_friction + _get_not_running_friction()
	return starter_torque


func _get_nominal_torque() -> float:
	var peak_power := peak_power_hp * HP_TO_W
	var peak_av := peak_rpm / TO_RPM
	var n := rpm / peak_rpm
	var power_factor := get_power_factor(n, peak_torque_rpm_ratio)
	var power := (peak_power + peak_friction * peak_av) * power_factor
	return (power / angular_velocity) if angular_velocity > 1.0 else power


func get_power_factor(n: float, peak_torque_n: float) -> float:
	var t := peak_torque_n
	var b := 0.0
	var d := t / (3.0 * t * t - 3.0 * t)
	var c := (-1.0 - 3 * d) / 2.0
	var a := 1.0 - c - d
	var factor := a * n + b * n * n + c * n * n * n + d * n * n * n * n
	return factor


func get_power_factor2(n: float, peak_torque_n: float) -> float:
	var t := peak_torque_n
	var c := -1.0 / (2.0 * t - 2)
	var b := 2.0 * c * t
	var a := 1.0 - b + c
	var factor := a * n + b * n * n - c * n * n * n
	return factor


func get_power_factor3(n: float, start_n: float, start_power: float) -> float:
	var t := start_n
	var s := start_power
	var c := (s + t * t - 2.0 * t) / (2.0 * t * t - t * t * t - t)
	var b := 2.0 * c - 1.0
	var a := 1.0 - b + c
	var factor := a * n + b * n * n - c * n * n * n
	return factor
