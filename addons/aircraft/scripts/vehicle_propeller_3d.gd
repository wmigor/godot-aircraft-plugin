@tool
extends VehiclePropellerBase3D
class_name VehiclePropeller3D

@export var airfoil: Airfoil
@export var blade_count := 2.0
@export var root_chord := 0.102
@export var tip_chord := 0.076
@export var mid_chord := 0.125
@export_range(0.0, 1.0, 0.001) var mid_fraction := 0.35
@export_range(0.0, 1.0, 0.001) var roundness := 1.0
@export var section_count := 20
@export var hub_radius := 0.3

@export_range(-75, 75, 0.001, "radians_as_degrees")
var root_pitch := deg_to_rad(25.0)

@export_range(-75, 75, 0.001, "radians_as_degrees")
var tip_pitch := deg_to_rad(12.0)

@export_range(0.01, 10.0, 0.001)
var pitch_power := 2.0

@export var sound_speed := 340.3


class Section extends Airfoil.Data:
	var radius: float
	var area: float
	var pitch : float
	var sigma: float
	var current_phi: float
	var width: float
	var total_velocity: float


var _sections: Array[Section]


func _ready() -> void:
	var blade_length := radius - hub_radius
	var section_length := blade_length / section_count
	for section_index in section_count:
		var section := Section.new()
		section.radius = hub_radius + section_index * section_length + section_length * 0.5
		var fraction := (section.radius - hub_radius) / blade_length
		section.chord = _get_chord(fraction)
		section.width = section_length
		section.area = section_length * section.chord
		section.pitch = lerpf(root_pitch, tip_pitch, pow(fraction, pitch_power))
		section.aspect_ratio = 0
		section.current_phi = section.pitch
		section.sigma = blade_count * section.chord / (2 * PI * section.radius)
		_sections.append(section)


func _get_chord(fraction: float) -> float:
	var chord_linear := 0.0
	if fraction < mid_fraction:
		chord_linear = lerpf(root_chord, mid_chord, fraction / mid_fraction)
	else:
		chord_linear = lerpf(mid_chord, tip_chord, (fraction - mid_fraction) / (1.0 - mid_fraction))
	var chord_bezier := (1.0 - fraction) * (1.0 - fraction) * root_chord + \
		 2.0 * (1.0 - fraction) * fraction * mid_chord + \
		 fraction * fraction * tip_chord
	return lerpf(chord_linear, chord_bezier, roundness)


func tip_loss(section: Section, phi: float) -> float:
	if phi == 0:
		return 1.0
	var r := section.radius
	var tip := prandtl(section, radius - r, r, phi)
	var hub := prandtl(section, r - hub_radius, r, phi)
	return tip * hub

func prandtl(section: Section, dr: float, r: float, phi: float) -> float:
	var f := blade_count * dr / (2 * r * (sin(phi)))
	if -f > 500:
		return 1.0
	return 2 * acos(min(1.0, exp(-f))) / PI

func airfoil_forces(section: Section, phi: float) -> Vector2:
	var C := 1.0
	var alpha := C * (section.pitch - phi)
	section.angle_of_attack = alpha
	airfoil.update_factors(section)
	_apply_mach_factor(section, section.total_velocity)
	var Cl = section.lift_factor
	var Cd = section.drag_factor
	var CT = Cl * cos(phi) - C * Cd * sin(phi)
	var CQ = Cl * sin(phi) + C * Cd * cos(phi)
	return Vector2(CT, CQ)

func induction_factors(section: Section, phi: float) -> Vector2:
	var C := 1.0
	var F := tip_loss(section, phi)
	var factors := airfoil_forces(section, phi)
	var CT := factors.x
	var CQ := factors.y
	var denominator_ct := section.sigma * CT
	var denominator_cq := section.sigma * CQ
	var kappa := (4 * F * sin(phi) ** 2 / denominator_ct) if abs(denominator_ct) > 0.000001 else 0.000001
	var kappap := (4 * F * sin(phi) * cos(phi) / denominator_cq) if abs(denominator_cq) > 0.000001 else 0.000001
	var a := 1.0 / (kappa - C)
	var ap := 1.0 / (kappap + C)
	return Vector2(a, ap)

func error(section: Section, phi: float, v_inf: float, omega: float) -> float:
	var C := 1.0
	var induction := induction_factors(section, phi)
	var a := induction.x
	var ap := induction.y
	var resid := sin(phi) / (1 + C * a) - v_inf * cos(phi) / (omega * section.radius * (1 - C * ap))
	return resid


