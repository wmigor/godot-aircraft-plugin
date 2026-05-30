extends VehiclePropellerBase3D
class_name VehiclePropeller3D

@export var airfoil: Airfoil
@export var blade_count := 2.0
@export var root_chord := 0.102
@export var tip_chord := 0.076
@export var mid_chord := 0.125
@export_range(0.0, 1.0, 0.001) var mid_fraction := 0.35
@export_range(0.0, 10.0, 0.001) var roundness := 2.0
@export var section_count := 20
@export var hub_radius := 0.2

@export_range(-75, 75, 0.001, "radians_as_degrees")
var root_pitch := deg_to_rad(27.0)

@export_range(-75, 75, 0.001, "radians_as_degrees")
var tip_pitch := deg_to_rad(12.0)

@export_range(0.01, 10.0, 0.001)
var pitch_power := 2.0

@export var sound_speed := 340.3

@export_range(0.01, 0.5) var induction_relaxation := 0.15

class Section extends Airfoil.Data:
	var radius: float
	var area: float
	var pitch : float
	var sigma: float
	var width: float
	var total_velocity: float
	var axial_velocity_induced: float = 0.0
	var tangent_velocity_induced: float = 0.0


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
		section.sigma = blade_count * section.chord / (2 * PI * section.radius)
		_sections.append(section)


func _get_chord(fraction: float) -> float:
	if fraction < mid_fraction:
		return lerpf(root_chord, mid_chord, 1.0 - pow(1.0 - fraction / mid_fraction, roundness))
	return lerpf(mid_chord, tip_chord, pow((fraction - mid_fraction) / (1.0 - mid_fraction), roundness))


func tip_loss(section: Section, phi: float) -> float:
	if phi <= 0.001:
		return 1.0
	var r := section.radius
	var tip := prandtl(section, radius - r, r, phi)
	var hub := prandtl(section, r - hub_radius, r, phi)
	return maxf(tip * hub, 0.01)


func prandtl(section: Section, dr: float, r: float, phi: float) -> float:
	var s_phi := sin(phi)
	if s_phi <= 0.001: return 1.0
	var f := blade_count * dr / (2.0 * r * s_phi)
	if f > 500.0:
		return 1.0
	return 2.0 * acos(min(1.0, exp(-f))) / PI


func airfoil_forces(section: Section, phi: float) -> Vector2:
	var alpha := section.pitch - phi
	section.angle_of_attack = alpha
	airfoil.update_factors(section)
	_apply_mach_factor(section, section.total_velocity)

	var Cl = section.lift_factor
	var Cd = section.drag_factor

	var CT = Cl * cos(phi) - Cd * sin(phi)
	var CQ = Cl * sin(phi) + Cd * cos(phi)
	return Vector2(CT, CQ)


func _calculate_factors(wind_velocity: float) -> void:
	if abs(wind_velocity) < 0.1:
		wind_velocity = 0.1 * signf(wind_velocity)

	var omega := angular_velocity
	var total_thrust := 0.0
	var total_torque := 0.0

	for section in _sections:
		section.wind = 100 * Vector3.FORWARD
		var r := section.radius

		var U_axial := wind_velocity + section.axial_velocity_induced
		var U_tangent := (omega * r) - section.tangent_velocity_induced

		var U_res := sqrt(U_axial**2 + U_tangent**2)
		section.total_velocity = U_res

		var phi := atan2(U_axial, maxf(U_tangent, 0.001))
		#phi = clampf(phi, 0.001 * PI, 0.49 * PI)

		var factors := airfoil_forces(section, phi)
		var CT := factors.x
		var CQ := factors.y

		var dT := section.sigma * PI * density * U_res**2 * CT * r * section.width
		var dQ := section.sigma * PI * density * U_res**2 * CQ * r**2 * section.width

		total_thrust += dT
		total_torque += dQ

		var F := tip_loss(section, phi)

		var denominator_vi := 4.0 * PI * r * section.width * density * U_axial * F
		var vi_target := dT / denominator_vi if abs(denominator_vi) > 0.0001 else 0.0
		if vi_target < 0.0:
			vi_target = 0.0

		var denominator_v_prime := 4.0 * PI * pow(r, 3.0) * section.width * density * U_axial * F
		var v_prime_target := dQ / denominator_v_prime if abs(denominator_v_prime) > 0.0001 else 0.0

		section.axial_velocity_induced = lerpf(section.axial_velocity_induced, vi_target, induction_relaxation)
		section.tangent_velocity_induced = lerpf(section.tangent_velocity_induced, v_prime_target, induction_relaxation)

	var power_required := total_torque * omega
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


func _create_debug_view() -> Node3D:
	return preload("uid://chg4st6hc3rrf").new()
