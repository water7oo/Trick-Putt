extends RigidBody3D

@onready var BallCollision: CollisionShape3D = $BallColllision
@onready var BallMesh: MeshInstance3D = $BallMesh
@onready var BallBounce: AudioStreamPlayer = $BallBounce
@onready var BallHit: AudioStreamPlayer = $HitSound
@onready var ballSpeedLabel = $BallSpeed
@export var trailEmitter: Node
@export var ballDefaultTrail: Gradient
@export var ballDefaultTrailSmash: Gradient
@export var ballDefaultTrailSmash2: StandardMaterial3D

var smash_gradient := preload("res://Player/Ball/ballMaterialSMASH.tres")



@export var surface_effect_scene: PackedScene
@export var hit1: PackedScene
@export var vforce: float = 25.0
@export var hforce: float = 20.0
@export var force: float = 25.0
@export var opponentForce: float = 25.0
@export var smashForce: float = 100
@export var camera: Node3D
@export var maxSpeed: float = 30.0
@export var smashSteepness: float = .5 #higher = steeper


var aim_hold_time := Vector2.ZERO
var aim_sensitivity := 1.5
var max_aim_strength := 0.5


var was_on_surface := false

var WALL_BOUNCE_ANGLES := [
	Vector3(0.6, 0.3, -1).normalized(),    # right-top angle
	Vector3(-0.5, 0.4, -1).normalized(),   # left-top angle
	Vector3(0.0, 0.5, -1).normalized(),    # straight upward
	Vector3(0.3, 0.2, -1).normalized()     # soft-right low bounce
]

@export var AIM_VECTOR_SCALE: float = 0.5
@export var BASE_VERTICAL_ARC: float = 0.3
@export var DEPTH_ARC_MULTIPLIER: float = 0.4
@export var FORWARD_ARC_REDUCTION: float = 0.5


func _ready():
	contact_monitor = true
	max_contacts_reported = 4


func _physics_process(delta: float) -> void:
	aim_hold_time.x += (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * delta
	aim_hold_time.y += (Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")) * delta
	aim_hold_time = aim_hold_time.clamp(Vector2(-1, -1), Vector2(1, 1))

	ballSpeedLabel.text = "BALL SPEED: " + str(snapped(linear_velocity.length(), 0.1))
	
	
	
	bounceDebug()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var contact_count = state.get_contact_count()

	if contact_count > 0:
		var collider = state.get_contact_collider_object(0)
		var surface_normal = state.get_contact_local_normal(0)
		var contact_position = state.get_contact_local_position(0)
	
		# Play bounce sound and spawn effect if newly landed
		if not was_on_surface:
			BallBounce.play()
			spawn_surface_effect(contact_position, surface_normal)

		# If bouncing off wallPaddle, apply one of several pre-set bounce angles
		if collider and collider.name == "wallPaddle":
			var angle_index := randi() % WALL_BOUNCE_ANGLES.size()
			var chosen_bounce_angle = WALL_BOUNCE_ANGLES[angle_index]
			var current_speed := linear_velocity.length()
			linear_velocity = chosen_bounce_angle * current_speed

	# Remember whether we're in contact this frame
	was_on_surface = contact_count > 0

	# Clamp ball speed to maxSpeed
	var current_velocity := linear_velocity.length()
	if current_velocity > maxSpeed:
		linear_velocity = linear_velocity.normalized() * maxSpeed


# --- Debug Bounce Triggers ---
func bounceDebug():
	if Input.is_action_just_pressed("debug_Bounce_horizontal") and camera:
		var spring_arm = camera.spring_arm_pivot
		var direction = -spring_arm.global_transform.basis.z.normalized()
		apply_impulse(direction * hforce)
		
	#if Input.is_action_just_pressed("debug_Bounce_vertical"):
		#apply_impulse(Vector3(0, -1, 0) * vforce)


func spawn_surface_effect(pos: Vector3, normal: Vector3) -> void:
	if surface_effect_scene:
		var effect = surface_effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_transform.origin = pos
		var up = normal.normalized()
		var forward = up.cross(Vector3.RIGHT).normalized()
		if forward.length() < 0.1:
			forward = up.cross(Vector3.FORWARD).normalized()
		var right = forward.cross(up).normalized()

		effect.global_transform.basis = Basis(right, up, -forward)

func spawn_hit_effect_at_area(area: Node3D):
	if hit1 and area && Global.isSwing:
		var hit_effect = hit1.instantiate()
		get_parent().add_child(hit_effect)
		
		# Slight offset to keep it from clipping into paddle
		hit_effect.global_transform.origin = area.global_transform.origin + Vector3.UP * 0.2

		if hit_effect is GPUParticles3D or hit_effect is CPUParticles3D:
			hit_effect.emitting = true
			await get_tree().create_timer(hit_effect.lifetime + 0.2).timeout
			hit_effect.queue_free()



func _on_p_ball_area_entered(area):
	var applied_force := 0.0
	var is_smash := false  # Track if this is a smash hit

	if area.name == "PaddleBox":
		if Global.isSmash:
			Global.is_player_hit = true
			is_smash = true
			applied_force = smashForce
			$TrailEmitter.visible = false
			$TrailEmitterSmash.visible = true
		elif Global.isSwing:
			Global.is_player_hit = true
			applied_force = force
			$TrailEmitter.visible = true
			$TrailEmitterSmash.visible = false

	elif area.name == "wallPaddle":
		Global.is_opponent_hit = true
		applied_force = opponentForce
		$TrailEmitter.visible = true
		$TrailEmitterSmash.visible = false

	if Global.is_player_hit or Global.is_opponent_hit:
		var paddle_forward = -area.global_transform.basis.z.normalized()

		var input_right := Input.get_action_strength("move_right")
		var input_left := Input.get_action_strength("move_left")
		var input_back := Input.get_action_strength("move_back")
		var input_forward := Input.get_action_strength("move_forward")

		var horizontal_input := input_right - input_left
		var depth_input := input_back - input_forward

		var aim_input := Vector3(horizontal_input, 0, depth_input)
		var aim_vector := aim_input.clamp(Vector3(-1, 0, -1), Vector3(1, 0, 1)) * AIM_VECTOR_SCALE

		var vertical_arc := BASE_VERTICAL_ARC + (depth_input * DEPTH_ARC_MULTIPLIER) - (input_forward * FORWARD_ARC_REDUCTION)

		var impulse_direction = (paddle_forward + aim_vector + Vector3(0, vertical_arc, 0))

		# Modify for smash: add a sharp downward component
		if is_smash:
			impulse_direction.y = -abs(impulse_direction.y + smashSteepness)  # ensure it’s going downward

		var final_impulse_direction = impulse_direction.normalized()

		linear_velocity = Vector3.ZERO
		apply_impulse(final_impulse_direction * applied_force)

		BallHit.play()
		spawn_hit_effect_at_area(area)

		await get_tree().create_timer(0.1).timeout

		Global.is_player_hit = false
		Global.is_opponent_hit = false
