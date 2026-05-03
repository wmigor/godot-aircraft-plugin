extends Node
class_name PistonMotor

@export var power_hp0 := 160.0
@export var rpm0 := 2700.0
@export var compression := 8.0
@export var displacement := 0.0
@export_range(0.0, 1.0, 0.001) var throttle := 0.0
@export_range(0.0, 1.0, 0.001) var mixture := 1.0

const TO_RPM := 60.0 / TAU
const TO_KMPH = 3.6
const HP_TO_W := 745.7
const CIN_TO_CM := 1.6387064e-5

var _power0: float
var _angular_velocity0: float
var _mix_factor: float
var _displacement: float
var _f0: float
var _charge: float
var _mp: float
var _boost_pressure: float
var _fuel_flow: float
var _fuel := true
var _density0 := 1.226
var _min_throttle := 0.1
var _turbo_lag := 2.0
var _charge_target := 2.0
var _boost := 1.0
var _turbo := 1.0
var _has_super := false
var _magnetos := 3
var _egt: float
var _oil_temp_target: float
var _oil_temp_velocity: float
var _oil_temp: float

var running: bool
var torque: float


func _ready() -> void:
	_angular_velocity0 = rpm0 / TO_RPM
	_power0 = power_hp0 * HP_TO_W
	_f0 = _power0 * 7.62e-08
	var real_flow := _f0 * 11.0 / 8.0
	_mix_factor = real_flow * 1.1 / _power0
	if displacement <= 0.0:
		_displacement = _power0 * (2.0 * CIN_TO_CM)
	_oil_temp = 288.15
	_oil_temp_target = _oil_temp


func integrate(delta: float) -> void:
	_oil_temp += _oil_temp_velocity * delta
	var decay := 2.3 / _turbo_lag
	_charge = (_charge + delta * decay * _charge_target) / (1 + delta * decay)


func calculate(angular_velocity: float, pressure: float, temperature: float) -> void:
	running = _fuel and angular_velocity * TO_RPM > 60.0
	var starter := not running and angular_velocity * TO_RPM > rpm0 / 10.0 and throttle >= _min_throttle
	var rpm_norm := angular_velocity / _angular_velocity0;
	var A := 1.795206541
	var B := 0.55620178
	var C := 1.246708471
	var rpm_factor = A * pow(B, rpm_norm) * pow(rpm_norm, C)
	_charge_target = 1 + (_boost * (_turbo-1) * rpm_factor)

	if _has_super:
		_charge = _charge_target
	elif not running:
		_charge_target = 1.0 + (_charge_target - 1.0) * 0.25

	_mp = pressure * _charge
	
	if running:
		var min_mp := (-0.008 * _turbo ) + _min_throttle
		_mp *= min_mp + (1.0 -min_mp) * throttle

	var max_mp := _mp / _charge
	_mp = minf(_mp, max_mp)
	_boost_pressure = _mp - pressure

	var T := temperature * pow(_mp * _mp / (pressure * pressure), 1.0 / 7.0)
	var density := _mp / (287.1 * T)
	
	_fuel_flow = (mixture * angular_velocity * _mix_factor) if _fuel else 0.0
	var burnable := _f0 * (density / _density0) * (angular_velocity / _angular_velocity0)

	var r := _fuel_flow / burnable
	var burned := 0.0
	if burnable <= 0.0:
		burned = 0.0
	elif r < 0.625:
		burned = _fuel_flow
	elif r > 1.375:
		burned = burnable
	else:
		burned = _fuel_flow + (burnable - _fuel_flow) * (r - 0.625) * (4.0 / 3.0)
	
	if not running:
		burned = 0

	if _magnetos < 3:
		burned *= 0.9

	var power := _power0 * burned / _f0
	torque = (power / angular_velocity) if absf(angular_velocity) > 0.001 else 0.0

	if starter and not running:
		torque += 0.15 * _power0 / _angular_velocity0

	if angular_velocity > 0.0 and angular_velocity < _angular_velocity0:
		var interp := 2.0 - 2.0 * angular_velocity / _angular_velocity0
		interp = 1.0 if interp > 1 else interp
		torque -= 0.08 * (_power0 / _angular_velocity0) * interp

	var mass_flow := _fuel_flow + (density * 0.5 * _displacement * angular_velocity)
	var spec_heat := 1300
	var corr := 1.0 / (pow(compression, 0.4) - 1.0)
	var egt_delta = corr * (power * 1.1) / (mass_flow * spec_heat)

	_egt = temperature + egt_delta
	var tau := 0.0
	if running:
		_oil_temp_target = 363.0 + 30.0 * power / _power0
		tau = 600.0 - 300.0 * power / _power0
	else:
		_oil_temp_target = temperature
		tau = 1500.0

	_oil_temp_velocity = (_oil_temp_target - _oil_temp) / tau
