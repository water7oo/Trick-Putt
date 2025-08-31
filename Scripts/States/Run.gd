extends LimboState

@export var animation_player : AnimationPlayer
@export var animation : StringName
@onready var armature = $"../../RootNode"

@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree =  playerCharScene.find_child("AnimationTree", true)

var sprinting = Input.is_action_pressed("move_sprint")
var is_in_air: bool = false
var is_moving: bool = false
var can_sprint: bool = true
var is_sprinting: bool = false
var current_speed: float = 0.0
var sprint_timer: float = 0.0
var velocity = Vector3.ZERO

@export var runMultiplier: float = 1.5
@export var runAdditive: float = 7
@export var MAX_SPEED: float = Global.MAX_SPEED + runAdditive
@export var BASE_SPEED: float = Global.BASE_SPEED + runAdditive
var target_speed: float = MAX_SPEED

@onready var Stamina_bar = $"UI Cooldowns"

@export var ACCELERATION: float = 1
@export var DECELERATION: float = Global.DECELERATION - 5
@export var BASE_ACCELERATION: float = 1
@export var BASE_DECELERATION: float = Global.DECELERATION - 5

@export var BASE_DASH_ACCELERATION: float = Global.ACCELERATION - 2
@export var BASE_DASH_DECELERATION: float = Global.DECELERATION - 5

@export var DASH_ACCELERATION: float = Global.ACCELERATION - 2
@export var DASH_DECELERATION: float = Global.DECELERATION - 5
var DASH_MAX_SPEED: float = Global.MAX_SPEED + 5  # Slightly above MAX_SPEED for extra burst

@export var momentum_deceleration: float = 0.6  # Lowered for smoother momentum control
@export var momentum_acceleration: float = 1.2  # Allows faster adaptation to direction changes
@export var speed_threshold: float = BASE_SPEED - 2

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	pass
	
func _update(delta: float) -> void:
	player_run(delta)
	initialize_runJump(delta)
	initialize_attack(delta)
	initialize_crouch(delta)
	#print(velocity.length())
	agent.move_and_slide()

# Smooth run (Mario-esque momentum)
func player_run(delta: float) -> void:
	if !Global.can_move:
		return  # Prevents running input if disabled
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)
	var velocity = agent.velocity
	
	
	if direction != Vector3.ZERO && can_sprint && Global.can_move && agent.is_on_floor():
		sprint_timer += delta
		is_sprinting = true
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)
		
		# Set animation blend to run
		animationTree.set("parameters/Ground_Blend2/blend_amount", 0)
		
		target_speed = MAX_SPEED
		ACCELERATION = DASH_ACCELERATION
		DECELERATION = DASH_DECELERATION
		
		# Calculate angle between velocity and new direction
		var angle_diff = velocity.normalized().dot(direction)

		# If angle is sharp (negative dot product) and player is at max speed, slow down first
		if angle_diff < 0 && current_speed >= MAX_SPEED:
			#print("SKUUUUURRRT")
			current_speed = move_toward(current_speed, BASE_SPEED, Global.run_momentum_deceleration * delta)
			velocity = velocity.lerp(direction * current_speed, Global.run_inertia_blend * delta)
		
		# Smoothly transition speed towards target speed
		current_speed = move_toward(current_speed, target_speed, Global.run_momentum_acceleration * delta)

		# Apply inertia-based movement blending
		velocity = velocity.lerp(direction * current_speed, Global.inertia_blend * delta)
		
	else:
		is_sprinting = false
		target_speed = BASE_SPEED
		ACCELERATION = BASE_ACCELERATION
		DECELERATION = BASE_DECELERATION

		# Smooth deceleration when not sprinting
		current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)

		# Apply deceleration
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

		# Always reset blend amount when stopping
		animationTree.set("parameters/Ground_Blend2/blend_amount", -1)

		# Sliding effect when no input
		if direction == Vector3.ZERO:
			velocity.x = move_toward(velocity.x, 0, momentum_deceleration * delta)
			velocity.z = move_toward(velocity.z, 0, momentum_deceleration * delta)
			
			agent.state_machine.dispatch("to_idle")

	# Ensure transition to idle when completely stopped
	if velocity.length() <= 0:
		animationTree.set("parameters/Ground_Blend2/blend_amount", -1) # Ensure idle animation is set
		agent.state_machine.dispatch("to_idle")
	
	elif Input.is_action_pressed("move_crouch"):
		animationTree.set("parameters/Ground_Blend2/blend_amount", -1)
		animationTree.set("parameters/Ground_Blend/blend_amount", 0)
		agent.state_machine.dispatch("to_crouch")



	elif Input.is_action_just_released("move_sprint") && direction != Vector3.ZERO:
		animationTree.set("parameters/Ground_Blend2/blend_amount", -1)
		agent.state_machine.dispatch("to_walk")

	agent.velocity = velocity


func initialize_runJump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		animationTree.set("parameters/Ground_Blend2/blend_amount", -1)
		agent.state_machine.dispatch("to_runJump")
	pass

func initialize_crouch(delta: float) -> void:
	if Input.is_action_pressed("move_crouch"):
		animationTree.set("parameters/Ground_Blend/blend_amount", 0)
		agent.state_machine.dispatch("to_crouch")

func initialize_attack(delta: float) -> void:
	
	#pressing attack unsheathes katana and player is in attackmode
	if Input.is_action_just_pressed("attack_light_1"):
		agent.state_machine.dispatch("to_attack")
