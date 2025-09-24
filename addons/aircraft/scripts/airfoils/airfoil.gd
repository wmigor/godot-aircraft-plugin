@abstract
extends Resource
class_name Airfoil


class Data:
	var angle_of_attack: float
	var aspect_ratio: float
	var control_surface_fraction: float
	var control_surface_angle: float
	var wind: Vector3
	var chord: float
	var lift_factor: float
	var drag_factor: float
	var pitch_factor: float
	var stall: bool
	var stall_warning: bool


@abstract func update_factors(data: Data) -> void
