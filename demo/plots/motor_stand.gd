extends Control

@onready var _plots_view := $PlotsView as PlotsView
@onready var _torque_ratio := $HBoxContainer/TorqueRatio as HSlider
@onready var _torque_ratio_label := $HBoxContainer/Label as Label


func _ready() -> void:
	_build_plots()
	_torque_ratio.min_value = 0.01
	_torque_ratio.max_value = 0.9
	_torque_ratio.step = 0.01
	for motor in find_children("*", "MotorSimple"):
		_torque_ratio.value = motor.peak_torque_rpm_ratio
	_torque_ratio.value_changed.connect(_on_torque_ratio_changed)


func _on_torque_ratio_changed(value: float) -> void:
	for motor in find_children("*", "MotorSimple"):
		motor.peak_torque_rpm_ratio = value
	_torque_ratio_label.text = str(value)
	_build_plots()


func _build_plots() -> void:
	_plots_view.clear()
	for motor in find_children("*", "MotorSimple"):
		_build_plot(motor)
		#_build_leinderman_plot(motor)


func _build_leinderman_plot(motor: MotorSimple) -> void:
	var torques := PackedVector2Array()
	var powers := PackedVector2Array()
	for i in 125:
		var n := (i + 1.0) / 100.0
		var t := motor.peak_torque_rpm_ratio
		var power := motor.get_power_factor_exp(n, t)
		powers.append(Vector2(n, power))
		torques.append(Vector2(n, power / n))
	_plots_view.add_plot(PlotsView.Data.new(torques, Color.BLUE, 2.0))
	_plots_view.add_plot(PlotsView.Data.new(powers, Color.RED, 2.0))


func _build_plot(motor: Motor, rpm_min := 10, rpm_max := 3500, step := 1) -> void:
	var torques := PackedVector2Array()
	var powers := PackedVector2Array()
	for rpm in range(rpm_min, rpm_max, step):
		motor.rpm = rpm
		var torque := motor._calculate_torque()
		var power := torque * rpm / Motor.TO_RPM
		var power_hp := power / Motor.HP_TO_W
		torques.append(Vector2(rpm, torque))
		powers.append(Vector2(rpm, power_hp))
		#if torque <= 0.0 and not torques.is_empty():
			#break
	_plots_view.add_plot(PlotsView.Data.new(torques, Color.BLUE, 2.0))
	_plots_view.add_plot(PlotsView.Data.new(powers, Color.RED, 2.0))
