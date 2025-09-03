extends VehicleBody3D
class_name AircraftBody3D

@export var flap_modes: Array[float] = [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
@export var brake_value := 1.0
@export var steering_value := 5.0
@export var horizontal_height := 0.0
@export var horizontal_rotation := 0.0
@export var camera_distance := 8.0
@export var trim_scale := 0.2
@export var trim_step := 0.1
@export_range(0.0, 1.0, 0.001) var thruster_wind_factor := 0.1
@export var debug := true

@export_group("Input")
@export_range(-1.0, 1.0, 0.001) var input_ailerons := 0.0
@export_range(-1.0, 1.0, 0.001) var input_elevator := 0.0
@export_range(-1.0, 1.0, 0.001) var input_rudder := 0.0
@export_range(0.0, 1.0, 0.001) var input_throttle := 1.0
@export var input_engine_running := true

var _wings: Array[VehicleWing3D]
var _elevators: Array[VehicleWing3D]
var _rudders: Array[VehicleWing3D]
var _thrusters: Array[VehicleThruster3D]
var _rotors: Array[VehicleRotor3D]
var _flap_mode := 0

var rpm: float:
	get(): return _thrusters[0].rpm if len(_thrusters) > 0 else 0.0

var has_rotor: bool:
	get(): return len(_rotors) > 0

var trim_aileron := 0.0:
	get(): return trim_aileron

var trim_elevator := 0.0:
	get(): return trim_elevator


func _ready() -> void:
	_find_objects()


func _physics_process(delta: float) -> void:
	_apply_input(delta)
	if thruster_wind_factor > 0.0:
		var wind := Vector3.ZERO
		for thruster in _thrusters:
			wind += thruster.wind * thruster_wind_factor
		for rudder in _rudders:
			rudder.global_wind = wind
		for elevator in _elevators:
			elevator.global_wind = wind


func _apply_input(delta: float) -> void:
	var ailerons_value := clampf(input_ailerons + trim_aileron * trim_scale, -1.0, 1.0)
	var elevator_value := clampf(input_elevator + trim_elevator * trim_scale, -1.0, 1.0)
	for thruster in _thrusters:
		thruster.throttle = input_throttle
		thruster.running = input_engine_running
	for rotor in _rotors:
		rotor.pitch = input_throttle
		rotor.tail_pitch = input_rudder
		rotor.stick_angle = atan2(elevator_value, -ailerons_value)
		rotor.stick_len = sqrt(elevator_value * elevator_value + ailerons_value * ailerons_value)
	for wing in _wings:
		wing.aileron_value = ailerons_value
		if _flap_mode >= 0 and _flap_mode < len(flap_modes):
			wing.flap_value = move_toward(wing.flap_value, flap_modes[_flap_mode], delta)
	for elevator in _elevators:
		elevator.flap_value = elevator_value
	for rudder in _rudders:
		rudder.flap_value = input_rudder


func _find_objects() -> void:
	for thruster in find_children("*", "VehicleThruster3D"):
		_thrusters.append(thruster)
		if thruster is VehicleRotor3D:
			_rotors.append(thruster)
		thruster.debug = debug
	for wing in find_children("*", "VehicleWing3D"):
		if wing.type == VehicleWing3D.Type.Wing:
			_wings.append(wing)
		elif wing.type == VehicleWing3D.Type.Elevator:
			_elevators.append(wing)
		elif wing.type == VehicleWing3D.Type.Rudder:
			_rudders.append(wing)
		wing.debug = debug
	for fuselage in find_children("*", "VehicleFuselage3D"):
		fuselage.debug = debug


func change_flap_mode(delta: int) -> void:
	_flap_mode = clampi(_flap_mode + delta, 0, len(flap_modes) - 1)


func change_trim_elevator(direction: int) -> void:
	trim_elevator = clampf(trim_elevator + direction * trim_step, -1.0, 1.0)


func change_trim_aileron(direction: int) -> void:
	trim_aileron = clampf(trim_aileron + direction * trim_step, -1.0, 1.0)
