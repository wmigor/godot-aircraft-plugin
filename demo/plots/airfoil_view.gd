extends Control

@export var airfoil: Airfoil

@onready var _angle_label := $GridContainer/Angle
@onready var _lift_label := $GridContainer/Lift
@onready var _drag_label := $GridContainer/Drag
@onready var _pitch_label := $GridContainer/Pitch
@onready var _deflection_label := $GridContainer/Deflection
@onready var _deflection := $Deflection as Slider
@onready var _aspect_ratio := $AspectRatio as Slider

var _lift: Array[float]
var _cursor: Vector2


func _ready() -> void:
	_update_deflection_text(_deflection.value)
	_deflection.value_changed.connect(_update_deflection_text)
	_deflection.value_changed.connect(func(value: float): $Deflection/Label.text = str(value))
	_aspect_ratio.value_changed.connect(func(value: float): $AspectRatio/Label.text = str(value))


func _process(_delta: float) -> void:
	queue_redraw()


func _make_plot() -> void:
	_lift.clear()


func _get_lift(angle: float) -> float:
	var deflection := deg_to_rad(_deflection.value)
	return airfoil.get_lift(angle, deflection) if airfoil != null else 0.0


func _get_drag(angle: float) -> float:
	var deflection := deg_to_rad(_deflection.value)
	return airfoil.get_drag(angle, deflection) if airfoil != null else 0.0


func _get_pitch(angle: float) -> float:
	var deflection := deg_to_rad(_deflection.value)
	return airfoil.get_pitch(angle, deflection) if airfoil != null else 0.0


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
	var aspect_ratio := _aspect_ratio.value
	while x <= rect.size.x:
		var angle := _map_x_to_angle(x)
		var lift := _get_lift(angle)
		var drag := _get_drag(angle)
		var pitch := _get_pitch(angle)
		lift += Airfoil.get_inducd_lift(lift, aspect_ratio)
		drag += Airfoil.get_induced_drag(lift, aspect_ratio)
		lift_points.append(Vector2(x, center.y - lift * lift_scale))
		drag_points.append(Vector2(x, center.y - drag * lift_scale))
		pitches_points.append(Vector2(x, center.y - pitch * lift_scale))
		x += 1
	draw_polyline(lift_points, Color.GREEN, 2.0, true)
	draw_polyline(drag_points, Color.RED, 2.0, true)
	draw_polyline(pitches_points, Color.YELLOW, 2.0, true)


func _map_x_to_angle(x: float) -> float:
	var interval := 180.0
	var s := interval / 180.0
	return deg_to_rad(x * 360.0 * s / get_rect().size.x - interval)


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var angle := _map_x_to_angle(motion.position.x)
		var lift := _get_lift(angle)
		var drag := _get_drag(angle)
		var pitch := _get_pitch(angle)
		_cursor = motion.position
		_angle_label.text = str(snappedf(rad_to_deg(angle), 0.001))
		_lift_label.text = str(snappedf(lift, 0.001))
		_drag_label.text = str(snappedf(drag, 0.001))
		_pitch_label.text = str(snappedf(pitch, 0.001))
