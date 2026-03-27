extends Node2D

@export var plot_size := Vector2(180, 2)
@export var show_wing := false
@export var show_fuselage := false
@export var show_aircraft := true

@onready var _wing := $Wing as VehicleWing3D
@onready var flap := $VBoxContainer/Flap as HSlider
@onready var forward := $VBoxContainer/Forward as CheckBox
@onready var backward := $VBoxContainer/Backward as CheckBox
@onready var _fuselage := $Fuselage as VehicleFuselage3D
@onready var _aircraft := $"Cessna-172" as AircraftBody3D

var _total_wings: Array[VehicleWing3D]


func _ready() -> void:
	flap.value_changed.connect(func(_v): queue_redraw())
	forward.toggled.connect(func(_v): queue_redraw())
	backward.toggled.connect(func(_v): queue_redraw())
	_aircraft.set_physics_process(false)
	_aircraft.gravity_scale = 0.0
	for wing in _aircraft._wings:
		wing.set_physics_process(false)
	for wing in _aircraft._rudders:
		wing.set_physics_process(false)
	for wing in _aircraft._elevators:
		wing.set_physics_process(false)
	for fuselage in _aircraft._fuselages:
		fuselage.set_physics_process(false)
	for thruster in _aircraft._thrusters:
		thruster.set_physics_process(false)


func _draw() -> void:
	_draw_axis()
	var lift: Array[Vector2]
	var drag: Array[Vector2]
	var torque: Array[Vector2]
	if forward.button_pressed:
		_make_plots(true, lift, drag, torque)
		_draw_plots(lift, drag, torque)
	if backward.button_pressed:
		_make_plots(false, lift, drag, torque)
		_draw_plots(lift, drag, torque)


func _draw_plots(lift: Array[Vector2], drag: Array[Vector2], torque: Array[Vector2]) -> void:
	for i in len(lift) - 1:
		draw_line(lift[i], lift[i + 1], Color.RED)
		draw_line(drag[i], drag[i + 1], Color.GREEN)
		draw_line(torque[i], torque[i + 1], Color.YELLOW)


func _make_plots(forward_direction: bool, lift: Array[Vector2], drag: Array[Vector2], torque: Array[Vector2]) -> void:
	lift.clear()
	drag.clear()
	torque.clear()
	var d := 1.0 if forward_direction else - 1.0
	var x := -plot_size.x if forward_direction else plot_size.x
	while true:
		if show_fuselage:
			_add_plot_point_fuselage(x, lift, drag, torque)
		elif show_aircraft:
			_add_plot_point_aircraft(x, lift, drag, torque)
		else:
			_add_plot_point(x, lift, drag, torque)
		x += d
		if forward_direction && x > plot_size.x:
			break
		elif not forward_direction && x < -plot_size.x:
			break


func _add_plot_point(x: float, lift: Array[Vector2], drag: Array[Vector2], torque: Array[Vector2]) -> void:
	var linear_velocity := Vector3.FORWARD * _wing.chord * 2
	var to_factor := 2.0 / (_wing.span * _wing.get_mac() * _wing.density * linear_velocity.length_squared())
	_wing.rotation_degrees.x = x
	_wing.flap_value = flap.value
	for i in 4:
		_wing.calculate(linear_velocity, Vector3.ZERO, _wing.position)
	var force :=  _wing.get_force()
	lift.append(_to_viewport(Vector2(x, force.y * to_factor)))
	drag.append(_to_viewport(Vector2(x, force.z * to_factor)))
	torque.append(_to_viewport(Vector2(x, _wing.get_torque().x * to_factor)))


func _add_plot_point_fuselage(x: float, lift: Array[Vector2], drag: Array[Vector2], torque: Array[Vector2]) -> void:
	var linear_velocity := Vector3.FORWARD * _fuselage.length
	var to_factor := 2.0 / (_fuselage.length * _fuselage.midpoint_width * _fuselage.density * linear_velocity.length_squared())
	_fuselage.rotation_degrees.x = x
	for i in 4:
		_fuselage.calculate(linear_velocity, Vector3.ZERO, _fuselage.position)
	var force :=  _fuselage.get_force()
	lift.append(_to_viewport(Vector2(x, force.y * to_factor)))
	drag.append(_to_viewport(Vector2(x, force.z * to_factor)))
	torque.append(_to_viewport(Vector2(x, _fuselage.get_torque().x * to_factor)))


