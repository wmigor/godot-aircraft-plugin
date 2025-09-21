@tool
extends Control

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

var _lift: Array[float]


func _process(_delta: float) -> void:
	queue_redraw()


func _make_plot() -> void:
	_lift.clear()


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
	var stall_angle := deg_to_rad(20.0)
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
	return max_lift - stall_drop - stalled_drop if angle > max_angle else min_lift + stall_drop + stalled_drop


func _draw() -> void:
	_draw_axis()
	_draw_plot()


func _draw_axis() -> void:
	var rect := get_rect()
	var center := rect.get_center()
	draw_line(Vector2(0.0, center.y), Vector2(rect.size.x, center.y), Color.WHITE)
	draw_line(Vector2(center.x, 0.0), Vector2(center.x, rect.size.y), Color.WHITE)


func _draw_plot() -> void:
	var rect := get_rect()
	var lift_scale := rect.size.y / max_lift / 2.0
	var center := rect.get_center()
	var start_pixel := rect.position.x
	var end_pixel := rect.end.x
	var x1 := start_pixel
	while x1 < end_pixel:
		var x2 := x1 + 1
		var angle1 := _map_x_to_angle(x1)
		var angle2 := _map_x_to_angle(x2)
		var lift1 := _get_lift(angle1)
		var lift2 := _get_lift(angle2)
		draw_line(Vector2(x1, center.y - lift1 * lift_scale), Vector2(x2, center.y - lift2 * lift_scale), Color.GREEN)
		x1 += 1


func _map_x_to_angle(x: float) -> float:
	return deg_to_rad(x * 360.0 / get_rect().size.x - 180.0)


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var angle := _map_x_to_angle(motion.position.x)
		var lift := _get_lift(angle)
		print("angle: {0}, lift: {1}".format([snappedf(rad_to_deg(angle), 0.001), lift]))
