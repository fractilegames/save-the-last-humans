extends KinematicBody2D

const GRAVITY = 10.0
const MAX_SPEED = 20.0
const PUSH_TIME = 0.4

var velocity = Vector2()
var turn_speed = 0.0
var push_time = 0.0
var thruster_power = 0.0
var tractor_power = 0.0


func tractor_beam_active():
	tractor_power = 1.0


func beam_up_human(var _p_human):
	$RescueSound.pitch_scale = rand_range(0.8, 1.2)
	$RescueSound.play()


func _process(delta):
	
	$ThrusterPolygon2D.polygon[1].y = 0.8 + thruster_power
	$ThrusterPolygon2D.color.g = 0.25 * thruster_power
	$ThrusterPolygon2D.visible = thruster_power > 0.0
	
	if thruster_power > 0.0:
		if not $ThrusterSound.playing:
			$ThrusterSound.playing = true
		$ThrusterSound.volume_db = max(-80.0, 12.0 * log(thruster_power * 0.2))
		$ThrusterSound.pitch_scale = 0.8 + 0.2 * thruster_power
	else:
		if $ThrusterSound.playing:
			$ThrusterSound.playing = false
	
	if tractor_power > 0.0:
		if not $TractorSound.playing:
			$TractorSound.playing = true
		$TractorSound.volume_db = max(-80.0, 12.0 * log(tractor_power * 0.5))
	else:
		if $TractorSound.playing:
			$TractorSound.playing = false


func _physics_process(delta: float) -> void:
	
	# Handle user control
	var control = Vector2(-Input.get_action_strength("turn_left") + Input.get_action_strength("turn_right"), Input.get_action_strength("accelerate"))
	if control.y > 0.0 and velocity.dot(transform.y) < MAX_SPEED * 0.75:
		velocity -= transform.y * 40.0 * delta
	
	# Fade thruster power up/down
	if thruster_power < control.y:
		thruster_power = min(thruster_power + 10.0 * delta, 1.0)
	else:
		thruster_power = max(thruster_power - 2.0 * delta, 0.0)
	
	# Fade out tractor beam power
	tractor_power = max(tractor_power - 4.0 * delta, 0.0)
	
	# Handle turning with accelerating turn speed
	if control.x != 0.0:
		
		if turn_speed == 0.0 or sign(control.x) != sign(turn_speed):
			turn_speed = control.x * 100.0
		else:
			turn_speed = clamp(turn_speed + control.x * 1000.0 * delta, -250, 250)
		
		rotation_degrees += turn_speed * delta
	else:
		turn_speed = 0.0
	
	# Apply gravity or ground friction
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity = lerp(velocity, Vector2(), delta * 5.0)
	
	# Apply air resistance
	velocity = lerp(velocity, Vector2(), delta * 0.7)
	
	# Move and handle contacts
	var pushing = false
	velocity = move_and_slide(velocity, Vector2.UP, true, 4, 0.7)
	for i in range(get_slide_count()):
		
		var collision = get_slide_collision(i)
		if collision.collider.collision_layer & 1: # Terrain
			if control.y >= 0.5 and collision.normal.dot(transform.y) > 0.2:
				pushing = true
		
		# Add "friction" to sliding
		if collision.normal.y < 0.7:
			var dot = collision.normal.tangent().dot(velocity)
			velocity -= collision.normal.tangent() * dot * 0.1
	
	# Limit maximum speed
	var speed = velocity.length()
	if speed > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	
	# Detect pushing against terrain
	if pushing:
		push_time += delta
		if push_time >= PUSH_TIME:
			get_node("../Terrain").cut(transform.origin + -transform.y * 1.0, 2.2)
			$DigSound.play()
			push_time = 0.0
		update()
	elif push_time > 0.0:
		push_time = 0.0
		update()


func _draw():
	
	var value = 1.0 - ease(1.0 - push_time / PUSH_TIME, 2.0)
	if value > 0.0:
		draw_circle(Vector2(0.0, -1.0), 2.2 * value, Color(0.0, 1.0, 0.0, 0.25))

