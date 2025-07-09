extends Node2D

signal hud_message(text)
signal mission_complete()

var human_scene = preload("res://human.tscn")
var rng = RandomNumberGenerator.new()
var total_human_count = 0
var human_count = 0
var mission_active = false
var mission_time = 0.0
var mission_completion_delay = 0.0
var hud_message_time = 0.0


func start_game(var p_seed : int):
	
	end_game()
	
	rng.seed = p_seed
	$Terrain.generate(rng.randi())
	
	var start_position = Vector2(rng.randf_range(4, $Terrain.width - 4), rng.randf_range(4, $Terrain.height - 4))
	$Terrain.cut(start_position, 4.0)
	$Player.transform = Transform2D(0.0, start_position)
	$Player.velocity = Vector2()
	
	total_human_count = rng.randi_range(10, 15)
	human_count = total_human_count
	for i in range(human_count):
		var human_position = Vector2(rng.randf_range(4, $Terrain.width - 4), rng.randf_range(4, $Terrain.height - 4))
		var human = human_scene.instance()
		human.connect("beamed_up", self, "on_human_beamed_up")
		$Terrain.cut(human_position, 3.0)
		human.transform.origin = human_position
		$Entities.add_child(human)
	
	mission_active = true
	mission_time = 0.0
	mission_completion_delay = 2.0
	
	emit_signal("hud_message", "Save the humans. Push against the rock to dig.")
	hud_message_time = 10.0
	
	$StartSound.play()


func end_game():
	
	for entity in $Entities.get_children():
		$Entities.remove_child(entity)
		entity.queue_free()
	
	mission_active = false


func _ready():
	get_tree().get_root().connect("size_changed", self, "on_viewport_size_changed")


func _physics_process(delta):
	
	if mission_active:
		mission_time += delta
	else:
		if mission_completion_delay > 0.0:
			mission_completion_delay -= delta
			if mission_completion_delay <= 0.0:
				emit_signal("mission_complete")
				mission_completion_delay = 0.0
	
	if hud_message_time > 0.0:
		hud_message_time -= delta
		if hud_message_time <= 0.0:
			emit_signal("hud_message", "")
			hud_message_time = 0.0
	
	var camera_position = $Player.transform.origin
	var viewport_size = get_viewport().size
	var margin = Vector2(8.0 * viewport_size.x / viewport_size.y, 8.0)
	camera_position.x = clamp(camera_position.x, margin.x, $Terrain.width - margin.x)
	camera_position.y = clamp(camera_position.y, margin.y, $Terrain.height - margin.y)
	
	$Camera.transform.origin = camera_position


func on_viewport_size_changed():
	# Adjust camera zoom to fit 24 world units in view vertically
	var size = get_viewport().size
	$Camera.zoom.y = 24.0 / size.y
	$Camera.zoom.x = $Camera.zoom.y


func on_human_beamed_up():
	
	human_count = max(human_count - 1, 0)
	
	if human_count <= 0:
		
		mission_active = false
		$CompletionSound.play()
		
		emit_signal("hud_message", "Mission complete")
		hud_message_time = 0.0
		
	else:
		
		if mission_time > 5.0:
			emit_signal("hud_message", str(total_human_count - human_count) + "/" + str(total_human_count) + " humans saved")
			hud_message_time = 2.0

