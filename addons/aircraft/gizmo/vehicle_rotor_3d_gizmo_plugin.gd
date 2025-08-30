extends EditorNode3DGizmoPlugin


func _init() -> void:
	create_material("blade_material", Color.GREEN)


func _get_gizmo_name() -> String:
	return "VehicleRotor3D"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is VehicleRotor3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var rotor := gizmo.get_node_3d() as VehicleRotor3D
	if VehicleRotor3D == null:
		return

	var lines := PackedVector3Array()
	for i in rotor.blade_count:
		_add_blade_lines(rotor, i, lines)
	gizmo.add_lines(lines, get_material("blade_material", gizmo), false, Color.WHITE)


func _add_blade_lines(rotor: VehicleRotor3D, index: int, lines: PackedVector3Array) -> void:
	var yaw := index * TAU / maxi(1, rotor.blade_count)
	var direction := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	var base := direction * rotor.blade_chord * 0.5
	var tip := base + direction * rotor.radius
	var azimuthal_angle := rotor.get_azimuthal_angle(yaw)
	var base_angle := rotor.collective_angle + azimuthal_angle
	var tip_angle := base_angle + rotor.blade_twist
	var base_right := direction.cross(Vector3.UP).rotated(direction, base_angle)
	var tip_right := direction.cross(Vector3.UP).rotated(direction, tip_angle)
	var half_chord := rotor.blade_chord * 0.5
	lines.append(base - base_right * half_chord)
	lines.append(base + base_right * half_chord)
	
	lines.append(lines[len(lines) - 1])
	lines.append(tip + tip_right * half_chord)
	
	lines.append(lines[len(lines) - 1])
	lines.append(tip + tip_right * half_chord)

	lines.append(lines[len(lines) - 1])
	lines.append(tip - tip_right * half_chord)
	
	lines.append(lines[len(lines) - 1])
	lines.append(lines[len(lines) - 9])
