@tool
class_name NoiseTerrain
extends TerrainFunction

@export var noises: Array[FastNoiseLite]:
	set(new):
		noises = new
		if noises:
			for i in noises.size():
				noises[i].changed.connect(function_changed.emit)
			function_changed.emit()

@export_range(0, 1, 0.01) var persistance := 0.3:
	set(new):
		persistance = new
		function_changed.emit()

@export_range(1, 32, 0.01) var lacunarity := 2.0:
	set(new):
		lacunarity = new
		for i in noises.size():
			noises[i].frequency = 0.001 * (lacunarity ** i)
		function_changed.emit()

func get_height(x: float, y: float) -> float:
	var total := 0.0
	
	for i in noises.size():
		total += noises[i].get_noise_2d(x, y) * (persistance ** i)
	
	return total
