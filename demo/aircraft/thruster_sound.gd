extends AudioStreamPlayer3D

@export var min_pitch := 0.2
@export var rpm_divider := 1500.0

@onready var _thruster := get_parent() as VehicleThruster3D


func _physics_process(_delta: float) -> void:
	if _thruster == null:
		return
	var pitch := absf(_thruster.rpm) / rpm_divider
	pitch_scale = maxf(min_pitch, pitch)
	if playing and pitch <= min_pitch:
		playing = false
	elif not playing and pitch > min_pitch:
		playing = true
