extends CharacterBody3D

var direction: Vector3
var speed: float = 50.0

func set_direction(dir: Vector3) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()
