@tool
class_name Chunk
extends StaticBody3D

@onready var tree_scene := preload("res://objects/tree.tscn")

@export var chunk_position: Vector2i:
	set(new):
		chunk_position = new
		update_pos()

var resolution: int
var amplitude: float
var terrain_function: TerrainFunction

var size: float = 256.0:
	set(new):
		size = new
		update_pos()

func update_pos():
	var flat_pos = chunk_position * size
	position.x = flat_pos.x
	position.z = flat_pos.y

func set_param(_resolution: int, _amplitude: float, _terrain_function: TerrainFunction):
	resolution = _resolution
	amplitude = _amplitude
	terrain_function = _terrain_function

func tree_probability(x: float, y: float, noise: float, normal: Vector3, random_factor: float) -> float:
	var angle = abs(acos(normal.dot(Vector3.UP)))

	return 1.0 / angle * 1.0 / (50 - noise) * random_factor

func update_mesh():
	# remove all trees to generate new one
	for child in %trees.get_children():
		child.queue_free()
	
	var plane := PlaneMesh.new()
	plane.subdivide_width = resolution
	plane.subdivide_depth = resolution
	plane.size = Vector2(size, size)
	
	var epsilon := size / float(resolution)
	
	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_position.y * 342342 + chunk_position.x
	
	for i: int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if terrain_function:
			vertex.y = terrain_function.get_height(vertex.x + position.x, vertex.z + position.z) * amplitude
			normal = terrain_function.get_normal(vertex.x + position.x, vertex.z + position.z, amplitude, epsilon)
			tangent = normal.cross(Vector3.UP).normalized()
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i + 0] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z

		if rng.randf() < tree_probability(vertex.x, vertex.z, vertex.y, normal, rng.randf()):
			var tree = tree_scene.instantiate()
			tree.position = vertex
			tree.rotation.x = rng.randf() * 0.3
			tree.rotation.z = rng.randf() * 0.3
			tree.rotation.y = rng.randf() * PI * 2
			%trees.add_child(tree)
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)

	%mesh.mesh = array_mesh
	%collision.shape = array_mesh.create_trimesh_shape()
