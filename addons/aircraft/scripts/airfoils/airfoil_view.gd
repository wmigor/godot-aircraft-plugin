@tool
extends Control
class_name AirfoiView

@export var airfoil: Airfoil
@export_range(0, 0.9, 0.001) var control_surface_fraction := 0.4
@export_range(-50, 50, 1) var control_surface_agnle := 0.0
@export_range(0, 100, 0.1) var aspect_ratio := 0.0

var _interval := 180.0
var _cursor: Vector2
var _airfoil_data := Airfoil.Data.new()
var _angle_label := Label.new()
var _lift_label := Label.new()
var _drag_label := Label.new()
var _pitch_label := Label.new()
var _grid := GridContainer.new()
var _control_surface_angle_slider := HSlider.new()
var _aspect_ratio_slider := HSlider.new()


func _ready() -> void:
	_build_controls()
	if airfoil == null:
		airfoil = AirfoilFormula.new()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_set_mouse_position(get_local_mouse_position())
	queue_redraw()


func _draw() -> void:
	_draw_axis()
	_draw_plot()
	_draw_cursor()


func _draw_axis() -> void:
	var center := size * 0.5
	draw_line(Vector2(0.0, center.y), Vector2(size.x, center.y), Color.WHITE)
	draw_line(Vector2(center.x, 0.0), Vector2(center.x, size.y), Color.WHITE)


func _draw_cursor() -> void:
	var x := _cursor.x
	draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color.ORANGE)


func _draw_plot() -> void:
	if airfoil == null:
		return
	var rect := get_rect()
	var max_value := 2.2
	var lift_scale := size.y / max_value / 2.0
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
		lift_points.append(Vector2(x, center.y - _airfoil_data.lift_factor * lift_scale))
		drag_points.append(Vector2(x, center.y - _airfoil_data.drag_factor * lift_scale))
		pitches_points.append(Vector2(x, center.y - _airfoil_data.pitch_factor * lift_scale))
		x += 1
	draw_polyline(lift_points, Color.GREEN, 1.0, true)
	draw_polyline(drag_points, Color.RED, 1.0, true)
	draw_polyline(pitches_points, Color.YELLOW, 1.0, true)


func _map_x_to_angle(x: float) -> float:
	var s := _interval / 180.0
	return wrapf(deg_to_rad(x * 360.0 * s / size.x - _interval), -PI, PI)


func _input(event: InputEvent) -> void:
	if event as InputEventMouseMotion:
		_set_mouse_position(get_local_mouse_position())
	elif event.is_action_pressed("ui_up"):
		_interval -= 10.0
	elif event.is_action_pressed("ui_down"):
		_interval += 10.0


func _set_mouse_position(pos: Vector2) -> void:
	_airfoil_data.angle_of_attack = _map_x_to_angle(pos.x)
	_airfoil_data.aspect_ratio = aspect_ratio
	_airfoil_data.stall = false
	_airfoil_data.control_surface_angle = deg_to_rad(control_surface_agnle)
	if airfoil != null:
		airfoil.update_factors(_airfoil_data)
	_cursor = pos
	_angle_label.text = str(snappedf(rad_to_deg(_airfoil_data.angle_of_attack), 0.001))
	_lift_label.text = str(snappedf(_airfoil_data.lift_factor, 0.001))
	_drag_label.text = str(snappedf(_airfoil_data.drag_factor, 0.001))
	_pitch_label.text = str(snappedf(_airfoil_data.pitch_factor, 0.001))


func _build_controls() -> void:
	_grid.columns = 2
	_grid.size = Vector2(256, 256)
	_grid.position = Vector2(0, 0)
	add_child(_grid)
	_add_to_grid(_angle_label, "Angle", Color.WHITE)	
	_add_to_grid(_lift_label, "Lift", Color.GREEN)	
	_add_to_grid(_drag_label, "Drag", Color.RED)	
	_add_to_grid(_pitch_label, "Pitch", Color.YELLOW)
	_add_to_grid(_control_surface_angle_slider, "Deflection", Color.WHITE)
	_add_to_grid(_aspect_ratio_slider, "Aspect ratio", Color.WHITE)
	_aspect_ratio_slider.max_value = 100
	_control_surface_angle_slider.min_value = -50
	_control_surface_angle_slider.max_value = 50
	_aspect_ratio_slider.value_changed.connect(func(value): aspect_ratio = value)
	_control_surface_angle_slider.value_changed.connect(func(value): control_surface_agnle = value)


func _add_to_grid(control: Control, title: String, color: Color) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.modulate = color
	control.modulate = color
	_grid.add_child(title_label)
	_grid.add_child(control)
	control.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
