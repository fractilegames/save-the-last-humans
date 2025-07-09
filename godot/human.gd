extends KinematicBody2D

signal beamed_up

const GRAVITY = 10.0
const MAX_SPEED = 20.0

var velocity = Vector2()
var movement = 1.0
var movement_time = 0.0
var beaming_up = false
var animation_phase = randf()


func _physics_process(delta: float) -> void:
	
	# Basic movement logic
	if not beaming_up:
		movement_time += delta
		if movement_time > 2.0:
			if movement > 0.0:
				movement = -1.0
			else:
				movement = 1.0
			movement_time = 0.0
		velocity.x = movement * 2.0
	
	# Handle beaming up to nearby player ship
	beam_up(delta)
	
	# Apply gravity or ground friction
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity = lerp(velocity, Vector2(), delta * 5.0)
	velocity = lerp(velocity, Vector2(), delta * 0.7)
	
	# Move
	velocity = move_and_slide(velocity, Vector2.UP, true, 4, 0.7)

	# Limit maximum speed
	var speed = velocity.length()
	if speed > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED


func beam_up(var delta : float):
	
	beaming_up = false
	var player = get_node("../../Player")
	if player:
		var delta_to_player = player.transform.origin - transform.origin
		var distance_to_player = delta_to_player.length()
		if distance_to_player < 4.0:
			
			beaming_up = true
			
			# Adjust velocity to fly towards player ship
			var target_velocity = delta_to_player * 5.0 / distance_to_player
			velocity = lerp(velocity, target_velocity, delta * 5.0)
			
			player.tractor_beam_active()
			
			# Detect sucessful beam-up
			if distance_to_player < 0.8:
				emit_signal("beamed_up")
				player.beam_up_human(self)
				queue_free()

