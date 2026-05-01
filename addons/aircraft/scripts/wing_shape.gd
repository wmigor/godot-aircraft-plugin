@tool
extends Node
class_name WingShape

## Length.
@export var length := 4.0:
	set(value):
		length = value
		_update_wing_gizmos()

## Chord at the tip.
@export var chord := 0.5:
	set(value):
		chord = value
		_update_wing_gizmos()

## Twist angle.
@export_range(-15, 15, 0.001, "radians_as_degrees") var twist := 0.0:
	set(value):
		twist = value
		_update_wing_gizmos()

## Twist power.
@export_range(0.0, 6, 0.001) var twist_power := 1.0:
	set(value):
		twist_power = value
		_update_wing_gizmos()

## Sweep angle.
@export_range(-70, 70, 0.001, "radians_as_degrees") var sweep := 0.0:
	set(value):
		sweep = value
		_update_wing_gizmos()

## Dihedral angle.
@export_range(-30, 30, 0.001, "radians_as_degrees") var dihedral := 0.0:
	set(value):
		dihedral = value
		_update_wing_gizmos()


var wing: VehicleWing3D:
	get: return wing


func _enter_tree() -> void:
	wing = get_parent() as VehicleWing3D
	if wing != null:
		wing.add_shape(self)


func _exit_tree() -> void:
	if wing != null:
		wing.remove_shape(self)
	wing = null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_parent() is not VehicleWing3D:
		warnings.append("Please use it as a child of a VehicleWing3D.")
	return warnings


func _update_wing_gizmos() -> void:
	if wing != null:
		wing.update_gizmos()


## Returns position of shape tip
func get_tip(base: Vector3) -> Vector3:
	var direction := Vector3.RIGHT
	direction = direction.rotated(Vector3.DOWN, sweep)
	direction = direction.rotated(Vector3.BACK, dihedral)
	var tip := direction * length / direction.x
	return base + tip


func get_mac(base_chord: float) -> float:
	var taper := chord / base_chord
	return 2.0 / 3.0 * base_chord * (1.0 + taper + taper * taper) / (1.0 + taper)


func get_area(base_chord: float, mirror: bool) -> float:
	var area := (base_chord + chord) * length * 0.5
	if mirror:
		area *= 2.0
	return area


func get_mac_forward_position(base_chord: float, mac: float, mirror: bool) -> float:
	var taper := chord / base_chord
	var pos := mac / 4.0 * (1.0 - taper)
	if sweep != 0.0:
		pos += tan(sweep) * get_mac_right_position(base_chord, mirror)
	return pos - (base_chord - mac) * 0.5


func get_mac_right_position(base_chord: float, mirror: bool) -> float:
	var taper := chord / base_chord
	var pos := length / 6.0 * (1.0 + 2.0 * taper) / (1.0 + taper)
	if mirror:
		pos *= 2.0
	return pos
