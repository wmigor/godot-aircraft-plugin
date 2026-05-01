extends EditorNode3DGizmoPlugin


func _init() -> void:
	create_material("wing_material", Color.GREEN)
	create_material("error_material", Color.RED)
	create_material("mac_material", Color.YELLOW)


func _get_gizmo_name() -> String:
	return "VehicleWing3D"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is VehicleWing3D


func _draw_shapes(gizmo: EditorNode3DGizmo, wing: VehicleWing3D) -> void:
	var lines := PackedVector3Array()
	_add_shape_lines(wing, lines)
	gizmo.add_lines(lines, get_material("mac_material", gizmo), false, Color.WHITE)


func _add_shape_lines(wing: VehicleWing3D, lines: PackedVector3Array) -> void:
	var mac := wing.get_mac()
	var mac_z := wing.get_mac_forward_position()
	var start := Vector3.RIGHT * wing.offset
	start.z += mac * 0.25 - mac_z
	var wing_chord := wing.chord
	var base := start
	var base_chord := wing_chord
	var base_twist := 0.0
	for shape in wing.shapes:
		var tip := shape.get_tip(base)
		var tip_chord := shape.chord
		var p1 := _get_wing_point(base, tip, 0.0, -base_chord * 0.5, base_twist)
		var p2 := _get_wing_point(base, tip, 1.0, -tip_chord * 0.5, shape.twist)
		var p3 := _get_wing_point(base, tip, 1.0, tip_chord * 0.5, shape.twist)
		var p4 := _get_wing_point(base, tip, 0.0, base_chord * 0.5, base_twist)
		lines.append(p1)
		lines.append(p2)
		lines.append(p2)
		lines.append(p3)
		lines.append(p3)
		lines.append(p4)
		lines.append(p4)
		lines.append(p1)
		base = tip
		base_chord = tip_chord
		base_twist = shape.twist


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var wing := gizmo.get_node_3d() as VehicleWing3D
	if wing == null:
		return

	_draw_shapes(gizmo, wing)
	#return

	var lines := PackedVector3Array()
	var valid := _add_wing_lines(wing, false, lines);
	if wing.mirror:
		_add_wing_lines(wing, true, lines);

	var material := "wing_material" if valid else "error_material"
	gizmo.add_lines(lines, get_material(material, gizmo), false, Color.WHITE)

	lines.clear()
	_add_mac(wing, lines)
	gizmo.add_lines(lines, get_material("mac_material", gizmo), false, Color.WHITE)


func _add_wing_lines(wing: VehicleWing3D, mirror: bool, lines: PackedVector3Array) -> bool:
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

	var sections := wing._build_control_surface_sections()
	var last_end := 0.0

	for i in len(sections):
		var section := sections[i]
		var start_chord := lerpf(chord, chord * taper, section.start)
		var end_chord := lerp(chord, chord * taper, section.end)

		if section.type == VehicleWing3D.ControlSurfaceType.None:
			var d1 := _get_wing_point(base, tip, section.start, start_chord * 0.5, twist * section.start)
			var d2 := _get_wing_point(base, tip, section.end, end_chord * 0.5, twist * section.end)
			lines.append(d1)
			lines.append(d2)
			if i == 0:
				lines.append(w1)
				lines.append(d1)
			if i == sections.size() - 1:
				lines.append(w2)
				lines.append(d2)
		else:
			var d1 := _get_wing_point(base, tip, section.start, start_chord * 0.5, twist * section.start)
			var d2 := _get_wing_point(base, tip, section.start, start_chord * 0.5 - start_chord * section.fraction, twist * section.start)
			var d3 := _get_wing_point(base, tip, section.end, end_chord * 0.5, twist * section.end)
			var d4 := _get_wing_point(base, tip, section.end, end_chord * 0.5 - end_chord * section.fraction, twist * section.end)
			if section.start > 0.0:
				lines.append(d1)
				lines.append(d2)
			if section.end < 1.0:
				lines.append(d3)
				lines.append(d4)
			lines.append(d2)
			lines.append(d4)
			var angle := wing.get_control_surface_angle(section.type, mirror)
			if mirror:
				angle *= -1.0
			var axis := (d4 - d2).normalized()
			var r1 := d2 + (d1 - d2).rotated(axis, angle)
			var r2 := d4 + (d3 - d4).rotated(axis, angle)
			lines.append(d2)
			lines.append(r1)
			lines.append(r1)
			lines.append(r2)
			lines.append(r2)
			lines.append(d4)
			if i == 0:
				lines.append(w1)
				lines.append(d2)
			if i == len(sections) - 1:
				lines.append(w2)
				lines.append(d4)
		valid = valid and section.start <= section.end and section.start >= 0.0 and section.start <= 1.0 and section.end <= 1.0 and section.end >= 0.0 and section.fraction >= 0.0 and section.fraction < 1.0 and section.start >= last_end
		last_end = section.end
	return valid


func _add_mac(wing: VehicleWing3D, lines: PackedVector3Array) -> void:
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