func forces(section: Section, phi: float, v_inf: float, omega: float, rho: float) -> Vector2:
	var C := 1.0
	var r := section.radius
	var induction := induction_factors(section, phi)
	var a := induction.x
	var ap := induction.y

	var v := (1 + C * a) * v_inf
	var vp := (1 - C * ap) * omega * r
	var U := sqrt(v ** 2 + vp ** 2)
	section.total_velocity = U

	var factors := airfoil_forces(section, phi)
	var CT := factors.x
	var CQ := factors.y

	var dT := section.sigma * PI * rho * U ** 2 * CT * r * section.width
	var dQ := section.sigma * PI * rho * U ** 2 * CQ * r ** 2 * section.width

	return Vector2(dT, dQ)


func _calculate_factors2(wind_velocity: float) -> void:
	if abs(wind_velocity) < 1.0:
		wind_velocity = 1.0 * signf(wind_velocity)
	var total_thrust := 0.0
	var total_torque := 0.0
	for section in _sections:
		section.wind = 111 * Vector3.FORWARD
		var error := error(section, section.current_phi, wind_velocity, angular_velocity)
		section.current_phi -= error * 5.0 / 60.0
		section.current_phi = maxf(0.001 * PI, min(0.49 * PI, section.current_phi))
		var f := forces(section, section.current_phi, wind_velocity, angular_velocity, density)
		total_thrust += f.x
		total_torque += f.y
	var power_required := total_torque * angular_velocity
	var diameter := radius * 2.0
	var safe_rps := maxf(0.01, absf(rps))
	_thrust_factor = total_thrust / (pow(safe_rps, 2.0) * pow(diameter, 4.0) * density)
	_power_required_factor = power_required / (pow(safe_rps, 3.0) * pow(diameter, 5.0) * density)


func _calculate_factors(wind_velocity: float) -> void:
	if abs(wind_velocity) < 1.0:
		wind_velocity = 1.0 * signf(wind_velocity)
	var total_thrust := 0.0
	var total_torque := 0.0
	for section in _sections:
		section.wind = 111 * Vector3.FORWARD
		var axial_velocity := wind_velocity
		var tangent_velocity := angular_velocity * section.radius
		var total_velocity := sqrt(axial_velocity * axial_velocity + tangent_velocity * tangent_velocity)
		var flow_angle := atan2(axial_velocity, tangent_velocity)
		section.angle_of_attack = section.pitch - flow_angle
		airfoil.update_factors(section)
		var pressure := blade_count * 0.5 * section.area * density * absf(total_velocity) * total_velocity
		var lift := section.lift_factor * pressure
		var drag := section.drag_factor * pressure
		var cos_fa := cos(flow_angle)
		var sin_fa := sin(flow_angle)
		var delta_thrust := lift * cos_fa - drag * sin_fa
		var delta_torque := (lift * sin_fa + drag * cos_fa) * section.radius
		total_thrust += delta_thrust
		total_torque += delta_torque
	var power_required := total_torque * angular_velocity
	var diameter := radius * 2.0
	var safe_rps := maxf(0.01, absf(rps))
	_thrust_factor = total_thrust / (pow(safe_rps, 2.0) * pow(diameter, 4.0) * density)
	_power_required_factor = power_required / (pow(safe_rps, 3.0) * pow(diameter, 5.0) * density)


func _apply_mach_factor(section: Section, total_velocity: float) -> void:
	var mach := minf(total_velocity / sound_speed, 0.95)
	var mach_crit := 0.68

	if mach <= mach_crit:
		var prandtl_glauert := 1.0 / sqrt(1.0 - pow(mach, 2))
		section.lift_factor *= prandtl_glauert
		section.drag_factor *= prandtl_glauert
	else:
		var pg_at_crit := 1.0 / sqrt(1.0 - pow(mach_crit, 2))
		var cl_subsonic = section.lift_factor * pg_at_crit
		var cd_subsonic = section.drag_factor * pg_at_crit
		var m_excess := mach - mach_crit
		var wave_drag := 20.0 * pow(m_excess, 4.0)
		section.drag_factor = cd_subsonic + wave_drag
		var lift_drop_factor := maxf(0.1, 1.0 - 1.5 * pow(m_excess, 1.5))
		section.lift_factor = cl_subsonic * lift_drop_factor


func _get_tip_loss(section: Section, phi: float) -> float:
	var e := 0.5 * blade_count * (radius - section.radius) / (maxf(section.radius * sin(phi), 0.01))
	var f := (2.0 / PI) * acos(clampf(exp(-e), 0.0, 1.0))
	f = maxf(f, 0.01)
	return f


func _create_debug_view() -> Node3D:
	return preload("uid://chg4st6hc3rrf").new()
