@tool
@icon("uid://dgp1egfjl2whe")
extends Node3D
class_name VehicleWing3D


@export_group("Shape")
@export var chord := 0.5:
	set(value):
		chord = value
		_dirty = true
		update_gizmos()

@export var span := 4.0:
	set(value):
		span = value
		_dirty = true
		update_gizmos()

@export_range(0, 1) var taper := 1.0:
	set(value):
		taper = value
		_dirty = true
		update_gizmos()

@export_range(-15, 15, 0.001, "radians_as_degrees") var twist := 0.0:
	set(value):
		twist = value
		_dirty = true
		update_gizmos()

@export_range(-70, 70, 0.001, "radians_as_degrees") var sweep := 0.0:
	set(value):
		sweep = value
		_dirty = true
		update_gizmos()

@export_range(-30, 30, 0.001, "radians_as_degrees") var dihedral := 0.0:
	set(value):
		dihedral = value
		_dirty = true
		update_gizmos()

@export var offset := 0.0:
	set(value):
		offset = value
		_dirty = true
		update_gizmos()

@export var mirror := true:
	set(value):
		mirror = value
		_dirty = true
		update_gizmos()

@export_group("Aerodynamic")
@export var lift_slope := TAU
@export_range(-10, 10, 0.001, "radians_as_degrees") var zero_lift_angle := 0.0
@export_range(0, 30, 0.001, "radians_as_degrees") var stall_angle_max := deg_to_rad(16.0)
@export_range(-30, 0, 0.001, "radians_as_degrees") var stall_angle_min := deg_to_rad(-16.0)
@export_range(0, 30, 0.001, "radians_as_degrees") var stall_width := deg_to_rad(6.0)
@export_range(0, 0, 0.001) var surface_friction := 0.023
@export_range(0, 30, 0.001, "radians_as_degrees") var restore_stall_angle := deg_to_rad(5.0)
@export var density := 1.2255
@export var alternative_drag := false

@export_group("Control surfaces")
@export_range(0, 1, 0.001) var flap_start := 0.1:
	set(value):
		flap_start = value
		update_gizmos()

@export_range(0, 1, 0.001) var flap_end := 0.4:
	set(value):
		flap_end = value
		update_gizmos()

@export_range(0, 0.9, 0.001) var flap_fraction := 0.3:
	set(value):
		flap_fraction = value
		update_gizmos()

@export_range(0, 90, 0.001, "radians_as_degrees") var flap_angle_max := deg_to_rad(30.0):
	set(value):
		flap_angle_max = value
		update_gizmos()

@export_range(0, -90, 0.001, "radians_as_degrees") var flap_angle_min := deg_to_rad(-30.0):
	set(value):
		flap_angle_min = value
		update_gizmos()

@export_range(0, 1, 0.001) var aileron_start := 0.5:
	set(value):
		aileron_start = value
		update_gizmos()

@export_range(0, 1, 0.001) var aileron_end := 0.9:
	set(value):
		aileron_end = value
		update_gizmos()

@export_range(0, 0.9, 0.001) var aileron_fraction := 0.2:
	set(value):
		aileron_fraction = value
		update_gizmos()

@export_range(0, 90, 0.001, "radians_as_degrees") var aileron_angle_max := deg_to_rad(15.0):
	set(value):
		aileron_angle_max = value
		update_gizmos()

@export_range(0, -90, 0.001, "radians_as_degrees") var aileron_angle_min := deg_to_rad(-15.0):
	set(value):
		aileron_angle_min = value
		update_gizmos()

@export_group("Input")
@export_range(-1, 1, 0.001) var aileron_value: float:
	set(value):
		aileron_value = value
		update_gizmos()

@export_range(-1, 1, 0.001) var flap_value: float:
	set(value):
		flap_value = value
		update_gizmos()



enum ControlSurfaceType { None, Flap, Aileron }


class ControlSurface:
	var type: ControlSurfaceType
	var start: float
	var end: float
	var fraction: float


