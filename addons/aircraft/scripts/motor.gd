@abstract
extends Node3D
class_name Motor

@export_range(0.0, 1.0, 0.001) var throttle := 1.0
@export var inertia := 0.3
@export var enabled := true
@export var apply_torque_to_body: bool
@export var reverse: bool

const TO_RPM := 60.0 / TAU
const TO_KMPH = 3.6
const HP_TO_W := 745.7

var angular_velocity: float
var torque: float
var running: bool

var rpm: float:
	get: return angular_velocity * VehicleThruster3D.TO_RPM
	set(value): angular_velocity = value / VehicleThruster3D.TO_RPM

var _body: RigidBody3D
var _thrusters: Array[VehicleThruster3D]


func _ready() -> void:
	_thrusters.clear()
	_thrusters.append_array(find_children("*", "VehicleThruster3D"))


func _enter_tree() -> void:
	_body = get_parent() as RigidBody3D


func _exit_tree() -> void:
	_body == null


func _physics_process(delta: float) -> void:
	if _body == null:
		return
	var total_inertia := inertia
	var total_torque_required := 0.0
	for thruster in _thrusters:
		thruster.angular_velocity = angular_velocity / thruster.gear
		thruster.calculate()
		total_torque_required += thruster.torque / thruster.gear
		total_inertia += thruster.inertia / (thruster.gear * thruster.gear)
	torque = _calculate_torque()
	angular_velocity += delta * (torque - total_torque_required) / total_inertia
	if angular_velocity < 0.0:
		angular_velocity = 0.0
	for thruster in _thrusters:
		thruster.angular_velocity = angular_velocity / thruster.gear
	if apply_torque_to_body:
		_apply_torque_to_body()


func _apply_torque_to_body() -> void:
	var direction := -1.0 if reverse else 1.0
	var forward := -global_basis.z
	_body.apply_torque(direction * forward * torque)


@abstract
func _calculate_torque() -> float
