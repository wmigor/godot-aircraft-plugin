@tool
extends Control
class_name VirtualStick

@export var _color := Color(0.5, 0.5, 0.5, 0.5)
@export var _pointer_color := Color.GRAY
@export var _reset_actions: Array[String] = [
		"aileron_left",
		"aileron_right",
		"aileron_left_key",
		"aileron_right_key",
		"elevator_up",
		"elevator_down",
		"elevator_up_key",
		"elevator_down_key"]

var _input_value: Vector2

var controller: PlayerAircraftController


func _input_to_point() -> Vector2:
	var x := (1.0 + clampf(_input_value.x, -1.0, 1.0)) * size.x * 0.5
	var y := (1.0 + clampf(_input_value.y, -1.0, 1.0)) * size.y * 0.5
	return Vector2(x, y)


func _point_to_input(point: Vector2) -> Vector2:
	var x := (2.0 * point.x / size.x - 1.0)
	var y := (2.0 * point.y / size.y - 1.0)
	return Vector2(clamp(x, -1.0, 1.0), clampf(y, -1.0, 1.0))


func _draw() -> void:
	var rect := Rect2(0.0, 0.0, size.x, size.y)
	draw_rect(rect, _color, false)
	_draw_cross(rect.get_center(), _color)
	_draw_cross(_input_to_point(), _pointer_color)


func _draw_cross(point: Vector2, color: Color, length := 10.0, width := 4.0) -> void:
	draw_line(point + Vector2.LEFT * length, point + Vector2.RIGHT * length, color, width)
	draw_line(point + Vector2.UP * length, point + Vector2.DOWN * length, color, width)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		_set_input(_point_to_input(button.position))
		return
	var motion := event as InputEventMouseMotion
	if motion != null and motion.pressure > 0.5:
		_set_input(_point_to_input(motion.position))
		return


func _input(event: InputEvent) -> void:
	for action in _reset_actions:
		if event.is_action(action):
			_set_input(Vector2.ZERO)


func _set_input(input: Vector2) -> void:
	_input_value = input
	if controller != null:
		controller.aileron_virtual = -_input_value.x
		controller.elevator_virtual = -_input_value.y
	queue_redraw()
