extends RigidBody3D

# --- Nodes ---
@onready var BallCollision: CollisionShape3D = $BallColllision
@onready var BallMesh: MeshInstance3D = $BallMesh
@onready var BallBounce: AudioStreamPlayer = $BallBounce
@onready var BallHit: AudioStreamPlayer = $HitSound
@export var trailEmitter: Node
@export var parabola_mesh: MultiMeshInstance3D  # 3D parabola preview (Cup Pong)
@export var golf_line_mesh: MultiMeshInstance3D # Ground visualizer for golf
@onready var ground_ray: RayCast3D = $GroundRayCast  # <--- Make sure this exists

# --- Settings ---
@export var camera: Camera3D
@export var maxSpeed: float = 30.0
@export var modeDebugLabel: Label
@export var max_drag_length := 300.0

# --- Mode ---
enum PlayMode { GOLF, CUPPONG }
var current_mode: PlayMode = PlayMode.CUPPONG

# --- Arc Settings ---
@export var BASE_VERTICAL_ARC: float = 0.3
@export var ARC_STRENGTH_MULTIPLIER: float = 0.5

# --- Banking --- # 

@export var golfPower = 0.05
@export var pongPower = 0.05
@export var bank_power_multiplier: float = 1.0

func _ready():
	contact_monitor = true
	max_contacts_reported = 4
	modeDebugLabel.text = str(current_mode)
	if camera == null:
		camera = get_viewport().get_camera_3d()

	if parabola_mesh:
		parabola_mesh.multimesh.instance_count = 0
	if golf_line_mesh:
		golf_line_mesh.multimesh.instance_count = 0

func _process(delta: float) -> void:
	pass
# --- Launch mechanics ---
func launch_ball(drag_vector: Vector2, cam: Camera3D):
	# Clamp drag length
	var drag_length = min(drag_vector.length(), max_drag_length)
	if drag_length <= 0.1:
		return
	drag_vector = drag_vector.normalized() * drag_length

	var cam_basis = cam.global_transform.basis
	var forward = -cam_basis.z.normalized()
	var right = cam_basis.x.normalized()

	if current_mode == PlayMode.GOLF:
		# --- Flatten forward/right to avoid "up/down tilt"
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()

		var launch_dir = (-forward * drag_vector.y + right * drag_vector.x).normalized()
		var power = drag_length * golfPower

		linear_velocity = Vector3.ZERO
		apply_impulse(launch_dir * power)

	elif current_mode == PlayMode.CUPPONG:
		# Pong arc launch
		var start = BallMesh.global_transform.origin
		var horizontal_dir = (forward * drag_vector.y + right * drag_vector.x).normalized()
		var power = drag_length * pongPower

		var end = start + horizontal_dir * power
		end.y = start.y  # flatten end to same ground height

		# Compute arc
		var height = max(5.0, power * 0.5)
		var g = ProjectSettings.get_setting("physics/3d/default_gravity")
		var v_y = sqrt(2 * g * height)
		var t_up = v_y / g
		var t_down = sqrt(2 * (height + (start.y - end.y)) / g)
		var t_total = t_up + t_down

		var horizontal_distance = end - start
		horizontal_distance.y = 0
		var v_horizontal = horizontal_distance / t_total

		var launch_velocity = v_horizontal + Vector3.UP * v_y

		linear_velocity = Vector3.ZERO
		apply_central_impulse(launch_velocity * mass)

	if BallHit:
		BallHit.play()


# --- Preview updater ---
func update_preview(drag_vector: Vector2, cam: Camera3D):
	if current_mode == PlayMode.GOLF and golf_line_mesh:
		_update_ground_line(drag_vector, cam, golf_line_mesh)
		modeDebugLabel.text = "Golf"
		if parabola_mesh: parabola_mesh.multimesh.instance_count = 0
	elif current_mode == PlayMode.CUPPONG and parabola_mesh:
		_update_3d_parabola(drag_vector, cam, parabola_mesh)
		modeDebugLabel.text = "Pong"
		if golf_line_mesh: golf_line_mesh.multimesh.instance_count = 0

