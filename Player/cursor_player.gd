extends CanvasLayer


@onready var follow = $Cursor
func _ready():
	pass

	
	
func _process(delta: float) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	follow.global_position = get_viewport().get_mouse_position()
	
