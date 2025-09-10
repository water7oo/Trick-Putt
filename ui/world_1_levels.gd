extends Node3D

@export var fade_overlay: ColorRect 
@export var levelSelector: Label
@export var level_markers: Array[Marker2D]   # Assign your 5 markers in the Inspector

var current_index: int = 0
var level_names: Array[String] = ["1", "2", "3", "4", "5"]

func _ready():
	$Preview/SubViewportContainer/TUTORIAL_CHANNEL.visible = true
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.5)

	_update_level_label()


func fade_to_scene(scene_path: String) -> void:
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5) # fade out
	tween.finished.connect(func ():
		get_tree().change_scene_to_file(scene_path)
	)


func _on_back_main_menu_pressed():
	fade_to_scene("res://ui/MAINMENU.tscn")


func levelSelectorInput():
	if Input.is_action_just_pressed("move_left"):
		current_index = (current_index - 1 + level_markers.size()) % level_markers.size()
		_update_level_label()
		print("Level " + str(current_index))

	elif Input.is_action_just_pressed("move_right"):
		current_index = (current_index + 1) % level_markers.size()
		_update_level_label()
		print("Level " + str(current_index))

	elif Input.is_action_just_pressed("Select") && current_index == 0:
		var level_name = level_names[current_index]
		print("Selected: " + level_name)
		
		fade_to_scene("res://Game/W1_000.tscn")

	if current_index == 0:
		$Preview/SubViewportContainer/TUTORIAL_CHANNEL.visible = true
	else:
		$Preview/SubViewportContainer/TUTORIAL_CHANNEL.visible = false

func _process(delta: float) -> void:
	levelSelectorInput()


func _update_level_label():
	# Move the label to the currently selected marker
	levelSelector.position = level_markers[current_index].position
