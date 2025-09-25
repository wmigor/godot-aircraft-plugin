@tool
@icon("uid://dgp1egfjl2whe")
extends Node3D
class_name VehicleWing3D

## A node used as a child of a [VehicleBody3D] parent to simulate the behavior of one of its wings.
## There are settings for flexible adjustment of the wing shape, control surfaces and aerodynamics.
## The wing is divided into multiple sections for precise forces calculation during aircraft
## rotation.[br][br]
## The aerodynamic formulas used here are from the paper "Real-time modeling of agile fixed-wing UAV
## aerodynamics" by Khan and Nahon 2015 .[br][br]
## It seems these formulas overestimate drag, so the alternative_drag enables a different
## calculation method from another paper https://www.aerodynamics4students.com/[br][br]
## [b]Note:[/b] It's important to disable damping in VehicleBody3D — the wings already create
## enough drag.[br][br]
## [b]Note:[/b] Use Custom Center of Mass Mode in VehicleBody3D because wing positioning relative
## to the center of mass is critical - wings should be placed near the center of mass.[br][br]
## [b]Note:[/b] When shape parameters are modified, the wing adapts to maintain the center of
## pressure at the wing node's position.[br][br]

enum Type { Wing, Elevator, Rudder }

@export_group("Shape")
## Wing span. Distance between wingtips.
@export var span := 4.0:
	set(value):
		span = value
		_dirty = true
		update_gizmos()

## Wing chord at the base.
@export var chord := 0.5:
	set(value):
		chord = value
		_dirty = true
		update_gizmos()

## Taper of the wing at the tip relative to the base.
@export_range(0, 1) var taper := 1.0:
	set(value):
		taper = value
		_dirty = true
		update_gizmos()

## Wing twist angle.
@export_range(-15, 15, 0.001, "radians_as_degrees") var twist := 0.0:
	set(value):
		twist = value
		_dirty = true
		update_gizmos()


## Wing twist power.
@export_range(0.0, 6, 0.001) var twist_power := 1.0:
	set(value):
		twist_power = value
		_dirty = true
		update_gizmos()

## Wing sweep angle.
@export_range(-70, 70, 0.001, "radians_as_degrees") var sweep := 0.0:
	set(value):
		sweep = value
		_dirty = true
		update_gizmos()

## Wing dihedral angle.
@export_range(-30, 30, 0.001, "radians_as_degrees") var dihedral := 0.0:
	set(value):
		dihedral = value
		_dirty = true
		update_gizmos()

## X-axis offset. The mirror part of the wing has the opposite offset.
@export var offset := 0.0:
	set(value):
		offset = value
		_dirty = true
		update_gizmos()

## Mirror wing on x axis.
@export var mirror := true:
	set(value):
		mirror = value
		_dirty = true
		update_gizmos()

@export_group("Aerodynamic")
## Airfoil
@export var airfoil: Airfoil
## Air density.
@export var density := 1.2255

@export_group("Control surfaces")
## Wing type
@export var type := Type.Wing
## Flap start relative to wing length.
@export_range(0, 1, 0.001) var flap_start := 0.1:
	set(value):
		flap_start = value
		update_gizmos()

## Flap end relative to wing length.
@export_range(0, 1, 0.001) var flap_end := 0.4:
	set(value):
		flap_end = value
		update_gizmos()

## Flap fraction relative to wing chord.
@export_range(0, 0.9, 0.001) var flap_fraction := 0.3:
	set(value):
		flap_fraction = value
		update_gizmos()

## Мaximum positive flap angle.
@export_range(0, 90, 0.001, "radians_as_degrees") var flap_angle_max := deg_to_rad(30.0):
	set(value):
		flap_angle_max = value
		update_gizmos()

## Мinimum negative flap angle.
@export_range(-90, 0, 0.001, "radians_as_degrees") var flap_angle_min := deg_to_rad(-30.0):
	set(value):
		flap_angle_min = value
		update_gizmos()

## Aileron start relative to wing length.
@export_range(0, 1, 0.001) var aileron_start := 0.5:
	set(value):
		aileron_start = value
		update_gizmos()

## Aileron end relative to wing length.
@export_range(0, 1, 0.001) var aileron_end := 0.9:
	set(value):
		aileron_end = value
		update_gizmos()