class Section:
	var type: ControlSurfaceType
	var transform: Transform3D
	var global_transform: Transform3D
	var length: float
	var chord: float
	var control_surface_fraction: float
	var mirror: bool
	var force: Vector3
	var torque: Vector3
	var lift_factor: float
	var drag_factor: float
	var torque_factor: float
	var angle_of_attack: float
	var control_surface_lift: float
	var control_surface_angle: float
	var corrected_lift_slope: float
	var corrected_zero_lift_angle: float
	var corrected_stall_angle_max: float
	var corrected_stall_angle_min: float
	var stall_warning: bool
	var stall: bool
	var restore_stall_angle_max: float
	var restore_stall_angle_min: float


var _force: Vector3
var _torque: Vector3
var _body: RigidBody3D
var _dirty := true
var _aspect_ratio: float
var _sections: Array[Section]


func _enter_tree() -> void:
	_body = get_parent() as RigidBody3D
	_try_rebuild()


func _exit_tree() -> void:
	_body = null


func _physics_process(delta: float) -> void:
	if _body == null:
		return
	var state := PhysicsServer3D.body_get_direct_state(_body.get_rid())
	if state != null:
		calculate(state.linear_velocity, state.angular_velocity, _body.transform * state.center_of_mass_local)
		_body.apply_central_force(_force)
		_body.apply_torque(_torque)


func calculate(p_linear_velocity: Vector3, p_angular_velocity: Vector3, p_center_of_mass: Vector3) -> void:
	_try_rebuild()
	_force = Vector3.ZERO
	_torque = Vector3.ZERO

	for section in _sections:
		section.global_transform = global_transform * section.transform
		var arm := section.global_transform.origin - p_center_of_mass
		var wind := -(p_linear_velocity + p_angular_velocity.cross(arm))
		_calculate_section_forces(section, wind)
		_force += section.force
		_torque += section.torque + arm.cross(section.force)


func _calculate_section_forces(p_section: Section, p_wind: Vector3) -> void:
	var right := p_section.global_transform.basis.x
	var drag_direction := p_wind.normalized()
	var lift_direction := drag_direction.cross(right)
	_update_section_parameters(p_section, p_wind)
	_calculate_section_factors(p_section, p_wind)
	var pressure := 0.5 * density * p_wind.length_squared() * p_section.chord * p_section.length
	var lift := lift_direction * p_section.lift_factor * pressure
	var drag := drag_direction * p_section.drag_factor * pressure
	var force := lift + drag
	var torque := -right * p_section.torque_factor * pressure * p_section.chord
	force = p_section.force + (force - p_section.force) * 0.5
	torque = p_section.torque + (torque - p_section.torque) * 0.5
	p_section.force = force
	p_section.torque = torque


func _update_section_parameters(p_section: Section, p_wind: Vector3) -> void:
	var to_local := p_section.global_transform.affine_inverse()
	var local_wind := to_local * p_wind - to_local * Vector3.ZERO
	p_section.angle_of_attack = get_angle_of_attack(local_wind)
	p_section.control_surface_angle = get_control_surface_angle(p_section.type, p_section.mirror)
	p_section.corrected_lift_slope = lift_slope * _aspect_ratio / (_aspect_ratio + 2.0 * (_aspect_ratio + 4.0) / (_aspect_ratio + 2.0))

	var control_surface_effectivness_factor := acos(2.0 * p_section.control_surface_fraction - 1.0)
	var control_surface_effectivness := 1.0 - (control_surface_effectivness_factor - sin(control_surface_effectivness_factor)) / PI

	p_section.control_surface_lift = p_section.corrected_lift_slope * control_surface_effectivness * get_control_surface_lift_factor(p_section.control_surface_angle) * p_section.control_surface_angle
	p_section.corrected_zero_lift_angle = zero_lift_angle - p_section.control_surface_lift / p_section.corrected_lift_slope

	var control_surface_lift_max := get_control_surface_lift_max(p_section.control_surface_fraction)
	var lift_max := p_section.corrected_lift_slope * (stall_angle_max - zero_lift_angle) + p_section.control_surface_lift * control_surface_lift_max
	var lift_min := p_section.corrected_lift_slope * (stall_angle_min - zero_lift_angle) + p_section.control_surface_lift * control_surface_lift_max

	p_section.corrected_stall_angle_max = p_section.corrected_zero_lift_angle + lift_max / p_section.corrected_lift_slope
	p_section.corrected_stall_angle_min = p_section.corrected_zero_lift_angle + lift_min / p_section.corrected_lift_slope

	_update_section_hysteresis_stall(p_section, p_wind)


