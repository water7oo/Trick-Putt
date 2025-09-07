extends LimboState

@onready var playerCharScene =  $"../../RootNode/COWBOYPLAYER_V4"
@onready var gameJuice = get_node("/root/GameJuice")
@onready var armature = $"../../RootNode"
@onready var chargeSound: AudioStreamPlayer = $"../../chargeSound"
@export var debugSwingLabel: Node
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)



@export var DECELERATION: float = Global.DECELERATION + 100
@export var JUMP_VELOCITY: float = 12.0  # Increased for better jump height
const CUSTOM_GRAVITY: float = 30.0  # Keeps the character from feeling too floaty
@export var air_timer: float = 0.0
@export var jump_timer: float = 0.0
@export var jump_counter: float = 0
@export var can_jump: bool = true
var last_ground_position = Vector3.ZERO

var current_speed: float = 0.0
var is_moving: bool = false
var target_speed: float = Global.MAX_SPEED
var velocity = Vector3.ZERO

var preserved_velocity: Vector3 = Vector3.ZERO
var chargeTimer: float = 0.0

@export var BASE_SPEED: float = Global.BASE_SPEED - 10  # Slightly slower than walking


func _enter() -> void:
	chargeTimer = 0.0
	chargeSound.play()
	Global.isSmash = true
	print("Current State:", agent.state_machine.get_active_state())
	debugSwingLabel.text = "PADDLE: CHARGING"


func _update(delta: float) -> void:
	chargeTimer += delta
	if Input.is_action_just_released("swing2") && chargeTimer >= .5:
		agent.state_machine.dispatch("to_smash")
	
	elif Input.is_action_just_released("swing2"):
		agent.state_machine.dispatch("to_swing")
		




func _exit() -> void:
	chargeTimer = 0.0
	Global.isSwing = false
	debugSwingLabel.text = "PADDLE: INACTIVE"
	chargeSound.stop()
	
	pass


func player_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	animationTree.set("parameters/Ground_Blend/blend_amount", 0)  # Crouch animation

	if direction != Vector3.ZERO:
		is_moving = true
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)

		# Smooth transition into crouch movement, blending previous momentum
		velocity = velocity.lerp(direction * BASE_SPEED, Global.inertia_blend * delta)
	else:
		is_moving = false
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

	velocity.y = agent.velocity.y  # Preserve vertical movement
	agent.velocity = velocity
