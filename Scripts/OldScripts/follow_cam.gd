extends Node3D

@onready var gameJuice = get_node("/root/GameJuice")
@onready var enemy = get_node("/root/EnemyHealthManager")
@export var target: NodePath
@export var speed := 1.0
@export var enabled: bool
@export var spring_arm_pivot: Node3D
@export var mouse_sensitivity: float = 0.005
@export var joystick_sensitivity: float = 0.005
@onready var camera = $SpringArmPivot/SpringArm3D/Margin/Camera3D
var cam_lerp_speed: float = .005

@export var y_offset: float = 2.0
@export var x_offset: float = 2.0
@export var z_offset: float = 2.0

var is_mouse_visible: bool = true

@export var period: float = .04
@export var magnitude: float = 0.08

var y_cam_rot_dist: float = 0
var x_cam_rot_dist: float = 0

var target_node: Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	target_node = get_node(target) as Node3D

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		print("Quit Game")
		get_tree().quit()

func _physics_process(delta):
	followTarget(delta)

func _process(delta: float) -> void:
	playShake()
	if Input.is_action_just_pressed("shake_test"):
		applyShake(.04, 0.08)

func followTarget(delta):
	if not enabled or not target_node:
		return

	# Get current and target positions
	var current_pos = global_transform.origin
	var target_pos = target_node.global_transform.origin

	# Apply offsets
	#target_pos.y += y_offset
	#target_pos.x += x_offset
	#target_pos.z += z_offset

	# Smoothly interpolate position
	var new_pos = current_pos.lerp(target_pos, speed * delta)

	# Update ONLY the position, keep this node's own rotation stable
	global_transform.origin = new_pos
	# Force rotation back to neutral (so no spinning with ball)
	global_transform.basis = Basis.IDENTITY

func applyShake(period, magnitude):
	var initial_transform = self.transform
	var elapsed_time = 0.0
	
	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)

		self.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame

	self.transform = initial_transform

func playShake():
	if EnemyHealthManager.taking_damage == true:
		applyShake(.02, 0.08)
	if PlayerHealthManager.taking_damage == true:
		applyShake(.02, 0.08)
