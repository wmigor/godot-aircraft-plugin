extends VehicleThruster3D

@export var max_thrust := 16870.0
@export var max_rpm := 10000.0
@export var reverse: bool

func _physics_process(_delta: float) -> void:
	if _body == null or not visible or Engine.is_editor_hint():
		return
	var forward := -_body.basis.z
	if reverse:
		forward *= -1.0
	thrust = max_thrust * throttle
	var force := thrust * forward
	_body.apply_force(force, global_position - _body.global_position)
	angular_velocity = max_rpm * throttle / TO_RPM
	if angular_velocity	 < 0.0:
		angular_velocity = 0.0


func toggle_mode() -> void:
	reverse = not reverse
