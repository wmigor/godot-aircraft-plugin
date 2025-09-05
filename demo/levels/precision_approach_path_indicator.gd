extends Node3D
class_name PrecisionApproachPathIndicator

@export var up_material: Material
@export var down_material: Material
@export var angles: Array[float] = [2.5, 2.9, 3.1, 3.5]
@export var light_radius := 3.0

var _lights: Array[CSGCylinder3D]

var target: Node3D


func _ready() -> void:
	for i in len(angles):
		var light := CSGCylinder3D.new()
		light.position.y = light_radius
		light.position.x = 0.5 * light_radius * (i + 1) + i * light_radius * 2.0
		light.rotation_degrees.x = 90.0
		light.radius = light_radius
		light.height = light_radius / 2.0
		_lights.append(light)
		add_child(light)


func _process(_delta: float) -> void:
	if target == null:
		return
	var vector := global_transform.affine_inverse() * (target.global_position - global_position)
	var angle := rad_to_deg(atan2(vector.y, -vector.z))
	for i in len(_lights):
		var light := _lights[i]
		var switch_angle := angles[i]
		light.material = up_material if angle > switch_angle else down_material
