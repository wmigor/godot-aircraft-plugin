@tool
extends Control

@export var airfoil: Airfoil

@onready var _angle_label := $GridContainer/Angle
@onready var _lift_label := $GridContainer/Lift
@onready var _drag_label := $GridContainer/Drag
@onready var _pitch_label := $GridContainer/Pitch
@onready var _deflection_label := $GridContainer/Deflection
@onready var _deflection := $Deflection as Slider
@onready var _aspect_ratio := $AspectRatio as Slider

var _interval := 180.0
var _cursor: Vector2
var _airfoil_data := Airfoil.Data.new()


func _ready() -> void:
	_update_deflection_text(_deflection.value)
	_deflection.value_changed.connect(_update_deflection_text)
	_deflection.value_changed.connect(func(value: float): $Deflection/Label.text = str(value))
	_aspect_ratio.value_changed.connect(func(value: float): $AspectRatio/Label.text = str(value))
	_airfoil_data.control_surface_fraction = 0.4


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var pos := get_viewport().get_mouse_position()
		_set_mouse_position(pos)
	queue_redraw()


func _draw() -> void:
	_draw_axis()
	_draw_plot()
	_draw_cursor()


func _draw_axis() -> void:
	var rect := get_rect()
	var center := rect.get_center()
	draw_line(Vector2(0.0, center.y), Vector2(rect.size.x, center.y), Color.WHITE)
	draw_line(Vector2(center.x, 0.0), Vector2(center.x, rect.size.y), Color.WHITE)


func _draw_cursor() -> void:
	var rect := get_rect()
	draw_line(Vector2(_cursor.x, 0.0), Vector2(_cursor.x, rect.size.y), Color.ORANGE)


func _update_deflection_text(value: float) -> void:
	_deflection_label.text = str(value)


func _draw_plot() -> void:
	var rect := get_rect()
	var max_value := 2.2
	var lift_scale := rect.size.y / max_value / 2.0
	var center := rect.get_center()
	var x := 0.0
	var lift_points := PackedVector2Array()
	var drag_points := PackedVector2Array()
	var pitches_points := PackedVector2Array()
	_airfoil_data.aspect_ratio = _aspect_ratio.value
	_airfoil_data.control_surface_angle = deg_to_rad(_deflection.value)
	while x <= rect.size.x:
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
	return wrapf(deg_to_rad(x * 360.0 * s / get_rect().size.x - _interval), -PI, PI)


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		_set_mouse_position(motion.position)
	elif event.is_action_pressed("ui_up"):
		_interval -= 10.0
	elif event.is_action_pressed("ui_down"):
		_interval += 10.0


func _set_mouse_position(pos: Vector2) -> void:
	_airfoil_data.angle_of_attack = _map_x_to_angle(pos.x)
	_airfoil_data.aspect_ratio = _aspect_ratio.value
	_airfoil_data.stall = false
	_airfoil_data.control_surface_angle = deg_to_rad(_deflection.value)
	airfoil.update_factors(_airfoil_data)
	_cursor = pos
	_angle_label.text = str(snappedf(rad_to_deg(_airfoil_data.angle_of_attack), 0.001))
	_lift_label.text = str(snappedf(_airfoil_data.lift_factor, 0.001))
	_drag_label.text = str(snappedf(_airfoil_data.drag_factor, 0.001))
	_pitch_label.text = str(snappedf(_airfoil_data.pitch_factor, 0.001))
