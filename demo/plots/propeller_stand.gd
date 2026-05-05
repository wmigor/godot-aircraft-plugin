extends Control

@onready var _plots_view := $PlotsView as PlotsView


func _ready() -> void:
	_build_plots()


func _process(_delta: float) -> void:
	_build_plots()


func _build_plots() -> void:
	_plots_view.clear()
	for propeller in find_children("*", "VehiclePropeller3D"):
		_build_plot(propeller)


func _build_plot(propeller: VehiclePropeller3D, velocity_min := 0, velocity_max := 200, step := 10) -> void:
	var thrusts := PackedVector2Array()
	var powers := PackedVector2Array()
	for velocity in range(velocity_min, velocity_max, step):
		propeller.angular_velocity = 500 / VehiclePropeller3D.TO_RPM
		propeller._calculate_factors(velocity / VehiclePropeller3D.TO_KMPH)
		var diameter := propeller.radius * 2.0
		#var j := velocity / (diameter * propeller.rps) if absf(propeller.rps) > 0.001 else velocity / diameter
		var j := velocity / propeller.angular_velocity
		thrusts.append(Vector2(j, propeller._thrust_factor))
		powers.append(Vector2(j, propeller._power_required_factor))
	_plots_view.add_plot(PlotsView.Data.new(thrusts, Color.BLUE, 2.0))
	_plots_view.add_plot(PlotsView.Data.new(powers, Color.RED, 2.0))
