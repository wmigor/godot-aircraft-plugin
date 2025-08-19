extends EditorNode3DGizmoPlugin


func _init() -> void:
	create_material("fuselage_material", Color.ORANGE)
	create_material("error_material", Color.RED)


func _get_gizmo_name() -> String:
	return "VehicleFuselage3D"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is VehicleFuselage3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var fuselage := gizmo.get_node_3d() as VehicleFuselage3D
	if fuselage == null:
		return

	var lines := PackedVector3Array()
	var right := fuselage.transform.basis.x.normalized()
	_add_fuselage_lines(fuselage, lines, right)
	if fuselage.cylinder:
		var up := fuselage.transform.basis.y.normalized()
		_add_fuselage_lines(fuselage, lines, up)
	gizmo.add_lines(lines, get_material("fuselage_material", gizmo), false, Color.WHITE)


func _add_fuselage_lines(fuselage: VehicleFuselage3D, lines: PackedVector3Array, right: Vector3) -> void:
	var forward := -fuselage.transform.basis.z.normalized()
	var forward_point := forward * fuselage.length * 0.5
	var backward_point := -forward_point
	var center_point := forward * fuselage.length * (0.5 - fuselage.center_position)

	var start_index = len(lines)
	lines.append(forward_point + right * fuselage.forward_width * 0.5)
	lines.append(forward_point - right * fuselage.forward_width * 0.5)

	if fuselage.center_position > 0.0 and fuselage.center_position < 1.0:
		lines.append(lines[len(lines) - 1])
		lines.append(center_point - right * fuselage.center_width * 0.5)
	
	lines.append(lines[len(lines) - 1])
	lines.append(backward_point - right * fuselage.backward_width * 0.5)

	lines.append(lines[len(lines) - 1])
	lines.append(backward_point + right * fuselage.backward_width * 0.5)

	if fuselage.center_position > 0.0 and fuselage.center_position < 1.0:
		lines.append(lines[len(lines) - 1])
		lines.append(center_point + right * fuselage.center_width * 0.5)
	
	lines.append(lines[len(lines) - 1])
	lines.append(lines[start_index])
