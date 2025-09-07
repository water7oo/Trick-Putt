extends Node3D

func _physics_process(delta: float) -> void:
	await get_tree().create_timer(1.0).timeout
	#print("effect over")
	queue_free()
