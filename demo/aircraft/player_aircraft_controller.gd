extends Node
class_name PlayerAircraftController

@onready var aircraft := get_parent() as AircraftBody3D

var aileron_key := 0.0
var elevator_key := 0.0
var rudder_key := 0.0


func _process(delta: float) -> void:
	if aircraft == null:
		return

	process_keyboard_values(delta)

	aircraft.input_ailerons = clampf(aileron_key + Input.get_axis("aileron_right", "aileron_left"), -1.0, 1.0)
	aircraft.input_elevator = clampf(elevator_key + Input.get_axis("elevator_down", "elevator_up"), -1.0, 1.0)
	aircraft.input_rudder = clampf(rudder_key + Input.get_axis("rudder_left", "rudder_right"), -1.0, 1.0)
	aircraft.steering = deg_to_rad(-aircraft.input_rudder) * aircraft.steering_value
	aircraft.brake = Input.get_action_strength("brake") * aircraft.brake_value

	if Input.is_action_pressed("throttle_down"):
		aircraft.input_throttle = move_toward(aircraft.input_throttle, 0.0, delta)
	if Input.is_action_pressed("throttle_up"):
		aircraft.input_throttle = move_toward(aircraft.input_throttle, 1.0, delta)


func _input(event: InputEvent) -> void:
	if aircraft == null:
		return
	var mode := Input.is_action_pressed("mode")
	if mode:
		if event.is_action_pressed("flap_down"):
			aircraft.change_trim_elevator(-1)
		elif event.is_action_pressed("flap_up"):
			aircraft.change_trim_elevator(1)
		elif event.is_action_pressed("right"):
			aircraft.change_trim_aileron(-1)
		elif event.is_action_pressed("left"):
			aircraft.change_trim_aileron(1)
	else:
		if event.is_action_pressed("flap_down"):
			aircraft.change_flap_mode(1)
		elif event.is_action_pressed("flap_up"):
			aircraft.change_flap_mode(-1)
		elif event.is_action_pressed("left"):
			aircraft.input_engine_running = not aircraft.input_engine_running
		elif event.is_action_pressed("thruster_mode"):
			aircraft.toggle_thruster_mode()


func process_keyboard_values(delta: float) -> void:
	var aileron_target := Input.get_axis("aileron_right_key", "aileron_left_key")
	var elevator_target := Input.get_axis("elevator_down_key", "elevator_up_key")
	var rudder_target := Input.get_axis("rudder_left_key", "rudder_right_key")
	aileron_key = move_toward(aileron_key, aileron_target, delta * _key_speed(aileron_key, aileron_target))
	elevator_key = move_toward(elevator_key, elevator_target, delta * _key_speed(elevator_key, elevator_target))
	rudder_key = move_toward(rudder_key, rudder_target, delta * _key_speed(rudder_key, rudder_target))


func _key_speed(current: float, target: float) -> float:
	if current * target < 0.0:
		return 2.0
	return 1.0 if absf(target) > 0.0 else 2.0
