@tool
class_name SumOfSinesTerrain
extends TerrainFunction

@export var sines: Array[SineTerrain]:
	set(new):
		sines = new
		if sines:
			for i in sines.size():
				sines[i].function_changed.connect(function_changed.emit)
			function_changed.emit()

func get_height(x: float, y: float) -> float:
	var height = 0
	for sin in sines:
		height += sin.get_height(x, y)
	return height
