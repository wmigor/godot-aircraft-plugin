extends Resource
class_name Airfoil


func get_lift(_alpha: float, _deflection: float) -> float:
	return 0.0


func get_drag(_alpha: float, _deflection: float) -> float:
	return 0.0


func get_pitch(_alpha: float, _deflection: float) -> float:
	return 0.0


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
