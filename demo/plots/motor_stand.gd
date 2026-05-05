extends Control

@onready var _plots_view := $PlotsView as PlotsView


func _ready() -> void:
	_build_plots()


func _process(_delta: float) -> void:
	_build_plots()


func _build_plots() -> void:
	_plots_view.clear()
	for motor in find_children("*", "Motor"):
		_build_plot(motor)
		#_build_leinderman_plot(motor)


func _build_leinderman_plot(motor: MotorSimple) -> void:
	var torques := PackedVector2Array()
	var powers := PackedVector2Array()
	for i in 125:
		var n := (i + 1.0) / 100.0
		var t := motor.start_rpm / motor.peak_rpm
		var s := motor.peak_power_hp * motor.start_power_ratio / motor.peak_power_hp
		var power := motor.get_leiderman_power_factor(n, t, s)
		powers.append(Vector2(n, power))
		torques.append(Vector2(n, power / n))
	_plots_view.add_plot(PlotsView.Data.new(torques, Color.BLUE, 2.0))
	_plots_view.add_plot(PlotsView.Data.new(powers, Color.RED, 2.0))


func _build_plot(motor: Motor, rpm_min := 0, rpm_max := 3000, step := 1) -> void:
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
