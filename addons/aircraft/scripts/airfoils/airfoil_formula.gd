@tool
extends Airfoil
class_name AirfoilFormula

## Determines how quickly the lift increases with the angle of rotation. For a normal wing it is 2 * PI.
@export var lift_slope := TAU
## Linear range of lift_slope
@export_range(0.0, 19.0, 0.001, "radians_as_degrees") var linear_range := deg_to_rad(10.0)
## Lift drop at begin stall
@export_range(0.0, 1.0, 0.001) var lift_drop := 0.0
## Lift drop power
@export_range(0.0, 9.0, 0.001) var lift_power := 1.0
## Zero lift angle of attack.
@export_range(-10, 10, 0.001, "radians_as_degrees") var zero_lift_angle := 0.0
## Positive stall angle.
@export_range(0, 19, 0.001, "radians_as_degrees") var stall_angle_max := deg_to_rad(15.0)
## Negative stall angle.
@export_range(-19, 0, 0.001, "radians_as_degrees") var stall_angle_min := deg_to_rad(-15.0)
## Distance in degrees between the beginning of the stall and the complete stall.
@export_range(0, 20, 0.001, "radians_as_degrees") var stall_width := deg_to_rad(5.0)
## Stall drop at begin stall
@export_range(0.0, 1.0, 0.001) var stall_drop := 0.0
#3 Stall drop power
@export_range(0.0, 9.0, 0.001) var stall_power := 1.4
## Surface friction factor.
@export_range(0, 0.3, 0.001) var surface_friction := 0.023
## Stall hysteresis is implemented here. This parameter determines the angle of attack at which normal flight conditions are restored after stall.
@export_range(0, 30, 0.001, "radians_as_degrees") var restore_stall_angle := deg_to_rad(5.0)
## Enables an alternative drag calculation method. If the aircraft seems to have too much drag, enable this option. Also, make sure to disable damping in the VehicleBody3D.
@export var alternative_drag := true

var _control_surface_lift: float
var _corrected_lift_slope: float
var _corrected_zero_lift_angle: float
var _corrected_stall_angle_max: float
var _corrected_stall_angle_min: float
var _restore_stall_angle_max: float
var _restore_stall_angle_min: float
var _correct_lift_factor: float
var _corrected_linear_max: float
var _corrected_linear_min: float


func update_factors(data: Data) -> void:
	_update_parameters(data)
	_calculate_factors(data)


func _update_parameters(data: Data) -> void:
	_correct_lift_factor = data.aspect_ratio / (data.aspect_ratio + 2.0 * (data.aspect_ratio + 4.0) / (data.aspect_ratio + 2.0)) if absf(data.aspect_ratio) > 0.0 else 1.0
	_corrected_lift_slope = lift_slope * _correct_lift_factor
	var control_surface_effectivness_factor := acos(2.0 * data.control_surface_fraction - 1.0)
	var control_surface_effectivness := 1.0 - (control_surface_effectivness_factor - sin(control_surface_effectivness_factor)) / PI
	_control_surface_lift = _corrected_lift_slope * control_surface_effectivness * _get_control_surface_lift_factor(data.control_surface_angle) * data.control_surface_angle
	_corrected_zero_lift_angle = zero_lift_angle - _control_surface_lift / _corrected_lift_slope
	var control_surface_lift_max := _get_control_surface_lift_max(data.control_surface_fraction)
	var max_lift := _corrected_lift_slope * (stall_angle_max - zero_lift_angle) + _control_surface_lift * control_surface_lift_max
	var min_lift := _corrected_lift_slope * (stall_angle_min - zero_lift_angle) + _control_surface_lift * control_surface_lift_max
	_corrected_stall_angle_max = _corrected_zero_lift_angle + max_lift / _corrected_lift_slope
	_corrected_stall_angle_min = _corrected_zero_lift_angle + min_lift / _corrected_lift_slope
	max_lift = _corrected_lift_slope * (linear_range - zero_lift_angle) + _control_surface_lift * control_surface_lift_max
	min_lift = _corrected_lift_slope * (-linear_range - zero_lift_angle) + _control_surface_lift * control_surface_lift_max
	_corrected_linear_max = _corrected_zero_lift_angle + max_lift / _corrected_lift_slope
	_corrected_linear_min = _corrected_zero_lift_angle + min_lift / _corrected_lift_slope
	_update_section_hysteresis_stall(data)


