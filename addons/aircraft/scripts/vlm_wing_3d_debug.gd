extends Node3D

@onready var _wing := get_parent() as VlmWing3D

class Section:
	var panel: VlmWing3D.WingPanel

static var material: Material

var _sections: Array[Section]
var _mesh_instance: MeshInstance3D
var _mesh: ImmediateMesh


func _ready() -> void:
	if material == null:
		material = StandardMaterial3D.new()
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	build()


func _process(_delta: float) -> void:
	_update_panels()


func build() -> void:
	_clear()
	if _wing == null:
		return
	_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.material_override = material
	add_child(_mesh_instance, true)
	_update_panels()


func _add_panel_to_mesh(panel: VlmWing3D.WingPanel) -> void:
	if _mesh == null:
		return
	var v1 := panel.back_left - panel.front_left
	var v2 := panel.front_right - panel.front_left
	var normal := v1.cross(v2).normalized()

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_normal(normal)
	_mesh.surface_add_vertex(panel.front_left)
	_mesh.surface_add_vertex(panel.front_right)
	_mesh.surface_add_vertex(panel.back_left)
	
	_mesh.surface_add_vertex(panel.back_left)
	_mesh.surface_add_vertex(panel.front_right)
	_mesh.surface_add_vertex(panel.back_right)
	_mesh.surface_end()

func _clear() -> void:
	_sections.clear()
	for i in get_child_count():
		get_child(i).queue_free()
	if _mesh != null:
		_mesh.queue_free()
		_mesh = null


func _update_panels() -> void:
	if _wing == null or _mesh == null:
		return
	_mesh.clear_surfaces()
	for panel in _wing._panels:
		var section := Section.new()
		_sections.append(section)
		section.panel = panel
		_add_panel_to_mesh(panel)
