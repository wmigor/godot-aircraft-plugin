extends Control

@export var cruise_power_hp := 120.0
@export var cruise_velocity_kmph := 200.0
@export var cruise_rpm := 2500.0
@export var efficiency := 0.85
@export var radius := 0.953
@export var density := 1.225

@onready var _plots_view := $PlotsView as PlotsView

var cruise_power: float:
	get(): return cruise_power_hp * Motor.HP_TO_W

var cruise_velocity: float:
	get(): return cruise_velocity_kmph / Motor.TO_KMPH

var cruise_rps: float:
	get(): return cruise_rpm / 60.0

var diameter: float:
	get(): return radius * 2.0


func _ready() -> void:
	_build_plots()


func _build_plots() -> void:
	_plots_view.clear()
	#_generate_plot()
	for propeller in find_children("*", "VehiclePropellerBase3D"):
		_build_plot(propeller)


func _build_plot(propeller: VehiclePropellerBase3D, velocity_min := 10, velocity_max := 400, step := 10) -> void:
	var thrusts := PackedVector2Array()
	var powers := PackedVector2Array()
	for velocity_kmph in range(velocity_min, velocity_max, step):
		var velocity := velocity_kmph / VehiclePropeller3D.TO_KMPH
		propeller.angular_velocity = 2500 / VehiclePropeller3D.TO_RPM
		for i in range(40):
			propeller._calculate_factors(velocity)
		var d := propeller.radius * 2.0
		var j := velocity / (d * propeller.rps) if absf(propeller.rps) > 0.001 else velocity / diameter
		thrusts.append(Vector2(j, propeller._thrust_factor))
		powers.append(Vector2(j, propeller._power_required_factor))
	_plots_view.add_plot(PlotsView.Data.new(thrusts, Color.BLUE, 2.0))
	_plots_view.add_plot(PlotsView.Data.new(powers, Color.RED, 2.0))


func _generate_plot(start:=0.0, end:=1.5, step:=0.01) -> void:
	var powers := PackedVector2Array()
	var thrusts := PackedVector2Array()
	var efficiencies := PackedVector2Array()
	var cruise_j := cruise_velocity / (cruise_rps * diameter)
	var j0 := cruise_j * 2
	var cruise_cp := cruise_power / (density * pow(cruise_rps, 3) * pow(diameter, 5))
	var cruise_ct := efficiency * cruise_cp / cruise_j
	var cp0 := 1.2 * cruise_cp
	var ct0 := 1.3 * cruise_ct
	var j := start
	while j < end:
		var cp := cp0 - (cp0 - cruise_cp) * pow(j / cruise_j, 3)
		var eta := absf(4.0 * efficiency * j / cruise_j * (1.0 - j / j0))
		var ct := eta * cp / maxf(0.001, j)
		powers.append(Vector2(j, cp))
		thrusts.append(Vector2(j, ct))
		efficiencies.append(Vector2(j, eta))
		j += step
	_plots_view.add_plot(PlotsView.Data.new(powers, Color.RED, 2.0))
	_plots_view.add_plot(PlotsView.Data.new(thrusts, Color.BLUE, 2.0))
	#_plots_view.add_plot(PlotsView.Data.new(efficiencies, Color.GREEN))
