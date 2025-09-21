@tool
class_name TerrainFunction
extends Resource

signal function_changed

func get_height(x: float, y: float) -> float:
	return 0

func get_normal(x: float, y: float, amplitude: float, epsilon: float) -> Vector3:
	return Vector3(
		(get_height(x + epsilon, y) - get_height(x - epsilon, y)) / (2.0 * epsilon) * amplitude,
		1.0,
		(get_height(x, y + epsilon) - get_height(x, y - epsilon)) / (2.0 * epsilon) * amplitude
	).normalized()
