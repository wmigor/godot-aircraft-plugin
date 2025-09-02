@tool
extends VehicleThruster3D
class_name VehicleRotor3D

@export_group("Blades")
@export var radius := 10.5:
	set(value):
		radius = value
		update_gizmos()

@export_range(2, 10, 1) var blade_count := 4:
	set(value):
		blade_count = value
		update_gizmos()

@export var blade_chord := 0.5:
	set(value):
		blade_chord = value
		update_gizmos()

@export_range(-15, 0, 0.001, "radians_as_degrees") var blade_twist := deg_to_rad(-12.0):
	set(value):
		blade_twist = value
		update_gizmos()

@export_range(-10, 10.0, 0.001, "radians_as_degrees") var collective_angle_min := deg_to_rad(2.0):
	set(value):
		collective_angle_min = value
		update_gizmos()

@export_range(0, 30, 0.001, "radians_as_degrees") var collective_angle_max := deg_to_rad(16.0):
	set(value):
		collective_angle_max = value
		update_gizmos()

@export_range(-30, 0, 0.001, "radians_as_degrees") var azimuthal_angle_min := deg_to_rad(-6.0):
	set(value):
		azimuthal_angle_min = value
		update_gizmos()

@export_range(0, 30, 0.001, "radians_as_degrees") var azimuthal_angle_max := deg_to_rad(6.0):
	set(value):
		azimuthal_angle_max = value
		update_gizmos()

@export_range(0.0, 6, 0.001) var blade_twist_power := 3.0
@export_range(0, 30, 0.001, "radians_as_degrees") var stall_angle := deg_to_rad(14.0)
@export_range(0, 30, 0.001, "radians_as_degrees") var stall_width := deg_to_rad(2.0)
@export_range(0, 30, 0.001, "radians_as_degrees") var restore_stall_angle := deg_to_rad(30.0)
@export_range(-10, 0.0, 0.001, "radians_as_degrees") var blade_zero_lift_angle := deg_to_rad(-2.0)
@export var alternative_drag := true

@export_group("Engine")
@export var max_rpm := 192.0
@export var inertia := 25000.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var max_engine_power := 3800.0

@export_group("Tail")
@export var tail_gear_ratio := 6.0
@export var tail_arm := 12.5:
	set(value):
		tail_arm = value
		update_gizmos()

@export var tail_radius := 2.0:
	set(value):
		tail_radius = value
		update_gizmos()

@export var tail_blade_chord := 0.28:
	set(value):
		tail_blade_chord = value
		update_gizmos()

@export_range(2, 10, 1) var tail_blade_count := 3:
	set(value):
		tail_blade_count = value
		update_gizmos()

@export_range(0, 30.0, 0.001, "radians_as_degrees") var tail_max_angle := deg_to_rad(10.0):
	set(value):
		tail_max_angle = value
		update_gizmos()



@export_group("Input")
@export_range(0.0, 1.0, 0.01) var pitch := 0.0:
	set(value):
		pitch = value
		update_gizmos()

@export_range(0.0, TAU, 0.01) var stick_angle: float:
	set(value):
		stick_angle = value
		update_gizmos()

@export_range(0.0, 1.0, 0.01) var stick_len: float:
	set(value):
		stick_len = value
		update_gizmos()

@export_range(-1.0, 1.0, 0.01) var tail_pitch: float:
	set(value):
		tail_pitch = value
		update_gizmos()

var collective_angle: float:
	get(): return lerpf(collective_angle_min, collective_angle_max, clampf(pitch, 0.0, 1.0))

var _blades: Array[VehicleWing3D]
var _rotor_pivot: Node3D
var _force: Vector3
var _torque: Vector3
var _debug_view: Node3D


func _enter_tree() -> void:
	_body = get_parent() as RigidBody3D


func _exit_tree() -> void:
	_body = null


func _ready() -> void:
	_rotor_pivot = Node3D.new()
	add_child(_rotor_pivot)
	for i in blade_count:
		var blade := _create_blade(i)
		_blades.append(blade)
		_rotor_pivot.add_child(blade)


func _physics_process(delta: float) -> void:
	if _body == null or Engine.is_editor_hint():
		return
	var state := PhysicsServer3D.body_get_direct_state(_body.get_rid())
	calculate(delta, _body.transform * state.center_of_mass_local, state.linear_velocity, state.angular_velocity, 1.2255)


