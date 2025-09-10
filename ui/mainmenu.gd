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
@export var worldSelectPos: Marker3D
@export var camerPivot: Marker3D
@export var World1Selector: Node2D
@export var world1Scene: PackedScene 

@export var fade_overlay: ColorRect 

@export var start_pos: Marker3D
@export var end_pos: Marker3D

# Stores the string of the selected world
var WorldSelectName: String = ""
var hovered_world: String = ""   # <- Track the world the reader is currently over

var rotation_speed := 0.3
var world_move_speed := 0.4
var displayWorldSelect := false

# Keep track of the current rotation step
var rotation_index := 0


func _ready() -> void:
	# Start worldSelector at the right spot
	worldSelector.position = start_pos.position
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.5)



func fade_to_scene(scene_path: String) -> void:
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5) # fade out
	tween.finished.connect(func ():
		get_tree().change_scene_to_file(scene_path)
	)
func _process(delta: float) -> void:
	if displayWorldSelect:
		rotateWorldsInput()
		selectWorld()



func selectWorld() -> void:
	if Input.is_action_just_pressed("Select") and hovered_world != "":
		WorldSelectName = hovered_world
		print("Player has selected world " + WorldSelectName)
		
		
		if WorldSelectName == "world1":
			fade_to_scene("res://ui/World1Levels.tscn") 
	
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


	hovered_world = "world1"
	print("Default highlight -> " + hovered_world)


func rotateWorldsInput() -> void:
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
	# Tween worldSelector rotation in 45° increments
	var tween := create_tween()
	tween.tween_property(
		worldSelector,
		"rotation_degrees:y",  # rotate around Y axis
		rotation_index * 45.0,
		rotation_speed
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_world_reader_area_entered(area: Area3D) -> void:
	if displayWorldSelect:
		hovered_world = area.name
		print(hovered_world + " highlighted")


func _on_world_reader_area_exited(area: Area3D) -> void:
	if hovered_world == area.name:
		hovered_world = ""  # Clear if reader leaves the world
