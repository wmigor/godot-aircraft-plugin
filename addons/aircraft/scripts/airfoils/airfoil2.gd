@tool
extends Airfoil
class_name Airfoil2

@export var lift_slope := TAU:
	set(value):
		lift_slope = value
		emit_changed()

@export_range(0, 19, 0.001, "radians_as_degrees") var stall_angle := deg_to_rad(15.0):
	set(value):
		stall_angle = value
		emit_changed()

@export_range(-10, 10, 0.001, "radians_as_degrees") var zero_lift_angle := 0.0:
	set(value):
		zero_lift_angle = value
		emit_changed()

@export var zero_pitch := -0.1:
	set(value):
		zero_pitch = value
		emit_changed()

@export var pitch_slope := -0.75:
	set(value):
		pitch_slope = value
		emit_changed()

@export var drag_max := 1.3:
	set(value):
		drag_max = value
		emit_changed()


func update_factors(data: Data) -> void:
	var oswald := 0.85
	var alpha := data.angle_of_attack
	var alpha_stall := deg_to_rad(14.0) + deg_to_rad(2.0) * log(data.re / 5.0e+5) / log(10.0)
	var lift_slope_correct := lift_slope if data.aspect_ratio <= 0.0 else lift_slope / (1.0 + lift_slope / (oswald * PI * data.aspect_ratio))
	var lift_control := 0.5 * lift_slope * data.control_surface_angle
	var liftNormal := lift_slope_correct * (alpha - zero_lift_angle) + lift_control
	var lift_stalled := 2.0 * signf(alpha) * sin(alpha) * sin(alpha) * cos(alpha)
	var stall_factor := _get_stall_factor(alpha, alpha_stall)
	data.lift_factor = (1.0 - stall_factor) * liftNormal + stall_factor * lift_stalled

	var drag_min := 0.455 / pow(log(data.re) / log(10.0), 2.58)
	var drag_control := 0.1 * absf(data.control_surface_angle)
	var drag_normal := drag_min + drag_control
	var drag_stalled := drag_max * pow(sin(alpha), 2.0) + drag_min * pow(cos(alpha), 2.0)
	data.drag_factor = (1.0 - stall_factor) * drag_normal + stall_factor * drag_stalled
	if data.aspect_ratio > 0.0:
		data.drag_factor += data.lift_factor * data.lift_factor / (PI * data.aspect_ratio * oswald)
	
	var pitch_control := -0.5 * data.control_surface_angle
	var pitch_normal := zero_pitch + pitch_control
	var pitch_stalled := -0.5 * drag_max * sin(PI / 2) * sin(2.0 * alpha)
	data.pitch_factor = (1.0 - stall_factor) * pitch_normal + stall_factor * pitch_stalled

	data.stall_warning = stall_factor > 0.0
	data.stall = stall_factor > 0.5

func _get_stall_factor(aoa: float, stall_aoa: float) -> float:
	var stall_width := deg_to_rad(4.0)
	if absf(aoa) < stall_aoa - stall_width * 0.5:
		return 0.0
	if absf(aoa) > stall_aoa + stall_width * 0.5:
		return 1.0
	var w := (absf(aoa) - stall_aoa + stall_width * 0.5) / stall_width
	return w * w * (3.0 - 2.0 * w)
