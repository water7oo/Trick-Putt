extends Node3D

@export var fade_overlay: ColorRect 

@export var playerBall: RigidBody3D

@export var holeSuctionArea: Area3D
@export var GoalArea: Area3D

@export var GoalSound1: AudioStreamPlayer
@export var GoalSound2: AudioStreamPlayer

func _ready():
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


func _on_goal_area_entered(area):
	
	if area.name == "pBall":
		GoalSound1.play()
		GoalSound2.play()
		



func _on_hole_suction_area_entered(area):
	pass # Replace with function body.


func _on_hole_suction_area_exited(area):
	pass # Replace with function body.
