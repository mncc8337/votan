@tool
class_name SineTerrain
extends TerrainFunction

@export_enum("x", "y") var component: int

@export var amplitude := 1.0:
	set(new):
		amplitude = new
		function_changed.emit()
@export var angular_frequency := 1.0:
	set(new):
		angular_frequency = new
		function_changed.emit()
@export var phase := 0.0:
	set(new):
		phase = new
		function_changed.emit()

func get_height(x: float, y: float) -> float:
	if component == 0:
		return amplitude * sin(angular_frequency * x + phase)
	else:
		return amplitude * sin(angular_frequency * y + phase)
