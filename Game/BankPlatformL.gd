extends StaticBody3D

@export var bank_power: float = 1.0  # how strong the bounce is
@export_enum("Up", "Forward", "Right") var bank_axis: String = "Up"
# Choose which axis should be the "bank direction" (customizable per platform)

func get_bank_direction() -> Vector3:
	var basis = global_transform.basis
	match bank_axis:
		"Up":
			return basis.y.normalized()
		"Forward":
			return -basis.z.normalized()  # -Z is forward in Godot
		"Right":
			return basis.x.normalized()
	return basis.y.normalized() # default