func _calculate_factors(data: Data) -> void:
	var stall_angle_max := _restore_stall_angle_max if data.stall else _corrected_stall_angle_max
	var stall_angle_min := _restore_stall_angle_min if data.stall else _corrected_stall_angle_min

	if data.angle_of_attack >= stall_angle_min and data.angle_of_attack <= stall_angle_max:
		var factors := _calculate_normal_factors(data, data.angle_of_attack)
		data.lift_factor = factors.x
		data.drag_factor = factors.y
		data.pitch_factor = factors.z
		data.stall_warning = false
		return

	data.stall_warning = data.wind.length_squared() >= data.chord * data.chord
	var full_stall_angle_max := _corrected_stall_angle_max + stall_width
	var full_stall_angle_min := _corrected_stall_angle_min - stall_width

	if data.angle_of_attack > full_stall_angle_max or data.angle_of_attack < full_stall_angle_min:
		var factors := _calculate_stall_factors(data, data.angle_of_attack)
		data.lift_factor = factors.x
		data.drag_factor = factors.y
		data.pitch_factor = factors.z
		return

	var factors1: Vector3
	var factors2: Vector3
	var w: float

	if data.angle_of_attack > stall_angle_max:
		factors1 = _calculate_normal_factors(data, stall_angle_max)
		factors1.x -= stall_drop * _correct_lift_factor
		factors2 = _calculate_stall_factors(data, full_stall_angle_max)
		factors1.x -= stall_drop * _correct_lift_factor
		w = (data.angle_of_attack - stall_angle_max) / (full_stall_angle_max - stall_angle_max)
	else:
		factors1 = _calculate_normal_factors(data, stall_angle_min)
		factors1.x += stall_drop * _correct_lift_factor
		factors2 = _calculate_stall_factors(data, full_stall_angle_min)
		factors1.x += stall_drop * _correct_lift_factor
		w = (data.angle_of_attack - stall_angle_min) / (full_stall_angle_min - stall_angle_min)

	w = pow(w, stall_power)
	data.lift_factor = lerpf(factors1.x, factors2.x, w)
	data.drag_factor = lerpf(factors1.y, factors2.y, w)
	data.pitch_factor = lerpf(factors1.z, factors2.z, w)


func _get_normal_lift(data: Data, angle_of_attack: float) -> float:
	if angle_of_attack >= _corrected_linear_min and angle_of_attack <= _corrected_linear_max:
		return (angle_of_attack - _corrected_zero_lift_angle) * _corrected_lift_slope
	var lift_offset := _corrected_lift_slope * linear_range - _corrected_linear_max * _corrected_lift_slope
	var max_lift := (lift_slope * (stall_angle_max - zero_lift_angle) - lift_drop) * _correct_lift_factor + lift_offset
	if angle_of_attack >= _corrected_linear_max and angle_of_attack <= _corrected_stall_angle_max:
		var weight := (angle_of_attack - _corrected_linear_max) / (_corrected_stall_angle_max - _corrected_linear_max)
		var a := (_corrected_linear_max - _corrected_zero_lift_angle) * _corrected_lift_slope
		return lerpf(a, max_lift, 1.0 - pow(1.0 - weight, lift_power))
	var zero_angle_lift := -_corrected_zero_lift_angle * _corrected_lift_slope
	var z := -zero_lift_angle * lift_slope
	var min_lift := zero_angle_lift - max_lift + z
	if angle_of_attack >= _corrected_stall_angle_min and angle_of_attack <= _corrected_linear_min:
		var weight := (angle_of_attack - _corrected_stall_angle_min) / (_corrected_linear_min - _corrected_stall_angle_min)
		var b := (_corrected_linear_min - _corrected_zero_lift_angle) * _corrected_lift_slope
		return lerpf(min_lift, b, pow(weight, lift_power))
	return 0.0


