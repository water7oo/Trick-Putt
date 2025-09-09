extends Node3D

@export var world_nodes: Array[Node3D]   # Drag your world balls into this array
@export var float_amplitude: float = .003 # how high they float
@export var float_speed: float = 3     # how fast they bob

var time := 0.0


func _process(delta: float) -> void:
	time += delta * float_speed

	for i in range(world_nodes.size()):
		var world = world_nodes[i]
		if world:
			# offset each one slightly so they’re out of sync
			var offset = float(i) * 1  
			var y = sin(time + offset) * float_amplitude
			var base_pos = world.position
			world.position.y = base_pos.y + y