## Aileron fraction relative to wing chord.
@export_range(0, 0.9, 0.001) var aileron_fraction := 0.2:
	set(value):
		aileron_fraction = value
		update_gizmos()

## Мaximum positive aileron angle.
@export_range(0, 90, 0.001, "radians_as_degrees") var aileron_angle_max := deg_to_rad(15.0):
	set(value):
		aileron_angle_max = value
		update_gizmos()

## Мinimum negative aileron angle.
@export_range(-90, 0, 0.001, "radians_as_degrees") var aileron_angle_min := deg_to_rad(-15.0):
	set(value):
		aileron_angle_min = value
		update_gizmos()

@export_group("Input")
## Controls the aileron angle. Values in the range (-1, 1) change the aileron angle from minimum to maximum angle. Ailerons at opposite ends of the wing deflect in opposite directions.
@export_range(-1, 1, 0.001) var aileron_value: float:
	set(value):
		aileron_value = value
		update_gizmos()

## Controls the flap angle. Values in the range (-1, 1) change the flap angle from minimum to maximum angle. Flaps on opposite ends of the wing deflect in the same direction.
@export_range(-1, 1, 0.001) var flap_value: float:
	set(value):
		flap_value = value
		update_gizmos()

## Global wind
@export var global_wind: Vector3

@export_group("Debug")
## Enables debug view of wing sections
@export var debug: bool:
	set(value):
		if value != debug:
			debug = value
			_update_debug_view()


enum ControlSurfaceType { None, Flap, Aileron }


class ControlSurface:
	var type: ControlSurfaceType
	var start: float
	var end: float
	var fraction: float


class Section extends Airfoil.Data:
	var type: ControlSurfaceType
	var transform: Transform3D
	var global_transform: Transform3D
	var length: float
	var mirror: bool
	var force: Vector3
	var torque: Vector3
	var torque_factor: float
	var control_surface_lift: float
	var corrected_lift_slope: float
	var corrected_zero_lift_angle: float
	var corrected_stall_angle_max: float
	var corrected_stall_angle_min: float
	var restore_stall_angle_max: float
	var restore_stall_angle_min: float


var relax_forces := true

var _force: Vector3
var _torque: Vector3
var _body: RigidBody3D
var _dirty := true
var _aspect_ratio: float
var _sections: Array[Section]
var _debug_view: Node3D


func _ready() -> void:
	if airfoil == null:
		airfoil = AirfoilFormula.new()


func _enter_tree() -> void:
	_body = get_parent() as RigidBody3D
	_try_rebuild()


func _exit_tree() -> void:
	_body = null


func _physics_process(delta: float) -> void:
	if _body == null or not visible or Engine.is_editor_hint():
		return
	var state := PhysicsServer3D.body_get_direct_state(_body.get_rid())
	if state != null:
		calculate(state.linear_velocity, state.angular_velocity, _body.transform * state.center_of_mass_local)
		_body.apply_central_force(_force)
		_body.apply_torque(_torque)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_parent() is not RigidBody3D:
		warnings.append("VehicleWing3D serves to provide a aerodynamic to a VehicleBody3D or RigidBody3D. Please use it as a child of a VehicleBody3D or RigidBody3D.")
	return warnings


## Мanual calculation of the force and torque generated by the wing. For example, to plot graphs.
func calculate(linear_velocity: Vector3, angular_velocity: Vector3, center_of_mass: Vector3) -> void:
	_try_rebuild()
	_force = Vector3.ZERO
	_torque = Vector3.ZERO

	for section in _sections:
		section.global_transform = global_transform * section.transform
		var arm := section.global_transform.origin - center_of_mass
		var wind := global_wind - (linear_velocity + angular_velocity.cross(arm))
		_calculate_section_forces(section, wind)
		_force += section.force
		_torque += section.torque + arm.cross(section.force)


func _calculate_section_forces(section: Section, wind: Vector3) -> void:
	var right := section.global_transform.basis.x
	var drag_direction := wind.normalized()
	var lift_direction := drag_direction.cross(right)
	var to_local := section.global_transform.affine_inverse()
	var local_wind := to_local * wind - to_local * Vector3.ZERO
	section.angle_of_attack = atan2(local_wind.y, local_wind.z)
	section.control_surface_angle = get_control_surface_angle(section.type, section.mirror)
	section.aspect_ratio = _aspect_ratio
	section.wind = wind
	airfoil.update_factors(section)
	var pressure := 0.5 * density * wind.length_squared() * section.chord * section.length
	var lift := lift_direction * section.lift_factor * pressure
	var drag := drag_direction * section.drag_factor * pressure
	var force := lift + drag
	var torque := right * section.pitch_factor * pressure * section.chord
	if relax_forces:
		force = section.force + (force - section.force) * 0.5
		torque = section.torque + (torque - section.torque) * 0.5
	section.force = force
	section.torque = torque