func _calculate_section_factors(p_section: Section, p_wind: Vector3) -> void:
	var stall_angle_max := p_section.restore_stall_angle_max if p_section.stall else p_section.corrected_stall_angle_max
	var stall_angle_min := p_section.restore_stall_angle_min if p_section.stall else p_section.corrected_stall_angle_min

	if p_section.angle_of_attack >= stall_angle_min and p_section.angle_of_attack <= stall_angle_max:
		var factors := _calculate_normal_factors(p_section, p_section.angle_of_attack)
		p_section.lift_factor = factors.x
		p_section.drag_factor = factors.y
		p_section.torque_factor = factors.z
		p_section.stall_warning = false
		return

	p_section.stall_warning = p_wind.length_squared() >= chord * chord
	var full_stall_angle_max := p_section.corrected_stall_angle_max + stall_width
	var full_stall_angle_min := p_section.corrected_stall_angle_min - stall_width

	if p_section.angle_of_attack > full_stall_angle_max or p_section.angle_of_attack < full_stall_angle_min:
		var factors := _calculate_stall_factors(p_section, p_section.angle_of_attack)
		p_section.lift_factor = factors.x
		p_section.drag_factor = factors.y
		p_section.torque_factor = factors.z
		return

	var factors1: Vector3
	var factors2: Vector3
	var w: float

	if p_section.angle_of_attack > stall_angle_max:
		factors1 = _calculate_normal_factors(p_section, stall_angle_max)
		factors2 = _calculate_stall_factors(p_section, full_stall_angle_max)
		w = (p_section.angle_of_attack - stall_angle_max) / (full_stall_angle_max - stall_angle_max)
	else:
		factors1 = _calculate_normal_factors(p_section, stall_angle_min)
		factors2 = _calculate_stall_factors(p_section, full_stall_angle_min)
		w = (p_section.angle_of_attack - stall_angle_min) / (full_stall_angle_min - stall_angle_min)

	w = w * w * (3 - 2 * w)
	p_section.lift_factor = lerpf(factors1.x, factors2.x, w)
	p_section.drag_factor = lerpf(factors1.y, factors2.y, w)
	p_section.torque_factor = lerpf(factors1.z, factors2.z, w)


func _calculate_normal_factors(p_section: Section, p_angle_of_attack: float) -> Vector3:
	var lift := p_section.corrected_lift_slope * (p_angle_of_attack - p_section.corrected_zero_lift_angle)
	var induced_angle := lift / (PI * _aspect_ratio)
	var effective_angle := p_angle_of_attack - p_section.corrected_zero_lift_angle - induced_angle
	var cos_ea := cos(effective_angle)
	var sin_ea := sin(effective_angle)
	var tangent := surface_friction * cos_ea
	var normal := (lift + sin_ea * tangent) / cos_ea if absf(cos_ea) >= 0.001 else 0.0
	var drag: float
	if alternative_drag:
		var k := 1.0 / (PI * _aspect_ratio * 0.8)
		drag = surface_friction + k * lift * lift
	else:
		drag = normal * sin_ea + tangent * cos_ea
	var torque := p_section.control_surface_lift / 6.0 - normal * get_torque_factor(effective_angle)
	return Vector3(lift, drag, torque)


