extends Node3D

@onready var _wing := get_parent() as VehicleWing3D

class Section:
	var view: CSGBox3D
	var control_surface_node: Node3D
	var control_surface_view: CSGBox3D
	var index: int

static var wing_material: Material = null
static var control_surface_material: Material = null
static var warning_material: Material = null
static var stall_material: Material = null

var _sections: Array[Section]


func _ready() -> void:
	if wing_material == null:
		wing_material = _create_material(Color(0.0, 0.65, 0.2))
	if control_surface_material == null:
		control_surface_material = _create_material(Color(0.0, 0.2, 1.0))
	if warning_material == null:
		warning_material = _create_material(Color(0.8, 0.4, 0.0))
	if stall_material == null:
		stall_material = _create_material(Color(1.0, 0.0, 0.0))
	build()


func _process(_delta: float) -> void:
	_update_sections()


func build() -> void:
	_clear()
	if _wing == null:
		return
	for i in _wing.get_section_count():
		var section := Section.new()
		_sections.append(section)
		section.index = i
		section.view = CSGBox3D.new()
		var chord := _wing.get_section_chord(i)
		var control_surface_chord := chord * _wing.get_section_control_surface_fraction(i)
		var section_transform := _wing.get_section_transform(i)
		chord -= control_surface_chord
		section.view.material = wing_material
		section.view.basis = section_transform.basis
		section.view.position = section_transform.origin + Vector3.FORWARD * control_surface_chord * 0.5 + Vector3.BACK * (_wing.get_mac() * 0.25)
		section.view.size.x = _wing.get_section_length(i) * 0.95
		section.view.size.y = chord * 0.05
		section.view.size.z = chord
		add_child(section.view)
		if control_surface_chord > 0.0:
			section.control_surface_node = Node3D.new()
			section.control_surface_node.position.z = chord * 0.5
			section.view.add_child(section.control_surface_node)
			section.control_surface_view = CSGBox3D.new()
			section.control_surface_view.material = control_surface_material
			section.control_surface_view.size = Vector3(section.view.size.x, section.view.size.y * 0.75, control_surface_chord)
			section.control_surface_view.position.z = control_surface_chord * 0.5
			section.control_surface_node.add_child(section.control_surface_view)


func _clear() -> void:
	_sections.clear()
	for i in get_child_count():
		get_child(i).queue_free()


func _update_sections() -> void:
	if _wing == null:
		return
	for i in mini(_wing.get_section_count(), len(_sections)):
		var section := _sections[i]
		var material := _get_wing_material(i)
		if section.view.material != material:
			section.view.material = material
		if section.control_surface_node == null or section.control_surface_view == null:
			continue
		material = _get_control_surface_material(i)
		if section.control_surface_view.material != material:
			section.control_surface_view.material = material
		section.control_surface_node.rotation.x = _wing.get_section_control_surface_angle(i)


func _get_wing_material(index: int) -> Material:
	if _wing.is_section_stall(index):
		return stall_material
	if _wing.is_section_stall_warning(index):
		return warning_material
	return wing_material


func _get_control_surface_material(index: int) -> Material:
	if _wing.is_section_stall(index):
		return stall_material
	return control_surface_material


func _create_material(color: Color) -> Material:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