## Returns angle of control surface at wing part
func get_control_surface_angle(type: ControlSurfaceType, is_mirror: bool) -> float:
	if type == ControlSurfaceType.Aileron:
		return _get_aileron_angle(is_mirror)
	elif type == ControlSurfaceType.Flap:
		return _get_flap_angle()
	return 0.0


func _get_aileron_angle(is_mirror: bool) -> float:
	if is_mirror:
		return (aileron_angle_min if aileron_value > 0.0 else -aileron_angle_max) * aileron_value
	return (aileron_angle_max if aileron_value > 0.0 else -aileron_angle_min) * aileron_value

func _get_flap_angle() -> float:
	return (flap_angle_max if flap_value >= 0.0 else -flap_angle_min) * flap_value


func _try_rebuild() -> void:
	if not _dirty:
		return
	_sections.clear()
	_dirty = false
	_update_aspect_ratio()
	_build_wing_sections()
	if _debug_view != null:
		_debug_view.build()


func _update_aspect_ratio() -> void:
	var mean_chord := (chord + chord * taper) * 0.5
	if absf(mean_chord) < 0.001:
		_aspect_ratio = 1.0
		return
	_aspect_ratio = span / mean_chord
	if absf(_aspect_ratio) < 0.001:
		_aspect_ratio = 1.0


func _build_wing_sections() -> void:
	_sections.clear()
	var nominal_section_length := _get_nominal_section_length()
	if nominal_section_length <= 0.0:
		return
	var control_surface_sections := _build_control_surface_sections()
	var base := get_base()
	var tip := get_tip()
	var mac_z := get_mac_forward_position()
	var offset_z := base.z - mac_z
	base.z += offset_z
	tip.z += offset_z
	for control_surface in control_surface_sections:
		var bound_size := control_surface.end - control_surface.start
		var section_count := ceili(bound_size / nominal_section_length)
		if section_count <= 0:
			continue
		var section_length := get_console_length() * bound_size / section_count
		for i in section_count:
			var fraction := control_surface.start + (i + 0.5) * bound_size / section_count
			var section_pos := base + (tip - base) * fraction
			var section_chord := chord * (1.0 - (1.0 - taper) * fraction)
			var section_twist = twist * pow(fraction, twist_power)
			_sections.append(_create_wing_section(control_surface, section_pos, section_chord, section_length, section_twist, false))
			if mirror:
				section_pos.x = -section_pos.x
				_sections.append(_create_wing_section(control_surface, section_pos, section_chord, section_length, section_twist, true))


func _build_control_surface_sections() -> Array[ControlSurface]:
	var sections: Array[ControlSurface]
	var control_surfaces: Array[ControlSurface]
	if has_flap():
		var flap := ControlSurface.new()
		flap.type = ControlSurfaceType.Flap
		flap.start = flap_start
		flap.end = flap_end
		flap.fraction = flap_fraction
		control_surfaces.append(flap)
	if has_aileron():
		var aileron := ControlSurface.new()
		aileron.type = ControlSurfaceType.Aileron
		aileron.start = aileron_start
		aileron.end = aileron_end
		aileron.fraction = aileron_fraction
		control_surfaces.append(aileron)
	if len(control_surfaces) <= 0:
		var empty := ControlSurface.new()
		empty.type = ControlSurfaceType.None
		empty.start = 0.0
		empty.end = 1.0
		empty.fraction = 0.0
		sections.append(empty)
		return sections
	control_surfaces.sort_custom(func(a: ControlSurface, b: ControlSurface): return a.start < b.start)
	var pos := 0.0
	for i in len(control_surfaces):
		var control_surface := control_surfaces[i]
		if pos < control_surface.start:
			var section := ControlSurface.new()
			section.type = ControlSurfaceType.None
			section.start = pos
			section.end = control_surface.start
			section.fraction = 0.0
			sections.append(section)
		sections.append(control_surface)
		pos = control_surface.end

		if i == len(control_surfaces) - 1 and pos < 1.0:
			var section := ControlSurface.new()
			section.type = ControlSurfaceType.None
			section.start = pos
			section.end = 1.0
			section.fraction = 0.0
			sections.append(section)
	sections.sort_custom(func(a: ControlSurface, b: ControlSurface): return a.start < b.start)
	return sections


