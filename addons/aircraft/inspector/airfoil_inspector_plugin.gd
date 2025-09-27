@tool
extends EditorInspectorPlugin

var AirfoilView := preload("uid://c2njpwvtq5rff")


func _can_handle(object: Object) -> bool:
	return object is Airfoil


func _parse_begin(object: Object) -> void:
	var airfoil := object as Airfoil
	if airfoil == null:
		return
	var view := AirfoilView.new()
	view.preview = true
	view.custom_minimum_size.y = 384
	view.interval = 45.0
	view.max_value = 2.0
	view.grid_step = 0.5
	view.airfoil = airfoil
	add_custom_control(view)