func _add_plot_point_aircraft(x: float, lifts: Array[Vector2], drags: Array[Vector2], torques: Array[Vector2]) -> void:
	var linear_velocity := Vector3.FORWARD * 100.0
	_aircraft.rotation_degrees.x = x
	var area := _get_aircraft_wing_area()
	_total_wings.clear()
	_total_wings.append_array(_aircraft._wings)
	_total_wings.append_array(_aircraft._rudders)
	_total_wings.append_array(_aircraft._elevators)
	for wing in _aircraft._wings:
		if wing.has_flap():
			wing.flap_value = flap.value
	for i in 4:
		for wing in _total_wings:
			wing.calculate(linear_velocity, Vector3.ZERO, _aircraft.center_of_mass)
		for fuselage in _aircraft._fuselages:
			fuselage.calculate(linear_velocity, Vector3.ZERO, _aircraft.center_of_mass)
	var force := Vector3.ZERO
	var torque := Vector3.ZERO
	for wing in _total_wings:
		force += wing.get_force()
		torque += wing.get_torque()
	for fuselage in _aircraft._fuselages:
		force += fuselage.get_force()
		torque += fuselage.get_torque()
	torque /= _aircraft._wings[0].get_mac()
	var to_factor := 2.0 / (area * _fuselage.density * linear_velocity.length_squared())
	lifts.append(_to_viewport(Vector2(x, force.y * to_factor)))
	drags.append(_to_viewport(Vector2(x, force.z * to_factor)))
	torques.append(_to_viewport(Vector2(x, torque.x * to_factor)))


func _get_aircraft_wing_area() -> float:
	var area := 0.0
	for wing in _aircraft._wings:
		for i in wing.get_section_count():
			area += wing.get_section_chord(i) * wing.get_section_length(i)
	return area

func _draw_plot_segment(x: float, x2: float) -> void:
	var linear_velocity := Vector3.FORWARD
	var to_factor := 2.0 / (_wing.span * _wing.get_mac() * _wing.density)
	_wing.rotation_degrees.x = x
	_wing.calculate(linear_velocity, Vector3.ZERO, Vector3.ZERO)
	var force := _wing.get_force() * to_factor
	var torque := _wing.get_torque() * to_factor
	var lift1 := _to_viewport(Vector2(x, force.y))
	var drag1 := _to_viewport(Vector2(x, force.z))
	var torque1 := _to_viewport(Vector2(x, torque.x))
	_wing.rotation_degrees.x = x2
	_wing.calculate(linear_velocity, Vector3.ZERO, Vector3.ZERO)
	force = _wing.get_force() * to_factor
	torque = _wing.get_torque() * to_factor
	var lift2 := _to_viewport(Vector2(x2, force.y))
	var drag2 := _to_viewport(Vector2(x2, force.z))
	var torque2 := _to_viewport(Vector2(x2, torque.x))
	draw_line(lift1, lift2, Color.RED)
	draw_line(drag1, drag2, Color.GREEN)
	draw_line(torque1, torque2, Color.YELLOW)



func _draw_axis() -> void:
	draw_line(_to_viewport(Vector2(-plot_size.x, 0)), _to_viewport(Vector2(plot_size.x, 0)), Color.BLUE)
	draw_line(_to_viewport(Vector2(0, -plot_size.y)), _to_viewport(Vector2(0, plot_size.x)), Color.BLUE)
	var d := 5
	for x in int(plot_size.x):
		var point := _to_viewport(Vector2(x, 0))
		draw_line(point + Vector2(0, -d), point + Vector2(0, d), Color.VIOLET)
		point = _to_viewport(Vector2(-x, 0))
		draw_line(point + Vector2(0, -d), point + Vector2(0, d), Color.VIOLET)

	for i in 20:
		var y := i * plot_size.y / 20
		var point := _to_viewport(Vector2(0, y))
		draw_line(point + Vector2(-d, 0), point + Vector2(d, 0), Color.VIOLET)
		point = _to_viewport(Vector2(0, -y))
		draw_line(point + Vector2(-d, 0), point + Vector2(d, 0), Color.VIOLET)


func _to_viewport(plot_point: Vector2) -> Vector2:
	var rect := get_viewport_rect()
	var center := rect.get_center()
	var size := Vector2(rect.size.x / plot_size.x / 2, rect.size.y / plot_size.y / 2)
	var point := center + plot_point * size
	point.y = center.y - plot_point.y * size.y
	return point
