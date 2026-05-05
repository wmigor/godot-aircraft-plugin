extends Motor
class_name MotorSimple

@export var peak_rpm := 2700.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var peak_power_hp := 160.0
@export var start_rpm := 500.0
@export_range(0.01, 0.8, 0.01) var start_power_ratio := 0.1
@export var throttle_curve_power := 0.5
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
	var t := start_rpm / peak_rpm
	var s := peak_power_hp * start_power_ratio / peak_power_hp
	var leiderman_power_factor := get_leiderman_power_factor(n, t, s)
	var power := (peak_power + peak_friction * peak_av) * leiderman_power_factor
	return (power / angular_velocity) if angular_velocity > 1.0 else power


func get_leiderman_power_factor(n: float, t: float, s: float) -> float:
	var c := (s + t * t - 2.0 * t) / (2.0 * t * t - t * t * t - t)
	var b := 2.0 * c - 1.0
	var a := 1.0 - b + c
	#print("a: {0}, b: {1}, c: {2}, {3}, {4}".format([a, b, c, a + b - c, a + 2 * b - 3 * c]))
	var factor := a * n + b * n * n - c * n * n * n
	return factor
