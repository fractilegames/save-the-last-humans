extends Control

var message_time = 0.0


func _ready() -> void:
	randomize()
	
	get_tree().get_root().connect("size_changed", self, "on_viewport_size_changed")
	$"%SeedTextEdit".connect("text_changed", self, "on_seed_text_changed")
	$"%StartButton".connect("pressed", self, "on_start_pressed")
	$"%ContinueButton".connect("button_down", self, "on_continue_pressed")
	$"%ExitButton".connect("pressed", self, "on_exit_pressed")
	$"%FullScreenCheckBox".connect("toggled", self, "on_full_screen_check_box_toggled")
	
	$"%SeedTextEdit".connect("focus_entered", self, "on_button_focus_entered")
	$"%StartButton".connect("focus_entered", self, "on_button_focus_entered")
	$"%ContinueButton".connect("focus_entered", self, "on_button_focus_entered")
	$"%ExitButton".connect("focus_entered", self, "on_button_focus_entered")
	$"%FullScreenCheckBox".connect("focus_entered", self, "on_button_focus_entered")
	
	$"%World".connect("hud_message", self, "on_world_hud_message")
	$"%World".connect("mission_complete", self, "on_mission_complete")
	$"%World".start_game(get_seed())
	$"%World".mission_active = false
	$UI/MessageLabel.text = ""
	
	if OS.has_feature("HTML5"):
		$"%ExitButton".visible = false
	
	# Scale things for initial viewport size
	on_viewport_size_changed()
	$"%World".on_viewport_size_changed()
	
	# Show menu
	$"%Menu".visible = false
	toggle_menu()


func _input(event):
	if event.is_pressed():
		if event.is_action("menu"):
			if not $"%Menu".visible or $"%World".mission_active:
				toggle_menu()
		elif event.is_action("screenshot"):
			ScreenshotQueue.snap(get_viewport())
		elif event.is_action("fullscreen_toggle"):
			toggle_full_screen()


func _process(delta):
	
	var minutes = int($"%World".mission_time / 60.0)
	var seconds = int($"%World".mission_time) % 60
	var fraction = int($"%World".mission_time * 100.0) % 100
	$UI/TimeLabel.text = "%d:%02d.%02d" % [minutes, seconds, fraction]


func on_viewport_size_changed():
	var size = get_viewport().size
	$Viewport.size = size


func on_seed_text_changed(_p_text : String):
	$"%StartButton".disabled = $"%SeedTextEdit".text.empty()


func on_start_pressed():
	$MenuSelectSound.play()
	$"%World".start_game(get_seed())
	toggle_menu()


func on_continue_pressed():
	$MenuSelectSound.play()
	toggle_menu()


func on_exit_pressed():
	$MenuSelectSound.play()
	get_tree().quit()


func on_full_screen_check_box_toggled(var _pressed : bool):
	toggle_full_screen()


func on_button_focus_entered():
	$MenuMoveSound.play()


func get_seed() -> int:
	return $"%SeedTextEdit".text.hash()
	

func toggle_menu():
	
	var mission_active = $"%World".mission_active
	
	if $"%Menu".visible:
		get_tree().paused = false
		$UI/MessageLabel.visible = true
		$"%Menu".visible = false
	else:
		get_tree().paused = true
		$UI/MessageLabel.visible = not mission_active
		$"%ContinueButton".disabled = not mission_active
		$"%Menu".visible = true
		if mission_active:
			$"%ContinueButton".grab_focus()
		else:
			$"%StartButton".grab_focus()


func on_world_hud_message(var p_text : String):
	
	if not p_text.empty():
		$MenuSelectSound.play()
	
	$UI/MessageLabel.text = p_text


func on_mission_complete():
	if not $"%Menu".visible:
		toggle_menu()


func toggle_full_screen():
	
	OS.window_fullscreen = not OS.window_fullscreen
	
	$"%FullScreenCheckBox".set_block_signals(true) 
	$"%FullScreenCheckBox".pressed = OS.window_fullscreen
	$"%FullScreenCheckBox".set_block_signals(false) 