func _calculate_stall_factors(p_section: Section, p_angle_of_attack: float) -> Vector3:
	var stall_angle := p_section.corrected_stall_angle_max if p_angle_of_attack > p_section.corrected_stall_angle_max else p_section.corrected_stall_angle_min
	var stall_lift := p_section.corrected_lift_slope * (stall_angle - p_section.corrected_zero_lift_angle)
	var induced_angle := stall_lift / (PI * _aspect_ratio)
	var half_pi := PI / 2.0
	var z := half_pi - p_section.corrected_stall_angle_max if p_angle_of_attack > p_section.corrected_stall_angle_max else -half_pi - p_section.corrected_stall_angle_min
	var w := (half_pi - clampf(p_angle_of_attack, -half_pi, half_pi)) / z if absf(z) >= 0.001 else 0.0
	induced_angle = lerpf(0.0, induced_angle, w)
	var effective_angle := p_angle_of_attack - p_section.corrected_zero_lift_angle - induced_angle
	var sin_ea := sin(effective_angle)
	var cos_ea := cos(effective_angle)

	var normal := get_drag_max(p_section.control_surface_angle) * sin_ea * (1.0 / (0.56 + 0.44 * absf(sin_ea)) - 0.41 * (1.0 - exp(-17.0 / _aspect_ratio)))
	var tangent := 0.5 * surface_friction * cos_ea

	var lift := normal * cos_ea - tangent * sin_ea
	var drag := normal * sin_ea + tangent * cos_ea
	var torque := -normal * get_torque_factor(effective_angle)
	return Vector3(lift, drag, torque)


func _update_section_hysteresis_stall(p_section: Section, p_wind: Vector3) -> void:
	if p_wind.length_squared() < chord * chord:
		p_section.stall = false
		return

	var start_hysteresis_angle_max := p_section.corrected_stall_angle_max + stall_width
	var start_hysteresis_angle_min := p_section.corrected_stall_angle_min - stall_width
	p_section.restore_stall_angle_max = minf(p_section.corrected_stall_angle_max, restore_stall_angle)
	p_section.restore_stall_angle_min = minf(p_section.corrected_stall_angle_min, -restore_stall_angle)
	if not p_section.stall and (p_section.angle_of_attack >= start_hysteresis_angle_max or p_section.angle_of_attack <= start_hysteresis_angle_min):
		p_section.stall = true
	elif p_section.stall and p_section.angle_of_attack <= restore_stall_angle and p_section.angle_of_attack >= -restore_stall_angle:
		p_section.stall = false


func get_angle_of_attack(p_wind: Vector3) -> float:
	var angle := atan2(p_wind.y, p_wind.z)
	if angle > PI / 2.0:
		angle -= PI
	elif angle < -PI / 2.0:
		angle += PI
	return angle


func get_control_surface_angle(p_type: ControlSurfaceType, p_mirror: bool) -> float:
	if p_type == ControlSurfaceType.Aileron:
		return get_aileron_angle(p_mirror)
	elif p_type == ControlSurfaceType.Flap:
		return get_flap_angle()
	return 0.0


func get_aileron_angle(p_mirror: bool) -> float:
	if p_mirror:
		return (aileron_angle_min if aileron_value > 0.0 else -aileron_angle_max) * aileron_value
	return (aileron_angle_max if aileron_value > 0.0 else -aileron_angle_min) * aileron_value

func get_flap_angle() -> float:
	return (flap_angle_max if flap_value >= 0.0 else -flap_angle_min) * flap_value


func get_torque_factor(p_effective_angle: float) -> float:
	return 0.25 - 0.175 * (1.0 - 2.0 * p_effective_angle / PI)


func get_control_surface_lift_max(p_control_surface_fraction: float) -> float:
	return clampf(1.0 - 0.5 * (p_control_surface_fraction - 0.1) / 0.3, 0.0, 1.0)


func get_drag_max(p_control_surface_angle: float) -> float:
	return 1.98 - 4.26e-2 * p_control_surface_angle * p_control_surface_angle + 2.1e-1 * p_control_surface_angle


