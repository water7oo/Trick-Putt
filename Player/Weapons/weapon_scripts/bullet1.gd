extends CharacterBody3D

@export var speed: float = 40.0
var direction: Vector3 = Vector3.FORWARD

func set_direction(dir: Vector3):
	direction = dir.normalized()

func _physics_process(delta: float):
	velocity = direction * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		queue_free() # Destroy on impact