func _create_wing_section(p_control_surface: ControlSurface, p_position: Vector3, p_chord: float, p_length: float, p_twist: float, is_mirror: bool) -> Section:
	var section := Section.new()
	section.transform = Transform3D(Basis.from_euler(Vector3(p_twist, 0.0, -dihedral if is_mirror else dihedral)), p_position)
	section.chord = p_chord
	section.length = p_length
	section.type = p_control_surface.type
	section.mirror = is_mirror
	section.stall = false
	if p_control_surface.type != ControlSurfaceType.None and p_control_surface.fraction > 0.0:
		section.control_surface_fraction = p_control_surface.fraction
	else:
		section.control_surface_fraction = 0.0
	return section


func _get_nominal_section_length() -> float:
	var tip_chord := chord * taper
	var mid_chord := (chord + tip_chord) / 2.0
	var section_length := mid_chord / get_console_length() / 2.0
	if section_length <= 0.0:
		return 0.0
	var section_count := ceili(1.0 / section_length)
	return 1.0 / 8.0 if twist != 0.0 and section_count < 8 else section_length


## Returns position of wing base
func get_base() -> Vector3:
	return Vector3.RIGHT * offset


## Returns position of wing tip
func get_tip() -> Vector3:
	var direction := Vector3.RIGHT
	direction = direction.rotated(Vector3.DOWN, sweep)
	direction = direction.rotated(Vector3.BACK, dihedral)
	var tip := direction * get_console_length() / direction.x
	return get_base() + tip


## Returns true if wing has flap
func has_flap() -> bool:
	return flap_start != flap_end and flap_fraction > 0.0


## Returns true if wing has aileron
func has_aileron() -> bool:
	return aileron_start != aileron_end and aileron_fraction > 0.0


## Returns console length
func get_console_length() -> float:
	return span / 2.0 - offset if mirror else span - offset


## Returns the mean aerodynamic chord of wing.
func get_mac() -> float:
	return 2.0 / 3.0 * chord * (1.0 + taper + taper * taper) / (1.0 + taper)


## Returns x-axis distance to mac
func get_mac_right_position() -> float:
	var length := get_console_length() * 2.0 if mirror else get_console_length()
	return length / 6.0 * (1.0 + 2.0 * taper) / (1.0 + taper)


## Returns z-axis distance to mac
func get_mac_forward_position() -> float:
	var mac := get_mac()
	var pos := mac / 4.0 * (1.0 - taper)
	if sweep != 0.0:
		pos += tan(sweep) * get_mac_right_position()
	return pos - (chord - mac) * 0.5


## Returns the force generated by the wing.
func get_force() -> Vector3:
	return _force


## Returns the torque generated by the wing.
func get_torque() -> Vector3:
	return _torque


## Returns the number of wing sections.
func get_section_count() -> int:
	return len(_sections)


## Returns the chord of the wing section.
func get_section_chord(index: int) -> float:
	return _sections[index].chord


## Returns the control surface fraction of the wing section.
func get_section_control_surface_fraction(index: int) -> float:
	return _sections[index].control_surface_fraction


## Returns the transform of the wing section.
func get_section_transform(index: int) -> Transform3D:
	return _sections[index].transform


## Returns the length of the wing section.
func get_section_length(index: int) -> float:
	return _sections[index].length


## Determines whether the wing section is currently in a stalled.
func is_section_stall(index: int) -> bool:
	return _sections[index].stall


## Determines whether the wing section is currently in a stalled.
func is_section_stall_warning(index: int) -> bool:
	return _sections[index].stall_warning


## Returns the control surface angle of the wing section.
func get_section_control_surface_angle(index: int) -> float:
	return _sections[index].control_surface_angle


var VehicleWing3DDebugView := preload("uid://ep1ok4t4lxt0")
func _update_debug_view() -> void:
	if _debug_view != null:
		_debug_view.queue_free()
		_debug_view = null
	if debug:
		_debug_view = VehicleWing3DDebugView.new()
		add_child(_debug_view)
