@abstract
extends Resource
class_name Airfoil


#@abstract func get_coefficients(alpha: float, aspect_ratio: float, control_surface_angle: float, control_surface_fraction: float) -> Vector3
@abstract func get_lift(alpha: float, deflection: float) -> float
@abstract func get_drag(alpha: float, deflection: float) -> float
@abstract func get_pitch(alpha: float, deflection: float) -> float


static func get_inducd_lift(lift: float, aspect_ratio: float) -> float:
	if absf(aspect_ratio) < 0.001:
		return 0.0
	var s := signf(lift)
	lift = absf(lift)
	var corrected_lift := lift / (1.0 + lift / (PI * aspect_ratio))
	return (corrected_lift - lift) * s


static func get_induced_drag(lift: float, aspect_ratio: float) -> float:
	if absf(aspect_ratio) < 0.001:
		return 0.0
	var k := 1.0 / (PI * aspect_ratio * 0.8)
	var induced_drag := k * lift * lift
	return induced_drag
