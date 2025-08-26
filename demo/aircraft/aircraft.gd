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
@onready var motor := $Motor as Motor

var flap_mode := 0


func _ready() -> void:
	for w in find_children("*", "VehicleWing3D"):
		w.debug = debug
	for f in find_children("*", "VehicleFuselage3D"):
		f.debug = debug

#
#func _physics_process(_delta: float) -> void:
	#var force := wing.get_force() + elevator.get_force() + rudder.get_force()
	#var wing_drag := force.dot(-linear_velocity.normalized())
	#var fuselage_drag = fuselage._force.dot(-linear_velocity.normalized())
	#print("wing: ", roundi(wing_drag), ' fuselage: ', roundi(fuselage_drag))
