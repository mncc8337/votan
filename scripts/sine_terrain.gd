@tool
class_name SineTerrain
extends TerrainFunction

@export var a := 1.0:
	set(new):
		a = new
		function_changed.emit()
@export var b := 1.0:
	set(new):
		b = new
		function_changed.emit()
@export var c := 1.0:
	set(new):
		c = new
		function_changed.emit()
@export var d := 1.0:
	set(new):
		d = new
		function_changed.emit()
@export var e := 1.0:
	set(new):
		e = new
		function_changed.emit()
@export var f := 1.0:
	set(new):
		f = new
		function_changed.emit()

func get_height(x: float, y: float) -> float:
	return a * sin(b * x + c) + d * sin(e * y + f)