func _calculate_normal_factors(data: Data, angle_of_attack: float) -> Vector3:
	var lift := _get_normal_lift(data, angle_of_attack)
	var induced_angle := lift / (PI * data.aspect_ratio) if absf(data.aspect_ratio) > 0.0 else 0.0
	var effective_angle := angle_of_attack - _corrected_zero_lift_angle - induced_angle
	var cos_ea := cos(effective_angle)
	var sin_ea := sin(effective_angle)
	var tangent := surface_friction * cos_ea
	var normal := (lift + sin_ea * tangent) / cos_ea if absf(cos_ea) >= 0.001 else 0.0
	var drag := _get_alternative_drag(data, lift) if alternative_drag else normal * sin_ea + tangent * cos_ea
	var pitch := -normal * _get_pitch_factor(effective_angle)
	return Vector3(lift, drag, pitch)


func _get_alternative_drag(data: Data, lift: float) -> float:
	var aspect_ratio := data.aspect_ratio if absf(data.aspect_ratio) > 0.0 else 50.0 
	var k := 1.0 / (PI * aspect_ratio * 0.8)
	var drag := surface_friction + k * lift * lift
	return drag
	

func _calculate_stall_factors(data: Data, angle_of_attack: float) -> Vector3:
	var stall_angle := _corrected_stall_angle_max if angle_of_attack > _corrected_stall_angle_max else _corrected_stall_angle_min
	var stall_lift := _corrected_lift_slope * (stall_angle - _corrected_zero_lift_angle)
	var induced_angle := stall_lift / (PI * data.aspect_ratio) if absf(data.aspect_ratio) > 0.0 else 0.0
	var half_pi := PI / 2.0
	var z := half_pi - _corrected_stall_angle_max if angle_of_attack > _corrected_stall_angle_max else -half_pi - _corrected_stall_angle_min
	var w := (half_pi - clampf(angle_of_attack, -half_pi, half_pi)) / z if absf(z) >= 0.001 else 0.0
	induced_angle = lerpf(0.0, induced_angle, clampf(w, 0.0, 1.0))
	var effective_angle := angle_of_attack - _corrected_zero_lift_angle - induced_angle
	var sin_ea := sin(effective_angle)
	var cos_ea := cos(effective_angle)
	
	var e := exp(-17.0 / data.aspect_ratio) if absf(data.aspect_ratio) > 0.0 else 0.0
	var normal := _get_drag_max(data.control_surface_angle) * sin_ea * (1.0 / (0.56 + 0.44 * absf(sin_ea)) - 0.41 * (1.0 - e))
	var tangent := 0.5 * surface_friction * cos_ea

	var lift := normal * cos_ea - tangent * sin_ea
	var drag := normal * sin_ea + tangent * cos_ea
	var pitch := -normal * _get_pitch_factor(effective_angle)
	return Vector3(lift, drag, pitch)


func _update_section_hysteresis_stall(data: Data) -> void:
	if data.wind.length_squared() < data.chord * data.chord:
		data.stall = false
		return
	var start_hysteresis_angle_max := _corrected_stall_angle_max + stall_width
	var start_hysteresis_angle_min := _corrected_stall_angle_min - stall_width
	_restore_stall_angle_max = minf(_corrected_stall_angle_max, restore_stall_angle)
	_restore_stall_angle_min = minf(_corrected_stall_angle_min, -restore_stall_angle)
	if not data.stall and (data.angle_of_attack >= start_hysteresis_angle_max or data.angle_of_attack <= start_hysteresis_angle_min):
		data.stall = true
	elif data.stall and data.angle_of_attack <= restore_stall_angle and data.angle_of_attack >= -restore_stall_angle:
		data.stall = false


func _get_control_surface_lift_factor(control_surface_angle: float) -> float:
	return lerpf(0.8, 0.4, (absf(rad_to_deg(control_surface_angle)) - 10.0) / 50.0)


func _get_control_surface_lift_max(control_surface_fraction: float) -> float:
	return clampf(1.0 - 0.5 * (control_surface_fraction - 0.1) / 0.3, 0.0, 1.0)


func _get_pitch_factor(effective_angle: float) -> float:
	return 0.25 - 0.175 * (1.0 - 2.0 * effective_angle / PI)


func _get_drag_max(control_surface_angle: float) -> float:
	return 1.98 - 4.26e-2 * control_surface_angle * control_surface_angle + 2.1e-1 * control_surface_angle
