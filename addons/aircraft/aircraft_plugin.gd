@tool
extends EditorPlugin

var VehicleWing3DGizmoPlugin := preload("uid://bn51yyq6ui0ym")
var VehicleFuselage3DGizmoPlugin := preload("uid://cgawjcesjcrh2")
var VehicleRotor3DGizmoPlugin := preload("uid://dihx2xgh8x6kx")
var AirfoilPreviewGenerator := preload("uid://cnkvh1p5mvkpa")

var _vehicle_wing_gizmo: EditorNode3DGizmoPlugin
var _vehicle_fuselage_gizmo: EditorNode3DGizmoPlugin
var _vehicle_rotor_gizmo: EditorNode3DGizmoPlugin
var _airfoil_preview_generator: EditorInspectorPlugin


func _enter_tree() -> void:
	_vehicle_wing_gizmo = VehicleWing3DGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_vehicle_wing_gizmo)
	_vehicle_fuselage_gizmo = VehicleFuselage3DGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_vehicle_fuselage_gizmo)
	_vehicle_rotor_gizmo = VehicleRotor3DGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_vehicle_rotor_gizmo)
	_airfoil_preview_generator = AirfoilPreviewGenerator.new()
	add_inspector_plugin(_airfoil_preview_generator)


func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(_vehicle_wing_gizmo)
	remove_node_3d_gizmo_plugin(_vehicle_fuselage_gizmo)
	remove_node_3d_gizmo_plugin(_vehicle_rotor_gizmo)
	remove_inspector_plugin(_airfoil_preview_generator)