func calculate(delta: float, mass_center: Vector3, aircraft_velocity: Vector3, aircraft_angular_velocity: Vector3, density: float) -> void:
	var rotor_force := Vector3.ZERO
	var rotor_torque := Vector3.ZERO
	var up := global_transform.basis.y.normalized()
	var rotor_av := angular_velocity * up
	for blade in _blades:
		blade.calculate(aircraft_velocity.dot(up) * up, aircraft_angular_velocity + rotor_av, mass_center)
		blade.rotation.z = 0.0
		var azimut_angle := get_azimuthal_angle(blade.rotation.y + _rotor_pivot.rotation.y)
		blade.rotation.x = collective_angle + azimut_angle
		rotor_force += blade.get_force()
		rotor_torque += blade.get_torque()
		var blade_lift := blade.get_force().dot(up)
		blade.rotation_degrees.z = _get_blade_bend_angle(blade_lift)
	var tail_torque := _calc_fake_tail_torque(aircraft_velocity, aircraft_angular_velocity, up)
	_process_engine(delta, rotor_torque.dot(up))
	rotor_torque = tail_torque + rotor_torque - rotor_torque.dot(up) * up
	_force += (rotor_force - _force) * 0.5
	_torque += (rotor_torque - _torque) * 0.5
	_body.apply_central_force(_force)
	_body.apply_torque(_torque)


func get_azimuthal_angle(blade_angle: float) -> float:
	var dynamic_pitch := _get_dynamic_pitch(blade_angle)
	return lerpf(azimuthal_angle_min, azimuthal_angle_max, dynamic_pitch)


func _get_blade_bend_angle(blade_lift: float) -> float:
	if _body == null:
		return 0.0
	return clampf(5.0 * blade_lift / (_body.mass * 9.8 / blade_count), -20, 20)


func _process_engine(delta: float, rotor_torque: float) -> void:
	var engine_torque := _get_engine_torque()
	angular_velocity += (rotor_torque + engine_torque) / inertia * delta
	_rotor_pivot.rotate_y(angular_velocity * delta)


func _get_engine_torque() -> float:
	if not running:
		return 0.0
	var max_torque := max_engine_power * HP_TO_W / max_rpm * TO_RPM
	var min_rpm := max_rpm * 0.1
	if rpm <= min_rpm:
		var starter_torque := 0.1 * max_torque
		return starter_torque
	if rpm > max_rpm:
		return lerpf(max_torque, 0.0, (rpm - max_rpm))
	var x := 1.0 - rpm / max_rpm
	x = 1.0 - x * x * x * x
	return lerpf(0.0, max_torque, x)


func _calc_fake_tail_torque(aircraft_velocity: Vector3, aircraft_angular_velocity: Vector3, up: Vector3) -> Vector3:
	var back := global_basis.z.normalized()
	var right := global_basis.x.normalized()
	var arm := tail_arm * back
	var work_area := tail_blade_count * tail_blade_chord * tail_radius * 0.5
	var lateral_velocity := (aircraft_velocity + aircraft_angular_velocity.cross(arm)).dot(right)
	var blade_velocity := tail_radius * angular_velocity * tail_gear_ratio
	var velocity := lateral_velocity + blade_velocity
	var pressure := 0.5 * velocity * velocity * density * work_area
	var lift_direction := -right
	var angle_of_attack := atan2(lateral_velocity, blade_velocity) + tail_pitch * tail_max_angle
	var lift := TAU * angle_of_attack if absf(angle_of_attack) < stall_angle else 0.0
	var force := lift * pressure * lift_direction
	var torque := arm.cross(force).dot(up) * up
	return torque


func _get_dynamic_pitch(blade_nagle: float) -> float:
	var blade_angle := wrapf(blade_nagle, -PI, PI)
	var angle_delta := wrapf(stick_angle - blade_angle, -PI, PI)
	var x := absf(angle_delta) / PI
	var dynamic_pitch := lerpf(-stick_len, stick_len, x)
	return clampf(0.5 * (dynamic_pitch + 1.0), 0.0, 1.0)


func _create_blade(index: int) -> VehicleWing3D:
	var blade := VehicleWing3D.new()
	blade.mirror = false
	blade.relax_forces = false
	blade.alternative_drag = alternative_drag
	blade.debug = debug
	blade.span = radius
	blade.chord = blade_chord
	blade.twist = blade_twist
	blade.twist_power = blade_twist_power
	blade.zero_lift_angle = blade_zero_lift_angle
	blade.stall_angle_max = stall_angle
	blade.stall_angle_min = -stall_angle - blade_zero_lift_angle
	blade.stall_width = stall_width
	blade.restore_stall_angle = restore_stall_angle
	blade.flap_angle_min = 0.0
	blade.flap_angle_max = 0.0
	blade.flap_start = 0.0
	blade.flap_end = 0.0
	blade.aileron_start = 0.0
	blade.aileron_end = 0.0
	blade.name = "Blade_" + str(index)
	blade.rotation.y = index * TAU / blade_count
	blade.rotation_degrees.x = collective_angle_min
	blade.position = blade.basis.x * blade_chord * 0.5
	return blade


var VehicleRotor3DDebugView := preload("uid://c8fd6k112j85a")
func _update_debug_view() -> void:
	if _debug_view != null and not debug:
		_debug_view.queue_free()
		_debug_view = null
	elif _debug_view == null and debug:
		_debug_view = VehicleRotor3DDebugView.new()
		add_child(_debug_view)
	for blade in _blades:
		blade.debug = debug
