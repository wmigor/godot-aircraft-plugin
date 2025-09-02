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

	var trim_aileron := aircraft.trim_aileron * aircraft.trim_scale
	aircraft.input_ailerons = clampf(aileron_key + trim_aileron + Input.get_axis("aileron_right", "aileron_left"), -1.0, 1.0)
	var trim_elevator := aircraft.trim_elevator * aircraft.trim_scale
	aircraft.input_elevator = clampf(elevator_key + trim_elevator + Input.get_axis("elevator_down", "elevator_up"), -1.0, 1.0)
	aircraft.input_rudder = clampf(rudder_key + Input.get_axis("rudder_left", "rudder_right"), -1.0, 1.0)
	aircraft.steering = deg_to_rad(-aircraft.input_rudder)
	aircraft.brake = Input.get_action_strength("brake") * aircraft.brake_value

	if Input.is_action_pressed("throttle_down"):
		aircraft.input_throttle = move_toward(aircraft.input_throttle, 0.0, delta)
	if Input.is_action_pressed("throttle_up"):
		aircraft.input_throttle = move_toward(aircraft.input_throttle, 1.0, delta)
	#if aircraft.rotor != null:
		#var stick := Vector2.ZERO
		#stick.y = clampf(elevator_key + Input.get_axis("elevator_down", "elevator_up"), -1.0, 1.0)
		#stick.x = -clampf(aileron_key + Input.get_axis("aileron_right", "aileron_left"), -1.0, 1.0)
		#aircraft.rotor.stick_angle = atan2(stick.y, stick.x)
		#aircraft.rotor.stick_len = stick.length()
		#aircraft.rotor.tail_pitch = clampf(rudder_key + Input.get_axis("rudder_left", "rudder_right"), -1.0, 1.0)

		#if Input.is_action_pressed("throttle_down"):
			#aircraft.rotor.pitch = move_toward(aircraft.rotor.pitch, 0.0, delta)
		#if Input.is_action_pressed("throttle_up"):
			#aircraft.rotor.pitch = move_toward(aircraft.rotor.pitch, 1.0, delta)

func _input(event: InputEvent) -> void:
	if aircraft == null:
		return
	var mode := Input.is_action_pressed("mode")
	if mode:
		if event.is_action_pressed("flap_down"):
			aircraft.trim_elevator = clampf(aircraft.trim_elevator - aircraft.trim_step, -1.0, 1.0)
		elif event.is_action_pressed("flap_up"):
			aircraft.trim_elevator = clampf(aircraft.trim_elevator + aircraft.trim_step, -1.0, 1.0)
		elif event.is_action_pressed("right"):
			aircraft.trim_aileron = clampf(aircraft.trim_aileron - aircraft.trim_step, -1.0, 1.0)
		elif event.is_action_pressed("left"):
			aircraft.trim_aileron = clampf(aircraft.trim_aileron + aircraft.trim_step, -1.0, 1.0)
	else:
		if event.is_action_pressed("flap_down"):
			aircraft.change_flap_mode(1)
		elif event.is_action_pressed("flap_up"):
			aircraft.change_flap_mode(-1)
		elif event.is_action_pressed("left") and aircraft.rotor != null:
			aircraft.rotor.running = not aircraft.rotor.running


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
