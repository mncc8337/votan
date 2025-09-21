@tool
extends Node

@onready var chunk_scene = preload("res://objects/chunk.tscn")

@export var player: CharacterBody3D

var current_chunk_pos := Vector2i.ZERO
var stored_chunk_pos := Vector2i.ZERO
var all_chunks: Array[Chunk] = []
var unloaded_chunks: Array[Chunk] = []
var unloaded_chunks_mutex: Mutex
var chunk_loader_semaphore: Semaphore

var chunk_load_thread : Thread

@export_range(1, 16, 1) var render_distance: int = 2:
	set(new): 
		render_distance = new
		reload_chunks()

@export var chunk_size := 256.0:
	set(new):
		chunk_size = new
		for chunk in all_chunks:
			chunk.size = chunk_size
		reload_chunks()

@export var chunk_resolution: int = 8:
	set(new):
		chunk_resolution = new
		update_terrain()

@export var chunk_amplitude: float = 5.3:
	set(new):
		chunk_amplitude = new
		update_terrain()

@export var terrain_function: TerrainFunction:
	set(new):
		terrain_function = new
		if terrain_function:
			terrain_function.function_changed.connect(update_terrain)

func _ready() -> void:
	chunk_loader_semaphore = Semaphore.new()
	unloaded_chunks_mutex = Mutex.new()
	chunk_load_thread = Thread.new()
	chunk_load_thread.start(chunk_loader)
	reload_chunks()

func _process(delta: float) -> void:
	current_chunk_pos = get_chunk_position(player.position)
	if current_chunk_pos != stored_chunk_pos:
		move_chunks()
		stored_chunk_pos = current_chunk_pos

func chunk_loader() -> void:
	while true:
		if len(unloaded_chunks) == 0:
			# self-block if there is nothing to do
			chunk_loader_semaphore.wait()
		
		unloaded_chunks_mutex.lock()
		unloaded_chunks.pop_front().update_mesh.call_deferred()
		unloaded_chunks_mutex.unlock()

func reload_chunks() -> void:
	if not player:
		return
	
	# clear existed chunks
	for child in all_chunks:
		remove_child(child)
		child.queue_free()
	all_chunks.clear()
	
	# generate points inside a circle
	var valid_points: Array[Vector2i] = []
	for y in range(-render_distance, render_distance + 1):
		var max_x = int(floor(sqrt(render_distance * render_distance - y * y)))
		for x in range(-max_x, max_x + 1):
			valid_points.append(Vector2i(x, y) + get_chunk_position(player.position))
	
	# then create as many chunks and assign those position to them
	for pos in valid_points:
		var new_chunk: Chunk = chunk_scene.instantiate()
		new_chunk.set_param(chunk_resolution, chunk_amplitude, terrain_function)
		new_chunk.size = chunk_size
		new_chunk.chunk_position = pos
		add_child(new_chunk)
		all_chunks.append(new_chunk)
		add_to_render_queue(new_chunk)
	chunk_loader_semaphore.post()

func move_chunks() -> void:
	# generate points inside render ranges
	var old_range_points: Array[Vector2i] = []
	var new_range_points: Array[Vector2i] = []
	for y in range(-render_distance, render_distance + 1):
		var max_x = int(floor(sqrt(render_distance * render_distance - y * y)))
		for x in range(-max_x, max_x + 1):
			old_range_points.append(Vector2i(x, y) + stored_chunk_pos)
			new_range_points.append(Vector2i(x, y) + current_chunk_pos)
	
	var overlap_points: Array[Vector2i] = []
	for p1 in old_range_points:
		for p2 in new_range_points:
			if p1 == p2:
				overlap_points.append(p1)
				old_range_points.erase(p1)
				new_range_points.erase(p1)

	# now old_range_points should contain to be moved chunks' position
	# and new_range_points should contain not filled positions
	# and both should have the same length
	
	# move chunks to new position
	for chunk in all_chunks:
		if not len(old_range_points):
			break
		if chunk.chunk_position in old_range_points:
			old_range_points.erase(chunk.chunk_position)
			chunk.chunk_position = new_range_points.pop_back()
			add_to_render_queue(chunk)
	chunk_loader_semaphore.post()

func update_terrain() -> void:
	if not player:
		return

	for child: Chunk in all_chunks:
		child.set_param(chunk_resolution, chunk_amplitude, terrain_function)
		child.update_mesh()

func get_chunk_position(pos: Vector3) -> Vector2i:
	# convert world pos to chunk pos
	var d = Vector2(chunk_size, chunk_size) / 2
	if pos.x < 0:
		d.x *= -1
	if pos.z < 0:
		d.y *= -1
	return (Vector2(pos.x, pos.z) + d) / chunk_size

func add_to_render_queue(chunk: Chunk):
	unloaded_chunks_mutex.lock()
	unloaded_chunks.append(chunk)
	unloaded_chunks_mutex.unlock()
