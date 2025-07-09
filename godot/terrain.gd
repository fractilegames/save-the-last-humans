extends Node2D

const CHUNK = preload("res://chunk.tscn")
const CHUNK_SIZE = 8
const SQUARE_SIZE = 1

export var height = 64
export var width = 64
var v_chunks: int = ceil(float(height) / float(CHUNK_SIZE))
var h_chunks: int = ceil(float(width) / float(CHUNK_SIZE))
var chunks = []
var altered_chunks = {}
#FIX NOISE- AIR SHOULD ALWAYS BE ZERO, ROCK SHOULD ALWAYS BE 1 INSIDE


func generate(var p_seed : int):
	generate_world(_get_noise(p_seed))


func cut(var p_position : Vector2, var p_radius : float, var smooth : float = 1.0):
	var cell_position = Vector2(round(p_position.x / SQUARE_SIZE), round(p_position.y / SQUARE_SIZE))
	var cell_radius := ceil(p_radius / SQUARE_SIZE) + 1
	var current := p_position.round() - Vector2(cell_radius, cell_radius)
	for i in range(cell_radius * 2):
		for j in range(cell_radius * 2):
			
			var world_radius = (Vector2(current.x + j, current.y + i) * SQUARE_SIZE).distance_to(p_position)
			
			if world_radius <= p_radius:
				var value = clamp(world_radius - p_radius + smooth, 0.0, 1.0)
				set_vertex(current.y + i, current.x + j, value - 1.0, true)
	
	update_chunks()


func _get_noise(noise_seed: int) -> Array:  #priv mark?
	var noise := OpenSimplexNoise.new()
	noise.seed = noise_seed
	noise.octaves = 2
	noise.persistence = 0.9
	noise.period = 12.0
	var n_max := 0.0
	var n_avg := 0.0
	for i in range(height):
		for j in range(width):
			var n = abs(noise.get_noise_2d(j,i))
			n_avg += n
			if n > n_max:
				n_max = n
	n_avg /= height * width
	
	var data = []
	for i in range(v_chunks * CHUNK_SIZE + 1): #debug
		data.append([])
		for j in range(h_chunks * CHUNK_SIZE + 1):
			data[i].append(clamp(noise.get_noise_2d(j, i) / n_avg + 1.5, 0.0, 2.0) / 2.0)
	
	return data


func generate_world(terrain_data: Array) -> void:
	
	for i in range(chunks.size()):
		for j in range(chunks[i].size()):
			chunks[i][j].queue_free()
	
	altered_chunks.clear()
	
	v_chunks = ceil(float(height) / float(CHUNK_SIZE))
	h_chunks = ceil(float(width) / float(CHUNK_SIZE))
	
	$BoundLine.points[1].x = width
	$BoundLine.points[2].x = width
	$BoundLine.points[2].y = height
	$BoundLine.points[3].y = height
	$BoundBody/BoundShape.polygon = $BoundLine.points
	
	chunks.resize(v_chunks)
	for i in range(v_chunks):
		chunks[i] = []
		chunks[i].resize(h_chunks)
		for j in range(h_chunks):
			chunks[i][j] = CHUNK.instance()
			chunks[i][j].set_size(CHUNK_SIZE, SQUARE_SIZE)
			chunks[i][j].position = Vector2(j, i) * CHUNK_SIZE * SQUARE_SIZE
			for k in range(CHUNK_SIZE + 1):
				for l in range(CHUNK_SIZE + 1):
					chunks[i][j].vertices[k][l] = terrain_data[i * CHUNK_SIZE + k][j * CHUNK_SIZE + l]
			$Chunks.add_child(chunks[i][j])
		
	for i in range(chunks.size()):
		for j in range(chunks[i].size()):
			chunks[i][j].initalize_mesh()


func set_vertex(row: int, col: int, value: float, add: bool = false) -> void:
	if row < 0 or col < 0 or row > height or col > width:
		return
	
	var chunk_row: int = (row - 1) / (CHUNK_SIZE)
	var chunk_col: int = (col - 1) / (CHUNK_SIZE)
	var vertex_row := (row - chunk_row * CHUNK_SIZE) % (CHUNK_SIZE + 1)
	var vertex_col := (col - chunk_col * CHUNK_SIZE) % (CHUNK_SIZE + 1)
	
	if add:
		value += chunks[chunk_row][chunk_col].vertices[vertex_row][vertex_col]
	
	value = clamp(value, 0.0, 1.0)
	
	var chunk = chunks[chunk_row][chunk_col]
	chunk.vertices[vertex_row][vertex_col] = value
	altered_chunks[chunk] = true
	
	var v_edge := vertex_row == CHUNK_SIZE
	var v_bound := chunk_row < v_chunks - 1
	var h_edge := vertex_col == CHUNK_SIZE
	var h_bound := chunk_col < h_chunks - 1
	if v_bound and v_edge:
		chunk = chunks[chunk_row + 1][chunk_col] 
		chunk.vertices[0][vertex_col] = value
		altered_chunks[chunk] = true
	if h_bound and h_edge:
		chunk = chunks[chunk_row][chunk_col + 1] 
		chunk.vertices[vertex_row][0] = value
		altered_chunks[chunk] = true
	if v_bound and v_edge and h_bound and h_edge:
		chunk = chunks[chunk_row + 1][chunk_col + 1]
		chunk.vertices[0][0] = value
		altered_chunks[chunk] = true


func update_chunks(): #unoptimized debug function
	for chunk in altered_chunks.keys():
		chunk.initalize_mesh()
	altered_chunks.clear()

