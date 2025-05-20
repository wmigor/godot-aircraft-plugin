@tool
extends EditorPlugin


var _vehicle_wing_gizmo: VehicleWing3DGizmoPlugin


func _enter_tree() -> void:
	_vehicle_wing_gizmo = VehicleWing3DGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_vehicle_wing_gizmo)


func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(_vehicle_wing_gizmo)
