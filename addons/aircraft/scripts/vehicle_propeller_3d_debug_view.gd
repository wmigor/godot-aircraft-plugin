extends Node3D

@onready var _propeller := get_parent() as VehiclePropeller3D

static var _material: Material = null


func _ready() -> void:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color.RED
	_build()


func _process(delta: float) -> void:
	if _propeller == null:
		return
	var rpm := _propeller.rpm
	var min_rpm := _propeller.min_rpm
	if rpm < min_rpm:
		rotate(Vector3.BACK, _propeller.angular_velocity * delta)
	else:
		var delta_angle := TAU / 8
		var speed := delta_angle * (rpm - min_rpm) / (_propeller.max_rpm - min_rpm) / 0.25
		rotate(Vector3.BACK, delta_angle + speed * delta)


func _build() -> void:
	_clear()
	if _propeller == null:
		return
	var blade := CSGBox3D.new()
	blade.material = _material
	blade.size.x = _propeller.diameter
	blade.size.z = 0.05
	blade.size.y = 0.1
	add_child(blade)


func _clear() -> void:
	for child in get_children():
		child.queue_free()
