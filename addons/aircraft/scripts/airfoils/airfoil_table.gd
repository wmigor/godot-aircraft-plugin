@tool
extends Airfoil
class_name AirfoilTable

@export_file_path("*.afl") var file_path: String:
	get: return file_path
	set(value):
		file_path = value
		_loaded = false
		emit_changed()

@export var flap_lift := 0.4
@export var flap_drag := 0.1
@export var flap_pitch := -0.1
@export var flap_angle_offet := 10.0


class Table:
	var _angles: Array[float]
	var _values: Array[float]
	var _baked_angles: Array[float]
	var _baked_values: Array[float]
	var _baked_angle_interval: float

	func add(angle: float, value: float) -> void:
		_angles.append(angle)
		_values.append(value)

	func get_raw_value(angle: float) -> float:
		for i in len(_angles):
			var angle1 := _angles[i]
			var value1 := _values[i]
			if angle == angle1:
				return value1
			if i >= len(_angles) - 1:
				return 0.0
			var angle2 := _angles[i + 1]
			if angle <= angle1 or angle > angle2:
				continue
			var value2 := _values[i + 1]
			var weight := (angle - angle1) / (angle2 - angle1)
			var value := lerpf(value1, value2, weight)
			return value
		return 0.0

	func get_baked_value(angle: float) -> float:
		if _baked_angle_interval <= 0.0 or len(_angles) < 1:
			return 0.0
		var index := int((angle - _angles[0]) / _baked_angle_interval)
		if index < 0 or index >= len(_baked_angles):
			return 0.0
		var angle1 := _baked_angles[index]
		var value1 := _baked_values[index]
		if angle == angle1:
			return value1
		if index >= len(_baked_angles) - 1:
			return _baked_values[len(_baked_values)]
		var angle2 := _baked_angles[index + 1]
		var value2 := _baked_values[index + 1]
		var weight := (angle - angle1) / (angle2 - angle1)
		var value := lerpf(value1, value2, weight)
		return value

	func clear() -> void:
		_angles.clear()
		_values.clear()
		_baked_angles.clear()
		_baked_values.clear()
		_baked_angle_interval = 0.0

	func bake() -> void:
		_baked_angle_interval = _find_min_interval()
		_baked_angles.clear()
		_baked_values.clear()
		if len(_angles) <= 0 or _baked_angle_interval <= 0.0:
			return
		var angle := _angles[0]
		while angle < _angles[len(_angles) - 1]:
			_baked_angles.append(angle)
			var value := get_raw_value(angle)
			_baked_values.append(value)
			angle += _baked_angle_interval

	func _find_min_interval() -> float:
		if len(_angles) < 2:
			return 0.0
		var min_interval := absf(_angles[1] - _angles[0])
		for i in len(_angles) - 1:
			var interval := absf(_angles[i + 1] - _angles[i])
			if interval < min_interval:
				min_interval = interval
		return min_interval
		

var _loaded := false
var _lift_table := Table.new()
var _drag_table := Table.new()
var _pitch_table := Table.new()


func _load_from_file() -> void:
	_lift_table.clear()
	_drag_table.clear()
	_pitch_table.clear()
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	while not file.eof_reached():
		var line := file.get_line()
		var numbers := Array(line.split(" ", false)).map(func(x): return x.to_float())
		if len(numbers) != 4:
			continue
		var angle := numbers[0] as float
		var lift := numbers[1] as float
		var drag := numbers[2] as float
		var pitch := numbers[3] as float
		_lift_table.add(angle, lift)
		_drag_table.add(angle, drag)
		_pitch_table.add(angle, pitch)
	_lift_table.bake()
	_drag_table.bake()
	_pitch_table.bake()


func update_factors(data: Data) -> void:
	if not _loaded:
		_loaded = true
		_load_from_file()
	var angle := rad_to_deg(data.angle_of_attack) + flap_angle_offet * data.control_surface_normalized_angle
	angle = wrapf(angle, -180, 180)
	data.lift_factor = _lift_table.get_baked_value(angle) + flap_lift * data.control_surface_normalized_angle
	data.drag_factor = _drag_table.get_baked_value(angle) + flap_drag * absf(data.control_surface_normalized_angle)
	data.pitch_factor = _pitch_table.get_baked_value(angle) + flap_pitch * data.control_surface_normalized_angle
