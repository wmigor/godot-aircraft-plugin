extends Node3D

@onready var _propeller := get_parent() as VehiclePropeller3D

static var _material: Material = null
var _blade: CSGBox3D
var _feater_rate: float


func _ready() -> void:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color.RED
	_build()


func _process(delta: float) -> void:
	if _propeller == null:
		return
	_process_feather(delta)
	var rpm := _propeller.rpm
	var min_rpm := _propeller.min_rpm
	var axis := Vector3.FORWARD if _propeller.reverse else Vector3.BACK
	if rpm < min_rpm:
		rotate(axis, _propeller.angular_velocity * delta)
	else:
		var delta_angle := TAU / 8
		var speed := delta_angle * (rpm - min_rpm) / (_propeller.max_rpm - min_rpm) / 0.25
		rotate(axis, delta_angle + speed * delta)


func _process_feather(delta: float) -> void:
	_feater_rate = move_toward(_feater_rate, 1.0 if _propeller.feather else 0.0, delta * 2.0)
	_blade.rotation_degrees.x = lerpf(0.0, 90.0, _feater_rate)
	

func _build() -> void:
	_clear()
	if _propeller == null:
		return
	_blade = CSGBox3D.new()
	_blade.material = _material
	_blade.size.x = _propeller.radius * 2.0
	_blade.size.z = _propeller.radius / 100.0
	_blade.size.y = _propeller.radius / 8.0
	add_child(_blade)


func _clear() -> void:
	for child in get_children():
		child.queue_free()
