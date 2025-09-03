extends Node3D
class_name VehicleThruster3D

## Air density.
@export var density := 1.2255
## Enables debug view of thruster
@export var debug: bool:
	set(value):
		if value != debug:
			debug = value
			_update_debug_view()

const TO_RPM := 60.0 / TAU
const TO_KMPH = 3.6
const HP_TO_W := 745.7

var throttle := 1.0
var thrust := 0.0
var torque := 0.0
var angular_velocity := 0.0
var wind := 0.0
var running := true
var _body: RigidBody3D

var rpm: float:
	get(): return angular_velocity * TO_RPM

var rps: float:
	get(): return rpm / 60.0


func _enter_tree() -> void:
	_body = get_parent() as RigidBody3D


func _exit_tree() -> void:
	_body = null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_parent() is not RigidBody3D:
		warnings.append("Please use it as a child of a VehicleBody3D or RigidBody3D.")
	return warnings


func _update_debug_view() -> void:
	pass
