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

@export var default_vote: int = 15
@export var hide_threshold: int = 10

@export_range(1, 32, 1) var render_distance: int = 2:
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
		process_chunks()
		stored_chunk_pos = current_chunk_pos

func chunk_loader() -> void:
	while true:
		if len(unloaded_chunks):
			unloaded_chunks_mutex.lock()
			unloaded_chunks.pop_front().update_mesh.call_deferred()
			unloaded_chunks_mutex.unlock()
		else:
			# self-block if there is nothing to do
			chunk_loader_semaphore.wait()

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
	for y in range(-render_distance * 1.5, render_distance * 1.5 + 1):
		var max_x = int(floor(sqrt(render_distance * render_distance * 1.5 * 1.5 - y * y)))
		for x in range(-max_x, max_x + 1):
			valid_points.append(Vector2i(x, y) + get_chunk_position(player.position))
	
	# then create as many chunks and assign those position to them
	for pos in valid_points:
		var new_chunk: Chunk = chunk_scene.instantiate()
		new_chunk.set_param(chunk_resolution, chunk_amplitude, terrain_function)
		new_chunk.size = chunk_size
		new_chunk.chunk_position = pos
		new_chunk.chunk_vote = default_vote
		add_child(new_chunk)
		all_chunks.append(new_chunk)
		add_to_render_queue(new_chunk)
	chunk_loader_semaphore.post()

func process_chunks() -> void:
	# generate points inside render ranges
	var new_range_points: Array[Vector2i] = []
	for y in range(-render_distance, render_distance + 1):
		var max_x = int(floor(sqrt(render_distance * render_distance - y * y)))
		for x in range(-max_x, max_x + 1):
			new_range_points.append(Vector2i(x, y) + current_chunk_pos)
	
	# show existed chunks inside new range
	for chunk in all_chunks:
		if not len(new_range_points):
			break
		if chunk.chunk_position in new_range_points:
			new_range_points.erase(chunk.chunk_position)
			if chunk.visible == false:
				chunk.chunk_vote += hide_threshold * 1.5
			chunk.visible = true
			chunk.chunk_vote += 1
		else:
			chunk.chunk_vote -= 1
			if chunk.chunk_vote <= 0:
				all_chunks.erase(chunk)
				chunk.queue_free()
			elif chunk.chunk_vote < hide_threshold:
				chunk.visible = false
	
	# add new chunks
	for new_pos in new_range_points:
		var new_chunk: Chunk = chunk_scene.instantiate()
		new_chunk.set_param(chunk_resolution, chunk_amplitude, terrain_function)
		new_chunk.size = chunk_size
		new_chunk.chunk_position = new_pos
		new_chunk.chunk_vote = default_vote
		add_child(new_chunk)
		all_chunks.append(new_chunk)
		add_to_render_queue(new_chunk)
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
