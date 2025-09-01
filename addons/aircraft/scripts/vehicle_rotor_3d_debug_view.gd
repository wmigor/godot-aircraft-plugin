extends Node3D

@onready var _rotor := get_parent() as VehicleRotor3D

static var _material: Material = null


var _blades: Array[Node3D]


func _ready() -> void:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color.RED
	_build()


func _process(delta: float) -> void:
	if _rotor == null:
		return
	var rpm := _rotor.rpm * _rotor.tail_gear_ratio
	if rpm < _rotor.max_rpm:
		rotate_x(_rotor.angular_velocity * _rotor.tail_gear_ratio * delta)
	else:
		var delta_angle := TAU / (6 + _rotor.tail_blade_count)
		var speed := delta_angle * rpm / _rotor.max_rpm / _rotor.tail_gear_ratio / 0.25
		rotate_x(delta_angle + speed * delta)
	for blade in _blades:
		blade.rotation.z = _rotor.rudder * _rotor.tail_max_angle


func _build() -> void:
	_clear()
	if _rotor == null:
		return
	position.z = _rotor.tail_arm
	position.y = -_rotor.tail_radius
	for i in _rotor.blade_count:
		var blade := CSGBox3D.new()
		blade.material = _material
		blade.size.x = _rotor.tail_blade_chord * 0.1
		blade.size.y = _rotor.tail_blade_chord
		blade.size.z = _rotor.tail_radius
		blade.rotation.x = i * TAU / _rotor.blade_count
		var offset := (_rotor.tail_blade_chord + _rotor.tail_radius) * 0.5
		blade.position = blade.basis * (offset * Vector3.FORWARD)
		add_child(blade)
		_blades.append(blade)


func _clear() -> void:
	for blade in _blades:
		blade.queue_free()
	_blades.clear()
