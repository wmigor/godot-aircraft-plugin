extends Node3D
class_name Motor

@export var max_rpm := 2900.0
@export var max_engine_power_hp := 360.0
@export var diameter := 2.4
@export var inertia := 10.0
@export var density := 1.2255

@onready var aircraft := get_parent() as Aircraft

const TO_KMPH = 3.6
const TO_RPM := 60.0 / TAU
const HP_TO_W := 745.7

var throttle := 1.0
var thrust := 0.0
var rpm := 0.0
var rps: float:
	get(): return rpm / 60.0


func _physics_process(delta: float) -> void:
	var forward := -aircraft.basis.z
	var velocity := aircraft.linear_velocity.dot(forward)
	var max_engine_power := max_engine_power_hp * HP_TO_W
	var engine_power := _get_engine_power()
	var j := velocity / (diameter * rps) if rps > 0.01 else velocity / diameter
	var required_power := _get_required_power(j)
	if throttle <= 0 and rpm < 500:
		required_power += max_engine_power * 0.1
	var angular_velocity := rpm / TO_RPM
	var torque := (engine_power - required_power) / angular_velocity if absf(angular_velocity) > 0.01 else (engine_power - required_power)
	rpm += torque / inertia * delta * TO_RPM
	if rpm < 0.0:
		rpm = 0.0
	thrust = _get_thrust(j)
	aircraft.apply_force(thrust * forward, global_position - aircraft.global_position)
	rotation.z += angular_velocity * delta
	print(int(rpm), '   ', thrust, '   ', torque)


func _get_engine_power() -> float:
	var max_engine_power := max_engine_power_hp * HP_TO_W
	if rpm > max_rpm:
		return throttle * lerpf(max_engine_power, 0.0, (rpm - max_rpm) / (max_rpm * 0.2))
	var min_engine_power := max_engine_power * 0.01
	var engine_power := throttle * minf(max_engine_power, maxf(min_engine_power, lerpf(min_engine_power, max_engine_power, rpm / max_rpm)))
	return throttle * engine_power


func _get_required_power(j: float) -> float:
	var x := j / 1.2
	var cp := 0.07 * (1.0 - x)
	return cp * density * pow(diameter, 5) * pow(rps, 3)


func _get_thrust(j: float) -> float:
	var x := j / 1.05
	var ct := 0.1 * (1.0 - x * x)
	return ct * density * pow(diameter, 4) * pow(rps, 2)
