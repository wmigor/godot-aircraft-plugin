extends VehiclePropeller3D
class_name VehiclePropellerTable

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


func _calculate_factors(velocity: float) -> void:
	var diameter := radius * 2.0
	var j := velocity / (diameter * rps) if absf(rps) > 0.1 else velocity / diameter
	_power_required_factor = _power_curve.sample_baked(j)
	_thrust_factor = _thrust_curve.sample_baked(j)

#
#func _calculate(engine_torque: float, velocity: float, forward: Vector3) -> void:
	#if velocity < 0.0:
		#velocity = 0.0
#
	#var rps := rpm / 60.0
	#var diameter := radius * 2.0
	#var j := velocity / (diameter * rps) if absf(rps) > 0.1 else velocity / diameter
	#var cp := _power_curve.sample_baked(j)
	#var ct := _thrust_curve.sample_baked(j)
	#var power_required := cp * pow(maxf(0.01, absf(rps)), 3.0) * pow(diameter, 5.0) * density
	#var torque_required := power_required / angular_velocity if absf(angular_velocity) > 0.1 else power_required
	#thrust = ct * pow(rps, 2) * pow(diameter, 4) * density
	#torque = torque_required
	#wind_induced = -forward * _calc_wind_induced(velocity, density)