func get_control_surface_lift_factor(p_control_surface_angle: float) -> float:
	return lerpf(0.8, 0.4, (absf(rad_to_deg(p_control_surface_angle)) - 10.0) / 50.0)


func _try_rebuild() -> void:
	if not _dirty:
		return
	_sections.clear()
	_dirty = false
	_update_aspect_ratio()
	_build_wing_sections()


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
	var nominal_section_length := get_nominal_section_length()
	if nominal_section_length <= 0.0:
		return
	var control_surface_sections := build_control_surface_sections()
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
			var section_twist = twist * fraction
			_sections.append(_create_wing_section(control_surface, section_pos, section_chord, section_length, section_twist, false))
			if mirror:
				section_pos.x = -section_pos.x
				_sections.append(_create_wing_section(control_surface, section_pos, section_chord, section_length, section_twist, true))


func build_control_surface_sections() -> Array[ControlSurface]:
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


func _create_wing_section(p_control_surface: ControlSurface, p_position: Vector3, p_chord: float, p_length: float, p_twist: float, p_mirror: bool) -> Section:
	var section := Section.new()
	section.transform = Transform3D(Basis.from_euler(Vector3(p_twist, 0.0, -dihedral if p_mirror else dihedral)), p_position)
	section.chord = p_chord
	section.length = p_length
	section.type = p_control_surface.type
	section.mirror = p_mirror
	section.stall = false
	if p_control_surface.type != ControlSurfaceType.None and p_control_surface.fraction > 0.0:
		section.control_surface_fraction = p_control_surface.fraction
	else:
		section.control_surface_fraction = 0.0
	return section


func get_nominal_section_length() -> float:
	var tip_chord := chord * taper
	var mid_chord := (chord + tip_chord) / 2.0
	var section_length := mid_chord / get_console_length() / 2.0
	if section_length <= 0.0:
		return 0.0
	var section_count := ceili(1.0 / section_length)
	return 1.0 / 8.0 if twist != 0.0 and section_count < 8 else section_length


func get_base() -> Vector3:
	return Vector3.RIGHT * offset


func get_tip() -> Vector3:
	var direction := Vector3.RIGHT
	direction = direction.rotated(Vector3.DOWN, sweep)
	direction = direction.rotated(Vector3.BACK, dihedral)
	var tip := direction * get_console_length() / direction.x
	return get_base() + tip


func has_flap() -> bool:
	return flap_start != flap_end and flap_fraction > 0.0


func has_aileron() -> bool:
	return aileron_start != aileron_end and aileron_fraction > 0.0


func get_console_length() -> float:
	return span / 2.0 - offset if mirror else span - offset


func get_mac() -> float:
	return 2.0 / 3.0 * chord * (1.0 + taper + taper * taper) / (1.0 + taper)


func get_mac_right_position() -> float:
	var length := get_console_length() * 2.0 if mirror else get_console_length()
	return length / 6.0 * (1.0 + 2.0 * taper) / (1.0 + taper)


func get_mac_forward_position() -> float:
	var mac := get_mac()
	var pos := mac / 4.0 * (1.0 - taper)
	if sweep != 0.0:
		pos += tan(sweep) * get_mac_right_position()
	return pos - (chord - mac) * 0.5


func get_force() -> Vector3:
	return _force


func get_torque() -> Vector3:
	return _torque


func get_section_count() -> int:
	return len(_sections)


func get_section_chord(index: int) -> float:
	return _sections[index].chord


func get_section_control_surface_fraction(index: int) -> float:
	return _sections[index].control_surface_fraction


func get_section_transform(index: int) -> Transform3D:
	return _sections[index].transform


func get_section_length(index: int) -> float:
	return _sections[index].length


func is_section_stall(index: int) -> bool:
	return _sections[index].stall


func is_section_stall_warning(index: int) -> bool:
	return _sections[index].stall_warning


func get_section_control_surface_angle(index: int) -> float:
	return _sections[index].control_surface_angle
