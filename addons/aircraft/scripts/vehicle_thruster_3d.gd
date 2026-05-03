@abstract
extends Node3D
class_name VehicleThruster3D

## Air density.
@export var density := 1.2255
## Gear
@export var gear := 1.0
## Inertia
@export var inertia := 6.5
## Enables debug view of thruster
@export var debug: bool:
	set(value):
		if value != debug:
			debug = value
			_update_debug_view()

const TO_RPM := 60.0 / TAU
const TO_KMPH = 3.6
const HP_TO_W := 745.7

var thrust := 0.0
var torque := 0.0
var angular_velocity := 0.0
var wind_induced: Vector3
var _motor: Motor
var _body: RigidBody3D

var rpm: float:
	get(): return angular_velocity * TO_RPM

var rps: float:
	get(): return rpm / 60.0


func _enter_tree() -> void:
	_motor = get_parent() as Motor
	_body = (_motor.get_parent() as RigidBody3D) if _motor != null else null


func _exit_tree() -> void:
	_body = null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_parent() is not Motor:
		warnings.append("Please use it as a child of a Motor.")
	return warnings


@abstract
func calculate() -> void


func get_radius() -> float:
	return 0.0


func toggle_mode() -> void:
	pass


func _update_debug_view() -> void:
	pass
