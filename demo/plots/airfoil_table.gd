extends Airfoil
class_name AirfoilTable

@export_file_path() var data_file: String
@export var step := 1.0

var _loaded := false
var _lifts: MultiTable
var _drags: MultiTable
var _pitches: MultiTable


class Table:
	var _values: Array[Vector2]
	var _baked_values: Array[Vector2]
	var _step_size: float


	func _init(step_size: float) -> void:
		_step_size = step_size


	func sample_baked(key: float) -> float:
		var index1 := int((key - _baked_values[0].x) / _step_size)
		var index2 := index1 + 1
		if index2 >= len(_baked_values):
			index1 -= 1
			index2 -= 1
		var value1 := _baked_values[index1]
		var value2 := _baked_values[index2]
		var weight := (key - value1.x) / (value2.x - value1.x)
		return lerpf(value1.y, value2.y, weight)


	func add_value(key: float, value: float) -> void:
		_values.append(Vector2(key, value))


	func bake() -> void:
		_values.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
		_baked_values.clear()
		var count := int((_values[len(_values) - 1].x - _values[0].x) / _step_size) + 1
		for i in count:
			var key := _values[0].x + i * _step_size
			var value := _sample(key)
			_baked_values.append(Vector2(key, value))


	func _sample(key: float) -> float:
		for i in len(_values) - 1:
			var value1 := _values[i]
			var value2 := _values[i + 1]
			if key >= value1.x and key <= value2.x:
				return lerpf(value1.y, value2.y, (key - value1.x) / (value2.x - value1.x))
		return 0.0


class MultiTable:
	var _keys: Array[float]
	var _tables: Array[Table]


	func add_table(key: float, table: Table) -> void:
		_keys.append(key)
		_tables.append(table)


	func sample(angle: float, deflection: float) -> float:
		for i in len(_keys) - 1:
			var deflection1 := _keys[i]
			var deflection2 := _keys[i + 1]
			if deflection >= deflection1 and deflection <= deflection2:
				var value1 := _tables[i].sample_baked(angle)
				var value2 := _tables[i + 1].sample_baked(angle)
				var weight := (deflection - deflection1) / (deflection2 - deflection1)
				return lerpf(value1, value2, weight)
		return 0.0


func update_factors(data: Data) -> void:
	_try_load()
	data.lift_factor = _lifts.sample(data.angle_of_attack, data.control_surface_angle)
	data.drag_factor = _drags.sample(data.angle_of_attack, data.control_surface_angle)
	data.pitch_factor = _pitches.sample(data.angle_of_attack, data.control_surface_angle)
	if absf(data.aspect_ratio) > 0.0:
		data.lift_factor += get_inducd_lift(data.lift_factor, data.aspect_ratio)
		data.drag_factor += get_induced_drag(data.lift_factor, data.aspect_ratio)


static func get_inducd_lift(lift: float, aspect_ratio: float) -> float:
	if absf(aspect_ratio) <= 0.0:
		return 0.0
	var s := signf(lift)
	lift = absf(lift)
	var corrected_lift := lift / (1.0 + lift / (PI * aspect_ratio))
	return (corrected_lift - lift) * s


static func get_induced_drag(lift: float, aspect_ratio: float) -> float:
	if absf(aspect_ratio) <= 0.0:
		return 0.0
	var k := 1.0 / (PI * aspect_ratio * 0.8)
	var induced_drag := k * lift * lift
	return induced_drag


func _try_load() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(data_file, FileAccess.READ)
	if file == null:
		return
	_lifts = MultiTable.new()
	_drags = MultiTable.new()
	_pitches = MultiTable.new()
	var lifts: Array[Table]
	var drags: Array[Table]
	var pitches: Array[Table]
	file.get_line()
	var deflections := file.get_line().split(" ")
	for d in deflections:
		lifts.append(Table.new(deg_to_rad(step)))
		drags.append(Table.new(deg_to_rad(step)))
		pitches.append(Table.new(deg_to_rad(step)))
		var deflection := deg_to_rad(d.to_float())
		_lifts.add_table(deflection, lifts[len(lifts) - 1])
		_drags.add_table(deflection, drags[len(drags) - 1])
		_pitches.add_table(deflection, pitches[len(pitches) - 1])
	while not file.eof_reached():
		var line := file.get_line()
		var words := line.split(" ")
		if len(words) < 4:
			break
		for i in len(deflections):
			var alpha := float(words[0])
			var lift := float(words[1 + i * 3])
			var drag := float(words[2 + i * 3])
			var pitch := float(words[3 + i * 3])
			lifts[i].add_value(deg_to_rad(alpha), lift)
			drags[i].add_value(deg_to_rad(alpha), drag)
			pitches[i].add_value(deg_to_rad(alpha), pitch)
	for i in len(deflections):
		lifts[i].bake()
		drags[i].bake()
		pitches[i].bake()
	file.close()
