@tool
extends Control

@export var airfoil: Airfoil
@export_range(0, 0.9, 0.001) var control_surface_fraction := 0.4
@export_range(-50, 50, 1) var control_surface_agnle := 0.0
@export_range(0, 100, 0.1) var aspect_ratio := 0.0
@export var max_value := 2.5
@export var grid_step := 0.2

var preview: bool
var interval := 180.0

var _cursor: Vector2
var _airfoil_data := Airfoil.Data.new()
var _lift: float
var _drag: float
var _pitch: float


func _ready() -> void:
	_build_controls()
	if airfoil == null:
		airfoil = AirfoilFormula.new()
	airfoil.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_set_mouse_position(get_local_mouse_position())


func _draw() -> void:
	_draw_grid()
	_draw_axis()
	_draw_plot()
	_draw_cursor()
	_draw_factors()


func _draw_grid() -> void:
	var count := int(max_value / grid_step)
	var v_scale := _get_vertical_scale()
	var center := size * 0.5
	var font_height := ThemeDB.fallback_font.get_height()
	for i in count:
		var value := (i + 1) * grid_step
		var y := value * v_scale
		draw_line(Vector2(0.0, center.y - y), Vector2(size.x, center.y - y), Color.SLATE_GRAY)
		draw_line(Vector2(0.0, center.y + y), Vector2(size.x, center.y + y), Color.SLATE_GRAY)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 30, center.y - y + font_height / 2.0), str(snappedf(value, 0.1)))
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 30, center.y + y + font_height / 2.0), str(snappedf(-value, 0.1)))


func _draw_axis() -> void:
	var center := size * 0.5
	draw_line(Vector2(0.0, center.y), Vector2(size.x, center.y), Color.WHITE)
	draw_line(Vector2(center.x, 0.0), Vector2(center.x, size.y), Color.WHITE)


func _draw_cursor() -> void:
	draw_line(Vector2(_cursor.x, 0.0), Vector2(_cursor.x, size.y), Color.ORANGE)
	draw_line(Vector2(0.0, _cursor.y), Vector2(size.x, _cursor.y), Color.ORANGE)
	var font := ThemeDB.fallback_font
	var font_height := font.get_height()
	var v_scale := _get_vertical_scale()
	var center := size * 0.5
	draw_string(font, Vector2(_cursor.x, size.y - font_height), str(snappedf(rad_to_deg(_map_x_to_angle(_cursor.x)), 0.001)) + "°")
	draw_string(font, Vector2(size.x - 90.0, _cursor.y + font_height * 0.5), str(snappedf((center.y - _cursor.y) / v_scale, 0.001)))


func _get_vertical_scale() -> float:
	return size.y / max_value / 2.0


func _draw_plot() -> void:
	if airfoil == null:
		return
	var rect := get_rect()
	var v_scale := _get_vertical_scale()
	var center := size * 0.5
	var x := 0.0
	var lift_points := PackedVector2Array()
	var drag_points := PackedVector2Array()
	var pitches_points := PackedVector2Array()
	_airfoil_data.aspect_ratio = aspect_ratio
	_airfoil_data.control_surface_angle = deg_to_rad(control_surface_agnle)
	_airfoil_data.control_surface_fraction = control_surface_fraction
	while x <= size.x:
		_airfoil_data.angle_of_attack = _map_x_to_angle(x)
		_airfoil_data.stall = false
		airfoil.update_factors(_airfoil_data)
		lift_points.append(Vector2(x, center.y - _airfoil_data.lift_factor * v_scale))
		drag_points.append(Vector2(x, center.y - _airfoil_data.drag_factor * v_scale))
		pitches_points.append(Vector2(x, center.y - _airfoil_data.pitch_factor * v_scale))
		x += 1
	draw_polyline(lift_points, Color.GREEN, 1.0, true)
	draw_polyline(drag_points, Color.RED, 1.0, true)
	draw_polyline(pitches_points, Color.YELLOW, 1.0, true)


func _draw_factors() -> void:
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	var font_height := font.get_height(font_size)
	var angle := rad_to_deg(_map_x_to_angle(_cursor.x))
	draw_string(font, Vector2(5, size.y - font_height - 3 * font_height), "Angle: " + str(snappedf(angle, 0.001)) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, size.y - font_height - 2 * font_height), "Lift: " + str(snappedf(_lift, 0.001)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.GREEN)
	draw_string(font, Vector2(5, size.y - font_height - 1 * font_height), "Drag: " + str(snappedf(_drag, 0.001)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)
	draw_string(font, Vector2(5, size.y - font_height - 0 * font_height), "Pitch: " + str(snappedf(_pitch, 0.001)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)


func _map_x_to_angle(x: float) -> float:
	var s := interval / 180.0
	return wrapf(deg_to_rad(x * 360.0 * s / size.x - interval), -PI, PI)


func _input(event: InputEvent) -> void:
	if event as InputEventMouseMotion:
		_set_mouse_position(get_local_mouse_position())
	elif event.is_action_pressed("ui_up"):
		interval -= 10.0
	elif event.is_action_pressed("ui_down"):
		interval += 10.0


func _set_mouse_position(pos: Vector2) -> void:
	if not get_rect().has_point(pos) or pos == _cursor:
		return
	_airfoil_data.angle_of_attack = _map_x_to_angle(pos.x)
	_airfoil_data.aspect_ratio = aspect_ratio
	_airfoil_data.stall = false
	_airfoil_data.control_surface_angle = deg_to_rad(control_surface_agnle)
	if airfoil != null:
		airfoil.update_factors(_airfoil_data)
	_cursor = pos
	_lift = _airfoil_data.lift_factor
	_drag = _airfoil_data.drag_factor
	_pitch = _airfoil_data.pitch_factor
	queue_redraw()


func _build_controls() -> void:
	if preview:
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size.x = 512
	grid.position = Vector2(10, 10)
	add_child(grid)
	var control_surface_slider := HSlider.new()
	var aspect_ratio_slider := HSlider.new()
	_add_slider_to_grid(grid, "Deflection", control_surface_slider)
	_add_slider_to_grid(grid, "Aspect ratio", aspect_ratio_slider)
	aspect_ratio_slider.max_value = 100
	control_surface_slider.min_value = -50
	control_surface_slider.max_value = 50
	aspect_ratio_slider.value_changed.connect(func(value): aspect_ratio = value)
	control_surface_slider.value_changed.connect(func(value): control_surface_agnle = value)


func _add_slider_to_grid(grid: GridContainer, title: String, slider: Slider) -> void:
	var title_label := Label.new()
	title_label.text = title
	var value_label := Label.new()
	value_label.text = "0.0"
	var container := HBoxContainer.new()
	container.add_child(value_label)
	container.add_child(slider)
	grid.add_child(title_label)
	grid.add_child(container)
	value_label.custom_minimum_size.x = 50
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	slider.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	value_label.size_flags_horizontal = Control.SIZE_FILL
	slider.value_changed.connect(func(value): value_label.text = str(value))
