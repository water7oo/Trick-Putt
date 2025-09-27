extends Node3D

@export var fade_overlay: ColorRect 
@export var playerBall: RigidBody3D
@export var holeSuctionArea: Area3D
@export var GoalArea: Area3D
@export var GoalSound1: AudioStreamPlayer
@export var GoalSound2: AudioStreamPlayer
@export var ApplauseSound: AudioStreamPlayer
@export var suctionEpicenter = Node3D

@export var completionMenu = Node2D
var isCompleteLevel = false
var ball_in_suction := false

func _ready():
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.5)
	completionMenu.visible = false


func _physics_process(delta: float) -> void:
	if ball_in_suction and playerBall and holeSuctionArea:
		var suction_center = suctionEpicenter.global_transform.origin
		var ball_pos = playerBall.global_transform.origin
		
		var dir = (suction_center - ball_pos).normalized()
		var distance = suction_center.distance_to(ball_pos)
		

		
		var strength = clamp(30.0 / max(distance, 1), 5.0, 15.0)

		playerBall.apply_central_force(dir * strength)
	
	resetLevel()


func fade_to_scene(scene_path: String) -> void:
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5) # fade out
	tween.finished.connect(func ():
		get_tree().change_scene_to_file(scene_path)
	)

func resetLevel():
	if Input.is_action_pressed("reloadLevel") && isCompleteLevel == true:
		get_tree().reload_current_scene()
		print("level reload")
		
		
# --- GOAL ---
func _on_goal_area_entered(area: Area3D) -> void:
	if area.name == "pBall":
		GoalSound1.play()
		GoalSound2.play()
		ApplauseSound.play()
		isCompleteLevel = true
		completionMenu.visible = true
		

		
		
		
	


func _on_hole_suction_area_entered(area: Area3D) -> void:
	if area.name == "pBall":
		ball_in_suction = true
		print("suction")

func _on_hole_suction_area_exited(area: Area3D) -> void:
	if area.name == "pBall":
		ball_in_suction = false
		print("no more suction")




func _on_levels_pressed():
	get_tree().change_scene_to_file("res://ui/World1Levels.tscn")
	pass # Replace with function body.


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://ui/MAINMENU.tscn")
	pass # Replace with function body.
