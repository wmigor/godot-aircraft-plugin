@tool
extends EditorPlugin

var VehicleWing3DGizmoPlugin := preload("uid://bn51yyq6ui0ym")
var VehicleFuselage3DGizmoPlugin := preload("uid://cgawjcesjcrh2")
var VlmWing3DGizmoPlugin := preload("uid://dq1q8iqyl8rlu")

var _vehicle_wing_gizmo: EditorNode3DGizmoPlugin
var _vehicle_fuselage_gizmo: EditorNode3DGizmoPlugin
var _vlm_wing_gizmo: EditorNode3DGizmoPlugin


func _enter_tree() -> void:
	_vehicle_wing_gizmo = VehicleWing3DGizmoPlugin.new()
	_vlm_wing_gizmo = VlmWing3DGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_vehicle_wing_gizmo)
	_vehicle_fuselage_gizmo = VehicleFuselage3DGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_vehicle_fuselage_gizmo)
	add_node_3d_gizmo_plugin(_vlm_wing_gizmo)


func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(_vehicle_wing_gizmo)
	remove_node_3d_gizmo_plugin(_vehicle_fuselage_gizmo)
	remove_node_3d_gizmo_plugin(_vlm_wing_gizmo)
