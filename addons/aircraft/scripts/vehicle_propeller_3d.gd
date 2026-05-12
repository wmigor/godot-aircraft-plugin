@tool
extends VehiclePropellerBase3D
class_name VehiclePropeller3D

@export var airfoil: Airfoil
@export var blade_count := 2.0
@export var root_chord := 0.102
@export var tip_chord := 0.076
@export var section_count := 10
@export var hub_radius := 0.15
@export_range(-75, 75, 0.001, "radians_as_degrees") var root_pitch := deg_to_rad(40.0)
@export_range(-75, 75, 0.001, "radians_as_degrees") var tip_pitch := deg_to_rad(12.7)
@export var sound_speed := 340.3


class Section extends Airfoil.Data:
	var radius: float
	var area: float
	var pitch : float
	var velocity_induced: float
	var velocity_induced_tangent: float


var _sections: Array[Section]


func _ready() -> void:
	var blade_length := radius - hub_radius
	var section_length := blade_length / section_count
	var blade_area := (root_chord + tip_chord) * 0.5 * blade_length
	var aspect_ratio := (blade_length * blade_length / blade_area) if blade_area > 0 else 1.0
	for section_index in section_count:
		var section := Section.new()
		section.radius = hub_radius + section_index * section_length + section_length * 0.5
		var fraction := (section.radius - hub_radius) / blade_length
		section.chord = lerpf(root_chord, tip_chord, fraction)
		section.area = section_length * section.chord
		section.pitch = lerpf(root_pitch, tip_pitch, fraction)
		section.aspect_ratio = aspect_ratio
		_sections.append(section)


func _calculate_factors(wind_velocity: float) -> void:
	var total_thrust := 0.0
	var total_torque := 0.0
	for section in _sections:
		var forward_velocity := wind_velocity + section.velocity_induced
		var tangent_velocity := absf(angular_velocity) * section.radius - section.velocity_induced_tangent
		var flow_velocity_squared := forward_velocity ** 2 + tangent_velocity ** 2
		var flow_velocity := sqrt(flow_velocity_squared)
		var flow_angle := atan2(forward_velocity, tangent_velocity)
		var aoa := section.pitch - flow_angle
		section.angle_of_attack = aoa
		airfoil.update_factors(section)
		_apply_mach_factor(section, flow_velocity)
		var section_thrust_factor := section.lift_factor * cos(flow_angle) - section.drag_factor * sin(flow_angle)
		var section_torque_factor := section.lift_factor * sin(flow_angle) + section.drag_factor * cos(flow_angle)
		var section_thrust := 0.5 * density * flow_velocity_squared * blade_count * section.area * section_thrust_factor
		var section_torque := 0.5 * density * flow_velocity_squared * blade_count * section.area * section.radius * section_torque_factor
		var f := _get_tip_loss(section, flow_angle)

		var v_i_target : float
		if forward_velocity < 0.1:
			v_i_target = sqrt(maxf(0.0, section_thrust / (2.0 * density * PI * section.radius * 2.0 * f)))
		else:
			v_i_target = section_thrust / (4.0 * PI * section.radius * density * forward_velocity * f + 1e-6)

		var v_it_target := section_torque / (4.0 * PI * pow(section.radius, 2) * density * forward_velocity * f + 1e-6)

		section.velocity_induced = lerpf(section.velocity_induced, v_i_target, 0.1)
		section.velocity_induced_tangent = lerpf(section.velocity_induced_tangent, v_it_target, 0.1)
		forward_velocity = wind_velocity + section.velocity_induced
		flow_velocity_squared = forward_velocity ** 2 + tangent_velocity ** 2
		flow_velocity = sqrt(flow_velocity_squared)
		flow_angle = atan2(forward_velocity, tangent_velocity)
		aoa = section.pitch - flow_angle
		section.angle_of_attack = aoa
		section.wind = Vector3.BACK * flow_velocity
		airfoil.update_factors(section)
		_apply_mach_factor(section, flow_velocity)

		section_thrust_factor = section.lift_factor * cos(flow_angle) - section.drag_factor * sin(flow_angle)
		section_torque_factor = section.lift_factor * sin(flow_angle) + section.drag_factor * cos(flow_angle)
		total_thrust += 0.5 * density * flow_velocity_squared * blade_count * section.area * section_thrust_factor
		total_torque += 0.5 * density * flow_velocity_squared * blade_count * section.area * section.radius * section_torque_factor
	var power_required := total_torque * angular_velocity
	var diameter := radius * 2.0
	var safe_rps := maxf(0.01, absf(rps))
	_thrust_factor = total_thrust / (pow(safe_rps, 2.0) * pow(diameter, 4.0) * density)
	_power_required_factor = power_required / (pow(safe_rps, 3.0) * pow(diameter, 5.0) * density)


func _apply_mach_factor(section: Section, total_velocity: float) -> void:
	var mach := total_velocity / sound_speed
	var mach_factor := 1.0 / sqrt(1.0 - pow(minf(mach, 0.7), 2))
	section.lift_factor *= mach_factor
	section.drag_factor *= mach_factor
	if mach > 0.7:
		var wave_factor := (mach - 0.7) ** 2
		var wave_drag := wave_factor * 20.0
		section.drag_factor += wave_drag
		section.lift_factor *= (1.0 - wave_factor * 10.0)


func _get_tip_loss(section: Section, phi: float) -> float:
	var e := 0.5 * blade_count * (radius - section.radius) / (maxf(section.radius * sin(phi), 0.01))
	var f := (2.0 / PI) * acos(clampf(exp(-e), 0.0, 1.0))
	f = maxf(f, 0.01)
	return f


func _create_debug_view() -> Node3D:
	return preload("uid://chg4st6hc3rrf").new()
