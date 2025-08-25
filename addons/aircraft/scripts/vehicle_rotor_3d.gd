extends Node3D
class_name VehicleRotor3D

@export var radius := 10.5
@export var blade_count := 2
@export var blade_chord := 0.5
@export var blade_twist := -12.0
@export var blade_twist_power := 1.0
@export var stall_angle := 14.0
@export var stall_width := 2.0
@export var blade_zero_lift_angle := -2.0
@export var collective_angle_min := 2.0
@export var collective_angle_max := 14.5
@export var azimuthal_angle_min := -6.0
@export var azimuthal_angle_max := 6.0
@export var rpm_max := 192.0
@export var inertia := 3000.0
@export var engine_torque_max := 110000
@export var debug := true

var force: Vector3
var torque: Vector3
var angular_velocity: float
var pitch: float
var stick_angle: float
var stick_len: float
var running: float = true
var rudder: float

var _blades: Array[VehicleWing3D]
var _engine_torque: float
var _body: RigidBody3D


func _enter_tree() -> void:
	_body = get_parent() as RigidBody3D


func _exit_tree() -> void:
	_body = null


func _ready() -> void:
	for i in blade_count:
		var blade := VehicleWing3D.new()
		blade.mirror = false
		blade.debug = debug
		blade.span = radius
		blade.chord = blade_chord
		blade.twist = deg_to_rad(blade_twist)
		blade.twist_power = blade_twist_power
		blade.zero_lift_angle = deg_to_rad(blade_zero_lift_angle)
		blade.stall_angle_max = deg_to_rad(stall_angle)
		blade.stall_angle_min = -deg_to_rad(stall_angle - blade_zero_lift_angle)
		blade.stall_width = deg_to_rad(stall_width)
		blade.restore_stall_angle = deg_to_rad(30)
		blade.flap_angle_min = 0.0
		blade.flap_angle_max = 0.0
		blade.flap_start = 0.0
		blade.flap_end = 0.0
		blade.aileron_start = 0.0
		blade.aileron_end = 0.0
		blade.name = "Blade_" + str(i)
		blade.rotation_degrees.y = i * 360.0 / blade_count
		blade.rotation_degrees.x = collective_angle_min
		blade.position = blade.basis.x * blade_chord * 0.5
		_blades.append(blade)
		add_child(blade)
		blade.set_owner(get_tree().get_edited_scene_root())


func _physics_process(delta: float) -> void:
	if _body == null:
		return
	var state := PhysicsServer3D.body_get_direct_state(_body.get_rid())
	_calculate(delta, _body.transform * state.center_of_mass_local, state.linear_velocity, state.angular_velocity, 1.2255)


func _calculate(delta: float, mass_center: Vector3, aircraft_velocity: Vector3, aircraft_angular_velocity: Vector3, density: float) -> void:
	force = Vector3.ZERO
	torque = Vector3.ZERO
	var up := global_transform.basis.y.normalized()
	var rotor_torque := 0.0
	var rotor_av := angular_velocity * up
	for blade in _blades:
		blade.calculate(aircraft_velocity.dot(up) * up, aircraft_angular_velocity + rotor_av, mass_center)
		#blade.rotation_degrees.z = 0.0
		var collective_angle := lerpf(collective_angle_min, collective_angle_max, clampf(pitch, 0.0, 1.0))
		var azimut_angle := lerpf(azimuthal_angle_min, azimuthal_angle_max, _get_dynamic_pitch(blade))
		blade.rotation_degrees.x = collective_angle + azimut_angle
		force += blade.get_force()
		torque += blade.get_torque() - blade.get_torque().dot(up) * up
		var blade_lift := blade.get_force().dot(up) * 0.0
		rotor_torque += blade.get_torque().dot(up)
		#for i in blade.get_section_count():
			#var section_global_transform := blade.global_transform * blade.get_section_transform(i)
			#var radius_vector := section_global_transform.origin - mass_center
			#var wind := _get_surface_wind(surface, up, radius_vector, aircraft_velocity, aircraft_angular_velocity)
			#surface.calculate_forces(wind, density)
			#force += surface.force
			#blade_lift += surface.force.dot(up)
			#torque += _get_surface_aircraft_torque(surface, up, radius_vector)
			#rotor_torque += _get_surface_rotor_torque(surface, up)
		blade.rotation_degrees.z = _get_blade_bend_angle(blade_lift)
	_calc_fake_rudder(aircraft_angular_velocity, up)
	_integrate_engine(delta, rotor_torque)
	_body.apply_central_force(force)
	_body.apply_torque(torque)


func _get_blade_bend_angle(blade_lift: float) -> float:
	return clampf(5.0 * blade_lift / (6000.0 * 9.8 / blade_count), -20, 20)


func _integrate_engine(delta: float, rotor_torque: float) -> void:
	if running:
		var rpm := maxf(0.0, angular_velocity * Motor.TO_RPM)
		var min_torque := 0.01 * engine_torque_max
		if rpm <= rpm_max:
			var rpm_factor := rpm / rpm_max
			var lerp_param := rpm_factor * rpm_factor * (3.0 - 2.0 * rpm_factor)
			_engine_torque = lerpf(min_torque, engine_torque_max, lerp_param)
		else:
			var rpm_factor = (rpm - rpm_max) / 2.0
			_engine_torque = lerpf(engine_torque_max, 0.0, rpm_factor)
		if _engine_torque < min_torque:
			_engine_torque += min_torque
	else:
		_engine_torque = 0.0
	angular_velocity += (rotor_torque + _engine_torque) / inertia * delta
	print(angular_velocity * Motor.TO_RPM)
	rotate_y(angular_velocity * delta)


func _calc_fake_rudder(aircraft_angular_velocity: Vector3, up: Vector3) -> void:
	var up_omega := 6 * (PI / 2 * rudder - aircraft_angular_velocity.dot(up))
	torque += up * 3000 * up_omega * absf(up_omega)


func _get_dynamic_pitch(blade: VehicleWing3D) -> float:
	var blade_angle_y := wrapf(blade.rotation.y + rotation.y, -PI, PI)
	var angle_delta := wrapf(stick_angle - blade_angle_y, -PI, PI)
	var x := absf(angle_delta) / PI
	var dynamic_pitch := lerpf(-stick_len, stick_len, x)
	return clampf(0.5 * (dynamic_pitch + 1.0), 0.0, 1.0)
