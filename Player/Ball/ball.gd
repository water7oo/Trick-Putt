extends RigidBody3D

# --- Nodes ---
@onready var BallCollision: CollisionShape3D = $BallColllision
@onready var BallMesh: MeshInstance3D = $BallMesh
@onready var BallBounce: AudioStreamPlayer = $BallBounce
@onready var PlatformCombo: AudioStreamPlayer = $PlatformCombo
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

var combo_count: int = 0
@export var combo_pitch_step: float = .2  # how much the pitch rises each combo
@export var combo_pitch_max: float = 2.0   # max pitch so it doesn’t get too squeaky


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
	var control = start + (end - start) * .5 + Vector3.UP * height

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

func _integrate_forces(state):
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)

		if collider is StaticBody3D and collider.is_in_group("BankPlatform"):
			PlatformCombo.pitch_scale += .2
			PlatformCombo.play()
			combo_count += 1

			print("Combo:", combo_count)
			var local_normal = state.get_contact_local_normal(i)
			var world_normal = (collider.global_transform.basis * local_normal).normalized()

			# Grab platform power (custom property)
			var platform_power: float = 1.0
			if "bank_power" in collider:
				platform_power = collider.bank_power

			var blend := -1  # 0 = pure normal, 1 = pure incoming bounce
			var normal_velocity = world_normal * (maxSpeed * platform_power)
			var bounced_velocity = linear_velocity.bounce(world_normal).normalized() * (maxSpeed * platform_power)

			linear_velocity = bounced_velocity.lerp(normal_velocity, blend)
			
			print("Banked off:", collider.name, "normal:", world_normal, "power:", platform_power)
		elif !collider.is_in_group("BankPlatform"):
			reset_combo()

func reset_combo():
	combo_count = 0
	PlatformCombo.pitch_scale = .5


func _on_p_ball_area_entered(area):
	if area.name == "Bank_p1":
		print("ball banked off area")
	pass # Replace with function body.
