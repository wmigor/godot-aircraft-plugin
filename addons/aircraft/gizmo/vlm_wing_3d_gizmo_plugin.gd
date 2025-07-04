extends EditorNode3DGizmoPlugin


func _init() -> void:
	create_material("wing_material", Color.GREEN)
	create_material("error_material", Color.RED)
	create_material("mac_material", Color.YELLOW)


func _get_gizmo_name() -> String:
	return "VlmWing3D"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is VlmWing3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var wing := gizmo.get_node_3d() as VlmWing3D
	if wing == null:
		return

	var lines := PackedVector3Array()
	_add_panels(wing, false, lines)
	#var valid := _add_wing_lines(wing, false, lines);
	#if wing.mirror:
		#_add_wing_lines(wing, true, lines);
#
	#var material := "wing_material" if valid else "error_material"
	gizmo.add_lines(lines, get_material("wing_material", gizmo), false, Color.WHITE)

	lines.clear()
	_add_mac(wing, lines)
	for panel in wing._panels:
		_add_point(panel.control_point, lines)
		_add_point(panel.vortex_left, lines)
		_add_point(panel.vortex_right, lines)

	gizmo.add_lines(lines, get_material("mac_material", gizmo), false, Color.WHITE)


func _add_panels(wing: VlmWing3D, mirror: bool, lines: PackedVector3Array) -> void:
	wing._try_rebuild_shape()
	for panel in wing._panels:
		lines.append(panel.front_left)
		lines.append(panel.front_right)
		lines.append(panel.front_right)
		lines.append(panel.back_right)
		lines.append(panel.back_right)
		lines.append(panel.back_left)
		lines.append(panel.back_left)
		lines.append(panel.front_left)


func _add_point(point: Vector3, lines: PackedVector3Array, size := 0.01) -> void:
	lines.append(point - Vector3.RIGHT * size)
	lines.append(point + Vector3.RIGHT * size)
	lines.append(point - Vector3.FORWARD * size)
	lines.append(point + Vector3.FORWARD * size)


func _add_wing_lines(wing: VlmWing3D, mirror: bool, lines: PackedVector3Array) -> bool:
	var base := wing.get_base()
	var tip := wing.get_tip()
	var chord := wing.chord
	var taper := wing.taper
	var twist := wing.twist
	var mac := wing.get_mac()
	var mac_z := wing.get_mac_forward_position()

	var valid := wing.span > 0.0 and chord > 0.0 and taper >= 0.0 and wing.offset >= 0.0 and wing.get_console_length() > 0.0

	base.z += mac * 0.25 - mac_z
	tip += (mac * 0.25 - mac_z) * Vector3.BACK.rotated(Vector3.RIGHT, twist)

	if mirror:
		base.x *= -1.0
		tip.x *= -1.0

	var w1 := _get_wing_point(base, tip, 0.0, -chord * 0.5, 0.0)
	var w2 := _get_wing_point(base, tip, 1.0, -chord * 0.5 * taper, twist)

	lines.append(w1)
	lines.append(w2)

	var last_end := 0.0
	var sections := [[0.0, 1.0]]
	for i in len(sections):
		var section = sections[i]
		var start = section[0]
		var end = section[1] 
		var start_chord := lerpf(chord, chord * taper, start)
		var end_chord := lerp(chord, chord * taper, end)
		var d1 := _get_wing_point(base, tip, start, start_chord * 0.5, twist * start)
		var d2 := _get_wing_point(base, tip, end, end_chord * 0.5, twist * end)
		lines.append(d1)
		lines.append(d2)
		if i == 0:
			lines.append(w1)
			lines.append(d1)
		if i == sections.size() - 1:
			lines.append(w2)
			lines.append(d2)
		valid = valid and start <= end and start >= 0.0 and start <= 1.0 and end <= 1.0 and end >= 0.0 and start >= last_end
		last_end = end
	return valid


func _add_mac(wing: VlmWing3D, lines: PackedVector3Array) -> void:
	var mac := wing.get_mac()
	var half_mac := mac * 0.5
	var mac_z := 0.25 * mac
	lines.append(Vector3(0.1, 0.0, mac_z + half_mac))
	lines.append(Vector3(-0.1, 0.0, mac_z + half_mac))
	lines.append(Vector3(0.1, 0.0, mac_z - half_mac))
	lines.append(Vector3(-0.1, 0.0, mac_z - half_mac))


func _get_wing_point(base: Vector3, tip: Vector3, pos: float, chord: float, twist: float) -> Vector3:
	var point := base + (tip - base) * pos
	var twist_dir := Vector3.BACK.rotated(Vector3.RIGHT, twist)
	point += twist_dir * chord
	return point
