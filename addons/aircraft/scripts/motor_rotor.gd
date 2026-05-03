extends Motor
class_name MotorRotor

## Max RPM
@export var max_rpm := 192.0
## Max engine power
@export_custom(PROPERTY_HINT_NONE, "suffix:hp") var max_engine_power := 3800.0


func _calculate_torque() -> float:
	if not enabled:
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
