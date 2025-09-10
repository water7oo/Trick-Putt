extends CanvasLayer

@export var fade_overlay: ColorRect


func fade_to_scene(scene_path: String) -> void:
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5) # fade out
	tween.finished.connect(func ():
		get_tree().change_scene_to_file(scene_path)
	)
