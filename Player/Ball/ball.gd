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
@export var smashSteepness: float = .5

var was_on_surface := false

var WALL_BOUNCE_ANGLES := [
	Vector3(0.6, 0.3, -1).normalized(),
	Vector3(-0.5, 0.4, -1).normalized(),
	Vector3(0.0, 0.5, -1).normalized(),
	Vector3(0.3, 0.2, -1).normalized()
]

@export var AIM_VECTOR_SCALE: float = 0.5
@export var BASE_VERTICAL_ARC: float = 0.3
@export var DEPTH_ARC_MULTIPLIER: float = 0.4
@export var FORWARD_ARC_REDUCTION: float = 0.5

# --- New variables for drag/launch mechanic ---
var is_dragging := false
var drag_start := Vector2.ZERO
var drag_end := Vector2.ZERO
@export var drag_power_scale := 0.05   # tweak shot power multiplier

func _ready():
	contact_monitor = true
	max_contacts_reported = 4

func _physics_process(delta: float) -> void:
	ballSpeedLabel.text = "BALL SPEED: " + str(snapped(linear_velocity.length(), 0.1))
	bounceDebug()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var contact_count = state.get_contact_count()

	if contact_count > 0:
		var collider = state.get_contact_collider_object(0)
		var surface_normal = state.get_contact_local_normal(0)
		var contact_position = state.get_contact_local_position(0)

		if not was_on_surface:
			BallBounce.play()
			spawn_surface_effect(contact_position, surface_normal)

		if collider and collider.name == "wallPaddle":
			var angle_index := randi() % WALL_BOUNCE_ANGLES.size()
			var chosen_bounce_angle = WALL_BOUNCE_ANGLES[angle_index]
			var current_speed := linear_velocity.length()
			linear_velocity = chosen_bounce_angle * current_speed

	was_on_surface = contact_count > 0

	var current_velocity := linear_velocity.length()
	if current_velocity > maxSpeed:
		linear_velocity = linear_velocity.normalized() * maxSpeed

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Cast a ray from the camera through the mouse position
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000.0

			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			var result = space_state.intersect_ray(query)

			# Only start dragging if the ray hit THIS ball
			if result and result.collider == self:
				is_dragging = true
				drag_start = mouse_pos

		elif is_dragging and not event.pressed:
			# Only release if dragging was started on the ball
			is_dragging = false
			drag_end = get_viewport().get_mouse_position()
			var drag_vector = drag_start - drag_end
			launch_ball(drag_vector)


# --- Launch function ---
func launch_ball(drag_vector: Vector2):
	var power = drag_vector.length() * drag_power_scale
	if power <= 0.1:
		return # ignore tiny clicks

	var cam_basis = camera.global_transform.basis
	var forward = -cam_basis.z.normalized()
	var right = cam_basis.x.normalized()

	var launch_dir = (forward * drag_vector.y + right * drag_vector.x).normalized()

	linear_velocity = Vector3.ZERO
	apply_impulse(launch_dir * power)

	BallHit.play()

# --- Existing helpers ---
func bounceDebug():
	if Input.is_action_just_pressed("debug_Bounce_horizontal") and camera:
		var spring_arm = camera.spring_arm_pivot
		var direction = -spring_arm.global_transform.basis.z.normalized()
		apply_impulse(direction * hforce)

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
		hit_effect.global_transform.origin = area.global_transform.origin + Vector3.UP * 0.2
		if hit_effect is GPUParticles3D or hit_effect is CPUParticles3D:
			hit_effect.emitting = true
			await get_tree().create_timer(hit_effect.lifetime + 0.2).timeout
			hit_effect.queue_free()
