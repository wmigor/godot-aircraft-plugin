extends Node3D

@onready var _fuselage := get_parent() as VehicleFuselage3D

static var _material: Material = null


func _ready() -> void:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color.ORANGE
	build()


func build() -> void:
	_clear()
	if _fuselage == null:
		return
	for i in _fuselage.get_section_count():
		var view := CSGBox3D.new()
		var width := _fuselage.get_section_width(i)
		var length := _fuselage.get_section_length(i)
		var section_transform := _fuselage.get_section_transform(i)
		view.material = _material
		view.basis = section_transform.basis
		view.position = section_transform.origin
		view.size.x = width
		view.size.y = width * 0.05
		view.size.z = length * 0.95
		add_child(view)


func _clear() -> void:
	for i in get_child_count():
		get_child(i).queue_free()
