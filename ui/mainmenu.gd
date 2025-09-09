extends Node3D

@export var playButton: Button
@export var worldSelector: Node3D
@export var backMainMenu: Button
@export var worldSelectScroll: AudioStreamPlayer
@export var worldTransition: AudioStreamPlayer
@export var worldReader: Area3D
@export var titleScreen: Sprite2D
@export var rWorldSelectBtn: Button
@export var lWorldSelectBtn: Button
@export var worldsOverlay: Node2D

@export var start_pos: Marker3D
@export var end_pos: Marker3D


#Stores the string of the selected world, attach this string to some sort of 
# scene or chunk that willl transition in based on this value
var WorldSelectName = 0
var rotation_speed = 0.3
var world_move_speed = 0.4
var displayWorldSelect = false

# Keep track of the current rotation step
var rotation_index := 0


func _ready() -> void:
	# Start worldSelector at the right spot
	worldSelector.position = start_pos.position

func _process(delta: float)-> void:
	
	rotateWorldsInput()
	selectWorld()
	
func selectWorld():
	
	if Input.is_action_just_pressed("Select"):
		print("selected world")
	pass
func _on_play_pressed() -> void:
	print("pressed button")
	displayWorldSelect = true
	titleScreen.visible = false
	playButton.visible = false
	backMainMenu.visible = true
	worldsOverlay.visible = true
	
	# Show selector buttons
	rWorldSelectBtn.visible = true
	lWorldSelectBtn.visible = true
	
	# Tween the world selector into position
	worldTransition.play()
	var tween := create_tween()
	tween.tween_property(
		worldSelector, 
		"position", 
		end_pos.position,  
		world_move_speed
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func rotateWorldsInput():
	
	if Input.is_action_just_pressed("move_left"):
		rotation_index += 1
		_tween_rotation()
	elif Input.is_action_just_pressed("move_right"):
		rotation_index -= 1
		_tween_rotation()
	

func _on_r_world_select_pressed() -> void:
	rotation_index += 1
	_tween_rotation()


func _on_l_world_select_pressed() -> void:
	rotation_index -= 1
	_tween_rotation()


func _on_back_main_menu_pressed() -> void:
	# Hide selector buttons
	titleScreen.visible = true
	rWorldSelectBtn.visible = false
	lWorldSelectBtn.visible = false
	playButton.visible = true
	backMainMenu.visible = false
	worldsOverlay.visible = false

	worldTransition.play()
	# Tween the world selector back
	var tween := create_tween()
	tween.tween_property(
		worldSelector, 
		"position", 
		start_pos.position,  
		world_move_speed
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Reset rotation
	rotation_index = 0
	_tween_rotation()


func _tween_rotation() -> void:
	worldSelectScroll.play()
	# Tween worldSelector rotation in 90° increments
	var tween := create_tween()
	tween.tween_property(
		worldSelector,
		"rotation_degrees:y",  # rotate around Y axis
		rotation_index * 45.0,
		rotation_speed
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_world_reader_area_entered(area):
	if displayWorldSelect == true:
		if area.name == "world1":
			print("world1 selected")
			WorldSelectName = area.name
		elif area.name == "world2":
			print("world2 selected")
		elif area.name == "world3":
			print("world3 selected")
		elif area.name == "world4":
			print("world4 selected")
		elif area.name == "world5":
			print("world5 selected")
		elif area.name == "world6":
			print("world6 selected")
		elif area.name == "world7":
			print("world7 selected")
		elif area.name == "world8":
			print("world8 selected")

	pass # Replace with function body.
