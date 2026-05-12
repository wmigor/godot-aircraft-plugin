@tool
extends Node3D

@export var min_rpm := 400.0
@export var max_rpm := 2700.0
@onready var _propeller := get_parent() as VehiclePropeller3D

static var _material_normal: Material = null
static var _material_warning: Material = null
static var _material_stall: Material = null

var _section_views: Dictionary[VehiclePropeller3D.Section, Array]
var _blades: Array[Node3D]


func _ready() -> void:
	if _material_normal == null:
		_material_normal = StandardMaterial3D.new()
		_material_normal.albedo_color = Color.GREEN
	if _material_warning == null:
		_material_warning = StandardMaterial3D.new()
		_material_warning.albedo_color = Color.ORANGE
	if _material_stall == null:
		_material_stall = StandardMaterial3D.new()
		_material_stall.albedo_color = Color.RED
	_build()


func _physics_process(delta: float) -> void:
	if _propeller == null:
		return
	_update_rotation(delta)
	for section in _propeller._sections:
		_update_material(section)


func _update_rotation(delta: float) -> void:
	var rpm = _propeller.rpm
	var axis := Vector3.FORWARD if _propeller.reverse else Vector3.BACK
	if rpm < min_rpm:
		rotate(axis, _propeller.angular_velocity * delta)
	else:
		var delta_angle := TAU / 8
		var speed = delta_angle * (rpm - min_rpm) / (max_rpm - min_rpm) / 0.25
		rotate(axis, delta_angle + speed * delta)


func _update_material(section: VehiclePropeller3D.Section) -> void:
	var views := _section_views.get(section)
	if not views:
		return
	for view in views:
		if section.stall:
			view.material = _material_stall
		elif section.stall_warning:
			view.material = _material_warning
		else:
			view.material = _material_normal


func _build() -> void:
	_clear()
	if _propeller == null:
		return
	for balade_index in _propeller.blade_count:
		var angle := balade_index * TAU / _propeller.blade_count
		var blade := Node3D.new()
		blade.rotation.z = angle
		_blades.append(blade)
		add_child(blade)
		for section in _propeller._sections:
			var view := CSGBox3D.new()
			view.material = _material_normal
			var length := section.area / section.chord
			view.size.x = length
			view.size.z = section.chord / 8
			view.size.y = section.chord
			view.rotation.x = -section.pitch
			view.position.x = _propeller.hub_radius + section.radius
			blade.add_child(view)
			if section not in _section_views:
				_section_views[section] = []
			_section_views[section].append(view)


func _clear() -> void:
	for views in _section_views.values():
		for view in views:
			view.queue_free()
	_section_views.clear()
	for blade in _blades:
		blade.queue_free()
	_blades.clear()