# --- Helpers ---
func _update_3d_parabola(drag_vector: Vector2, cam: Camera3D, mesh: MultiMeshInstance3D):
	var mm = mesh.multimesh
	if mm == null: return

	var drag_length = min(drag_vector.length(), max_drag_length)
	if drag_length <= 0.1:
		mm.instance_count = 0
		return
	drag_vector = drag_vector.normalized() * drag_length

	var start = BallMesh.global_transform.origin
	var cam_basis = cam.global_transform.basis
	var forward = -cam_basis.z.normalized()
	var right = cam_basis.x.normalized()
	var horizontal_dir = (-forward * drag_vector.y + right * drag_vector.x).normalized()

	# Scale power based on drag length
	var power = drag_length * 0.05

	# Set end position farther out for longer drag
	var end = start + horizontal_dir * power
	end.y = start.y  # keep on same vertical plane

	# Height scales with drag length and power
	var min_height = 1.0
	var height = min_height + power * 1  # drag longer = taller arc

	# Control point for quadratic Bezier
	var control = start + (end - start) * 0.5 + Vector3.UP * height

	# Number of steps for parabola preview
	var steps = 20
	mm.instance_count = steps

	# Build parabola points
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		var pos = (1-t)*(1-t)*start + 2*(1-t)*t*control + t*t*end
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))


func _update_ground_line(drag_vector: Vector2, cam: Camera3D, mesh: MultiMeshInstance3D):
	var mm = mesh.multimesh
	if mm == null: return

	var drag_length = min(drag_vector.length(), max_drag_length)
	if drag_length <= 0.1:
		mm.instance_count = 0
		return
	drag_vector = drag_vector.normalized() * drag_length

	# Ground check
	var start = BallMesh.global_transform.origin
	var ground_normal = Vector3.UP
	if ground_ray and ground_ray.is_colliding():
		start = ground_ray.get_collision_point()
		ground_normal = ground_ray.get_collision_normal().normalized()

	var cam_basis = cam.global_transform.basis
	var forward = -cam_basis.z.normalized()
	var right = cam_basis.x.normalized()
	var horizontal_dir = (-forward * drag_vector.y + right * drag_vector.x).normalized()
	var power = drag_length * 0.05
	var velocity = horizontal_dir * power

	# Slide along ground plane
	velocity = velocity.slide(ground_normal)

	var steps = 20
	mm.instance_count = steps
	var pos = start
	for i in range(steps):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))
		pos += velocity * 0.1

var bounced_platforms: Array = []

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider and collider.is_in_group("BankPlatform") and collider not in bounced_platforms:
			# Convert local normal to world space
			var local_normal = state.get_contact_local_normal(i)
			var world_normal = (global_transform.basis * local_normal).normalized()


			# Get platform-specific bounce power
			var platform_power = 1.0
			if "bank_power" in collider:
				platform_power = collider.bank_power

			platform_power *= bank_power_multiplier

			# Reflect velocity along platform normal
			var incoming_velocity = linear_velocity
			var reflected_velocity = incoming_velocity - 2  * incoming_velocity.dot(world_normal) * world_normal

			# Apply impulse
			var impulse = reflected_velocity.normalized() * incoming_velocity.length() * platform_power * mass
			apply_central_impulse(impulse)

			if BallBounce:
				BallBounce.play()

			bounced_platforms.append(collider)

	# Remove platforms no longer in contact
	for platform in bounced_platforms.duplicate():
		var still_in_contact = false
		for j in range(state.get_contact_count()):
			if state.get_contact_collider_object(j) == platform:
				still_in_contact = true
				break
		if not still_in_contact:
			bounced_platforms.erase(platform)




func _on_p_ball_area_entered(area):
	if area.name == "Bank_p1":
		print("ball banked off area")
	pass # Replace with function body.
