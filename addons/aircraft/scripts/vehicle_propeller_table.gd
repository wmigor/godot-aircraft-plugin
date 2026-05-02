extends VehicleThruster3D
class_name VehiclePropellerTable

@export var max_rpm := 2700.0
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var max_engine_power := 160.0
@export var inertia := 6.5
@export var radius := 0.953
@export var reverse: bool
@export var apply_engine_torque: bool
@export var apply_gyroscopic_torque: bool
@export var feather: bool
@export var thrust_table: Array[Vector2] = [
	Vector2(0.0, 0.073),
	Vector2(0.1, 0.073),
	Vector2(0.2, 0.072),
	Vector2(0.3, 0.071),
	Vector2(0.4, 0.069),
	Vector2(0.5, 0.066),
	Vector2(0.6, 0.062),
	Vector2(0.7, 0.055),
	Vector2(0.8, 0.045),
	Vector2(0.9, 0.034),
	Vector2(1.0, 0.024),
	Vector2(1.1, 0.013),
	Vector2(1.2, -0.006),
	Vector2(1.3, -0.013),
	Vector2(1.4, -0.024),
	Vector2(1.5, -0.034),
	Vector2(1.6, -0.045),
	Vector2(1.7, -0.055),
	Vector2(1.8, -0.062),
	Vector2(1.9, -0.066),
	Vector2(2.0, -0.069),
	Vector2(2.1, -0.071),
	Vector2(2.2, -0.072),
	Vector2(2.3, -0.073),
	Vector2(5.0, -0.073)
]

@export var power_table: Array[Vector2] = [
	Vector2(0.0, 0.0660),
	Vector2(0.1, 0.0700),
	Vector2(0.2, 0.0700),
	Vector2(0.3, 0.0660),
	Vector2(0.4, 0.0600),
	Vector2(0.5, 0.0530),
	Vector2(0.6, 0.0501),
	Vector2(0.7, 0.0469),
	Vector2(0.8, 0.0426),
	Vector2(0.9, 0.0360),
	Vector2(1.0, 0.0282),
	Vector2(1.1, 0.0191),
	Vector2(1.2, 0.0155),
	Vector2(1.3, 0.0191),
	Vector2(1.4, 0.0282),
	Vector2(1.5, 0.0360),
	Vector2(1.6, 0.0426),
	Vector2(1.7, 0.0469),
	Vector2(1.8, 0.0501),
	Vector2(1.9, 0.0516),
	Vector2(2.0, 0.0525),
	Vector2(2.1, 0.0525),
	Vector2(2.2, 0.0522),
	Vector2(2.3, 0.0511),
	Vector2(2.4, 0.0504),
	Vector2(5.0, 0.0493)
]

var _thrust_curve: Curve
var _power_curve: Curve
var _debug_view: Node3D

var min_rpm: float:
	get(): return max_rpm * 0.2

var max_torque: float:
	get(): return max_engine_power * HP_TO_W / max_rpm * TO_RPM


func _ready() -> void:
	_thrust_curve = _build_curve(thrust_table)
	_power_curve = _build_curve(power_table)


func _build_curve(points: Array[Vector2]) -> Curve:
	var curve := Curve.new()
	curve.min_domain = points[0].x
	curve.max_domain = points[len(points) - 1].x
	curve.min_value = points.map(func (p): return p.y).min()
	curve.max_value = points.map(func (p): return p.y).max()
	for point in points:
		curve.add_point(point)
	curve.bake()
	return curve


func _physics_process(delta: float) -> void:
	if _body == null or not visible or Engine.is_editor_hint():
		return
	var forward := -_body.basis.z
	var velocity := _body.linear_velocity.dot(forward)
	var engine_torque := _get_engine_torque()
	_calculate(engine_torque, velocity, forward)
	var force := thrust * forward
	_body.apply_force(force, global_position - _body.global_position)
	if apply_engine_torque:
		_apply_engine_torque(forward)
	if apply_gyroscopic_torque:
		_apply_gyroscopic_torque(forward)
	angular_velocity += (engine_torque - torque) / inertia * delta
	if angular_velocity	 < 0.0:
		angular_velocity = 0.0


func _calculate(engine_torque: float, velocity: float, forward: Vector3) -> void:
	if velocity < 0.0:
		velocity = 0.0

	var rps := rpm / 60.0
	var diameter := radius * 2.0
	var j := velocity / (diameter * rps) if absf(rps) > 0.1 else velocity / diameter
	var cp := _power_curve.sample_baked(j)
	var ct := _thrust_curve.sample_baked(j)
	var power_required := cp * pow(maxf(0.01, absf(rps)), 3.0) * pow(diameter, 5.0) * density
	var torque_required := power_required / angular_velocity if absf(angular_velocity) > 0.1 else power_required
	thrust = ct * pow(rps, 2) * pow(diameter, 4) * density
	torque = torque_required
	wind_induced = -forward * _calc_wind_induced(velocity, density)


func get_radius() -> float:
	return radius


func _get_engine_torque() -> float:
	var starter_torque := max_torque * 0.2
	if throttle <= 0 or not running:
		return - angular_velocity * 0.1
	if rpm >= min_rpm:
		return throttle * _get_nominal_engine_torque()
	return starter_torque


func _get_nominal_engine_torque() -> float:
	if rpm > max_rpm:
		var x := clampf((rpm - max_rpm) / (max_rpm * 0.25), 0.0, 1.0)
		return lerpf(max_torque, 0.0, x * x * (3.0 - 2.0 * x))
	var x := 1.0 - rpm / max_rpm
	x = 1.0 - x * x * x * x
	return lerpf(0.0, max_torque, x)


func _apply_engine_torque(forward: Vector3) -> void:
	var direction := 1.0 if reverse else -1.0
	_body.apply_torque(direction * forward * torque)


func _apply_gyroscopic_torque(forward: Vector3) -> void:
	var direction := -1.0 if reverse else 1.0
	var gyro_torque := direction * forward * angular_velocity * inertia
	_body.apply_torque(gyro_torque.cross(_body.angular_velocity))


func _calc_wind_induced(velocity: float, density: float) -> float:
	if feather:
		return 0.0
	var area := radius * radius * PI
	var vel2sum := velocity * absf(velocity) + 2.0 * thrust / (density * area)
	if vel2sum > 0.0:
		return 0.5 * (-velocity + sqrt(vel2sum))
	return 0.5 * (-velocity - sqrt(-vel2sum))


func toggle_mode() -> void:
	feather = not feather


var VehiclePropeller3DDebugView := preload("uid://bi5f3pjnf633x")
func _update_debug_view() -> void:
	if _debug_view != null:
		_debug_view.queue_free()
		_debug_view = null
	if debug:
		_debug_view = VehiclePropeller3DDebugView.new()
		add_child(_debug_view)
