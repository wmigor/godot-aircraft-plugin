extends VehicleBody3D
class_name Aircraft

@export var flap_modes: Array[float] = [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
@export var brake_value := 1.0
@export var horizontal_height := 0.0
@export var horizontal_rotation := 0.0
@export var camera_distance := 8.0
@export var debug := true

@onready var wing := $Wing as VehicleWing3D
@onready var elevator := $Elevator as VehicleWing3D
@onready var rudder := $Rudder as VehicleWing3D
@onready var fuselage := $Fuselage as VehicleFuselage3D

var thrusters: Array[VehicleThruster3D]
var flap_mode := 0

var rpm: float:
	get(): return thrusters[0].rpm if len(thrusters) > 0 else 0.0

var throttle: float:
	get(): return thrusters[0].throttle if len(thrusters) > 0 else 0.0
	set(value):
		for thruster in thrusters:
			thruster.throttle = value


func _ready() -> void:
	for thruster in find_children("*", "VehicleThruster3D"):
		thrusters.append(thruster)
		thruster.debug = debug
	for w in find_children("*", "VehicleWing3D"):
		w.debug = debug
	for f in find_children("*", "VehicleFuselage3D"):
		f.debug = debug
