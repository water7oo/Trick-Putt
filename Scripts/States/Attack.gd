extends LimboState

@export var debugPaddle: Node3D
@export var paddle_box: Node
@export var debugSwingLabel: Node
@onready var playerCharScene =  $"../../RootNode/COWBOYPLAYER_V4"
@onready var gameJuice = get_node("/root/GameJuice")
@onready var armature = $"../../RootNode"
@onready var swingSound: AudioStreamPlayer = $"../../SwingSound"


@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var attackPush: float = 10.0
@export var DECELERATION: float = Global.DECELERATION + 100
@export var attack_power: float = 10.0
@export var animation_request: StringName
@export var next_attack_state: StringName  # State name for chaining attacks
@export var combo_window_duration: float = 0.4  # Time frame for chaining attacks
@export var attack_cooldown_amount: float = 0.2  # Cooldown between attacks

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
var swingTimer: float = 0.0

func _enter() -> void:
	swingTimer = 0.0
	swingSound.play()
	Global.isSwing = true
	print("Current State:", agent.state_machine.get_active_state())
	debugSwingLabel.text = "PADDLE: CHOP"
	debugPaddle.visible = true
	paddle_box.visible = true
	if paddle_box:
		paddle_box.monitoring = true  
		paddle_box.monitorable = true
		paddle_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)



func _update(delta: float) -> void:
	swingTimer += delta
	
	if swingTimer >= .1:
		agent.state_machine.dispatch("to_idle")
		



#func _on_paddle_box_area_entered(area):
	#if area.name == "pBall":
		#agent.state_machine.dispatch("to_idle")

func _exit() -> void:
	paddle_box.monitoring = false
	paddle_box.monitorable = false
	swingTimer = 0.0
	debugPaddle.visible = false
	paddle_box.visible = false
	Global.isSwing = false
	debugSwingLabel.text = "PADDLE: INACTIVE"
	
	pass


func player_movement(delta: float) -> void:
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	if direction != Vector3.ZERO && Global.can_move:
		is_moving = true
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)
		Global.target_blend_amount = 0.0
		Global.current_blend_amount = lerp(Global.current_blend_amount, Global.target_blend_amount, Global.blend_lerp_speed * delta)
		animationTree.set("parameters/Ground_Blend/blend_amount", 1)

		var target_rotation = atan2(direction.x, direction.z)

		# **Calculate the angle between current velocity and new direction**
		var angle_diff = velocity.normalized().dot(direction)
		
		# If the dot product is negative (angle > 90°), apply stronger deceleration
		if angle_diff < 0:
			current_speed = move_toward(current_speed, 0, Global.momentum_deceleration * delta)

		# Blend movement instead of instantly switching direction
		velocity = velocity.lerp(direction * target_speed, Global.inertia_blend * delta)

	else:
		is_moving = false
		current_speed = 0
		velocity.x = move_toward(velocity.x, 0, Global.BASE_DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, Global.BASE_DECELERATION * delta)

	velocity.y = agent.velocity.y  

	if velocity.length() <= 0:
		agent.state_machine.dispatch("to_idle")
	elif Input.is_action_pressed("move_crouch"):
		agent.state_machine.dispatch("to_crouch")

	agent.velocity = velocity
