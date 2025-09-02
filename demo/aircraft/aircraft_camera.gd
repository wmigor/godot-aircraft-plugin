extends Camera3D
class_name AircraftCamera

@export var distance := 10.0
@export var default_pitch := -20.0
@export var stick_sens := 360.0

@onready var aircraft := get_parent() as AircraftBody3D

var yaw := 0.0
var pitch := deg_to_rad(default_pitch)


func _process(delta: float) -> void:
	if aircraft == null:
		return
	_process_stick(delta)
	var up := aircraft.basis.y
	var right := aircraft.basis.x
	var velocity := aircraft.linear_velocity
	if aircraft.has_rotor:
		velocity *= 0.0
	var direction := velocity.normalized().rotated(right, pitch).rotated(up, yaw)
	var speed := velocity.length()
	if speed < 3.0:
		direction = lerp(-aircraft.basis.z.rotated(right, pitch).rotated(up, yaw), direction, speed / 3)
	global_position = aircraft.position - direction * distance
	up = (Quaternion(up, yaw) * right).cross(direction)
	look_at(aircraft.position, up)


func _process_stick(delta: float) -> void:
	var stick := Input.get_vector("camera_left", "camera_right", "camera_down", "camera_up")
	yaw -= deg_to_rad(stick.x) * delta * stick_sens
	pitch += deg_to_rad(stick.y) * delta * stick_sens


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= deg_to_rad(motion.relative.x)
		pitch -= deg_to_rad(motion.relative.y)
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		yaw -= deg_to_rad(drag.relative.x)
		pitch -= deg_to_rad(drag.relative.y)
		return
	if event.is_action_released("reset_camera"):
		yaw = 0.0
		pitch = deg_to_rad(default_pitch)
