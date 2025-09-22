extends Airfoil
class_name AirfoilFormula

@export var zero_angle_lift := 0.25
@export var lift_slope := TAU
@export var max_lift := 1.6
@export_range(-20.0, 0.0, 0.001, "radians_as_degrees") var min_angle := deg_to_rad(-15.0)
@export_range(0.0, 20.0, 0.001, "radians_as_degrees") var max_angle := deg_to_rad(15.0)
@export_range(0.0, 19.0, 0.001, "radians_as_degrees") var linear_range := deg_to_rad(10.0)
@export_range(0.0, 9.0, 0.001) var lift_power := 1.6
@export_range(0.0, 1.6, 0.001) var stall_drop := 0.1
@export_range(0.0, 1.6, 0.001) var stalled_drop := 0.8
@export_range(0.0, 9.0, 0.001) var stall_power := 1.4
@export var min_drag := 0.006
@export var max_drag := 0.02
@export_range(20.0, 180, 1.0) var interval := 180.0


var stall_angle := deg_to_rad(20.0)


func get_lift(alpha: float, _deflection: float) -> float:
	return _get_lift(alpha)


func get_drag(alpha: float, _deflection: float) -> float:
	if alpha >= 0.0 and alpha <= max_angle:
		return lerpf(min_drag, max_drag, alpha / max_angle)
	if alpha >= min_angle and alpha <= 0.0:
		return lerpf(max_drag, min_drag, -alpha / min_angle)
	var drag := 1.2 * sin(absf(alpha))
	if alpha >= max_angle and alpha <= stall_angle:
		var weight := (alpha - max_angle) / (stall_angle - max_angle)
		return lerpf(max_drag, drag, pow(weight, 2.4))
	if alpha >= -stall_angle and alpha <= min_angle:
		var weight := 1.0 - (alpha + stall_angle) / (min_angle + stall_angle)
		return lerpf(max_drag, drag, pow(weight, 2.4))
	return drag


func get_pitch(_alpha: float, _deflection: float) -> float:
	return 0.0


func _get_lift(angle: float) -> float:
	if angle >= -linear_range and angle <= linear_range:
		return zero_angle_lift + angle * lift_slope
	if angle > linear_range and angle <= max_angle:
		var weight := (angle - linear_range) / (max_angle - linear_range)
		var a := zero_angle_lift + linear_range * lift_slope
		return lerpf(a, max_lift, 1.0 - pow(1.0 - weight, lift_power))
	var min_lift := zero_angle_lift * 2.0 - max_lift
	if angle > min_angle and angle <= -linear_range:
		var weight := (angle - min_angle) / (-linear_range - min_angle)
		var a := zero_angle_lift - linear_range * lift_slope
		return lerpf(a, min_lift, 1.0 - pow(weight, lift_power))
	if angle > max_angle and angle < stall_angle:
		var a := max_lift - stall_drop
		var b := max_lift - stall_drop - stalled_drop
		var weight := (angle - max_angle) / (stall_angle - max_angle)
		return lerpf(a, b, pow(weight, stall_power))
	if angle <= min_angle and angle >= -stall_angle:
		var a := min_lift + stall_drop
		var b := min_lift + stall_drop + stalled_drop
		var weight := (min_angle - angle) / (stall_angle + min_angle)
		return lerpf(a, b, pow(weight, stall_power))
	var ta := PI / 4.0
	if angle >= stall_angle and angle <= ta:
		var a := max_lift - stall_drop - stalled_drop
		var b := sin(ta * 2.0) * 1.144
		var weight := (angle - stall_angle) / (ta - stall_angle)
		return lerpf(a, b, 1.0 - pow(1.0 - weight, 2.0))
	if angle >= -ta and angle <= -stall_angle:
		var a := min_lift + stall_drop + stalled_drop
		var b := sin(-ta * 2.0) * 1.144
		var weight := (-angle - stall_angle) / (ta - stall_angle)
		return lerpf(a, b, 1.0 - pow(1.0 - weight, 2.0))
	return sin(angle * 2.0) * 1.144
