extends Control
class_name PlotsView

@export var show_grid := true
@export var grid_color := Color(0.5, 0.5, 0.5)
@export var axis_color := Color(0.8, 0.8, 0.8)

@export var margin_left := 40
@export var margin_right := 20
@export var margin_top := 40
@export var margin_bottom := 40


class Data:
	var points: PackedVector2Array
	var color: Color
	var width: float
	var draw_points: float

	func _init(points_: PackedVector2Array, color_:=Color.BLUE, width_:=1.0, draw_points_:=false) -> void:
		self.points = points_
		self.color = color_
		self.width = width_
		self.draw_points = draw_points_


class GridSettings:
	var start: float
	var end: float
	var step: float


var _plots: Array[Data]
var _cursor_label := Label.new()
var _min: Vector2
var _max: Vector2


func _ready():
	add_child(_cursor_label)
	queue_redraw()


func _draw():
	if _plots.is_empty():
		return
	if show_grid:
		_draw_grid()
	_draw_axes()
	_draw_plots()


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion:
		_cursor_label.text = "Cursor: " + str(_screen_to_data(motion.position))


func add_plot(plot: Data) -> void:
	_plots.append(plot)
	_update_bounds();
	queue_redraw()


func clear() -> void:
	_plots.clear()
	queue_redraw()


func _update_bounds():
	if _plots.is_empty() or _plots[0].points.is_empty():
		return

	_min.x = _plots[0].points[0].x
	_max.x = _plots[0].points[0].x
	_min.y = _plots[0].points[0].y
	_max.y = _plots[0].points[0].y

	for plot in _plots:
		if plot.points.is_empty():
			continue
		for point in plot.points:
			_min.x = minf(_min.x, point.x)
			_max.x = maxf(_max.x, point.x)
			_min.y = minf(_min.y, point.y)
			_max.y = maxf(_max.y, point.y)

	var x_padding := (_max.x - _min.x) * 0.05
	var y_padding := (_max.y - _min.y) * 0.05
	_min.x -= x_padding
	_max.x += x_padding
	_min.y -= y_padding
	_max.y += y_padding


func _data_to_screen(point: Vector2) -> Vector2:
	var screen_x := margin_left + (point.x - _min.x) / (_max.x - _min.x) * (size.x - margin_left - margin_right)
	var screen_y := margin_top + (1.0 - (point.y - _min.y) / (_max.y - _min.y)) * (size.y - margin_top - margin_bottom)
	return Vector2(screen_x, screen_y)


func _screen_to_data(screen_pos: Vector2) -> Vector2:
	var data_x := _min.x + (screen_pos.x - margin_left) / (size.x - margin_left - margin_right) * (_max.x - _min.x)
	var data_y := _min.y + (1.0 - (screen_pos.y - margin_top) / (size.y - margin_top - margin_bottom)) * (_max.y - _min.y)
	return Vector2(data_x, data_y)


func _draw_grid():
	var x_bounds := _get_nice_grid_settings(_min.x, _max.x, 10)
	var y_bounds := _get_nice_grid_settings(_min.y, _max.y, 10)

	var x := x_bounds.start
	while x <= x_bounds.end:
		var screen_x := _data_to_screen(Vector2(x, 0)).x
		if screen_x >= margin_left and screen_x <= size.x - margin_right:
			draw_line(Vector2(screen_x, margin_top), Vector2(screen_x, size.y - margin_bottom),
				grid_color, 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(screen_x - 10, size.y - margin_bottom + 15),
				str(x), HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		x += x_bounds.step

	var y := y_bounds.start
	while y <= y_bounds.end:
		var screen_y := _data_to_screen(Vector2(0, y)).y
		if screen_y >= margin_top and screen_y <= size.y - margin_bottom:
			draw_line(Vector2(margin_left, screen_y), Vector2(size.x - margin_right, screen_y),
				 grid_color, 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(margin_left - 35, screen_y + 5), str(y),
				 HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		y += y_bounds.step


func _draw_axes():
	var x_axis_y := clampf(_data_to_screen(Vector2(0, 0)).y, margin_top, size.y - margin_bottom)
	draw_line(Vector2(margin_left, x_axis_y), Vector2(size.x - margin_right, x_axis_y), axis_color, 1.5)
	var y_axis_x := clampf(_data_to_screen(Vector2(0, 0)).x, margin_left, size.x - margin_right)
	draw_line(Vector2(y_axis_x, margin_top), Vector2(y_axis_x, size.y - margin_bottom), axis_color, 1.5)


func _draw_plots():
	var points_packed := PackedVector2Array()
	for plot in _plots:
		points_packed.clear()
		for point in plot.points:
			var screen_point := _data_to_screen(point)
			points_packed.append(screen_point)
		if points_packed.size() > 1:
			draw_polyline(points_packed, plot.color, plot.width, true)
		if plot.draw_points:
			for point in points_packed:
				draw_circle(point, plot.width * 1.5, plot.color)


func _get_nice_grid_step(distance: float, line_count := 8) -> float:
	var rough_step := distance / line_count
	var magnitude := pow(10.0, floor(log(rough_step) / log(10.0)))
	var normalized := distance / magnitude
	var nice_step := 5.0
	if normalized < 1.5:
		nice_step = 1.0
	elif normalized < 3.0:
		nice_step = 2.0
	elif normalized < 7.0:
		nice_step = 5.0
	return nice_step * magnitude


func _get_nice_grid_settings(min_value: float, max_value: float, line_count) -> GridSettings:
	var distance := max_value - min_value
	if distance < 1e-10:
		distance = 1.0
		min_value -= 0.5
		max_value += 0.5
	var settings := GridSettings.new()
	settings.step = _get_nice_grid_step(distance, line_count)
	settings.start = floorf(min_value / settings.step) * settings.step
	settings.end = ceilf(max_value / settings.step) * settings.step
	if settings.start == settings.end:
		settings.end = settings.start + settings.step
	return settings
