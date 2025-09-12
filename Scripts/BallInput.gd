extends Node

@export var ball: NodePath
@export var camera_scene: NodePath   # assign the PlayerCamera scene root in the editor
@export var drag_power_scale := 0.05
@export var max_drag_length := 300.0
@export var respawnPoint = Marker3D

@export var pong: MultiMeshInstance3D
@export var golf_line: MultiMeshInstance3D

var camera: Camera3D
var is_dragging := false
var drag_start := Vector2.ZERO
var drag_end := Vector2.ZERO

func _ready():
	if camera_scene != NodePath():
		var cam_root = get_node(camera_scene)
		camera = cam_root.get_node_or_null("SpringArmPivot/SpringArm3D/Margin/Camera3D") as Camera3D


func _is_mouse_over_ball(mouse_pos: Vector2) -> bool:
	var ball_node = get_node(ball)
	var ball_mesh = ball_node.BallMesh
	var ball_screen_pos = camera.unproject_position(ball_mesh.global_transform.origin)
	return mouse_pos.distance_to(ball_screen_pos) <= 50


func _input(event):
	if camera == null:
		return

	# --- Mode switch ---
	if Input.is_action_just_pressed("Switch"):
		var ball_node = get_node(ball)
		ball_node.current_mode = ball_node.PlayMode.CUPPONG if ball_node.current_mode == ball_node.PlayMode.GOLF else ball_node.PlayMode.GOLF
		print("Mode switched to:", ball_node.current_mode)

	# --- Dragging logic ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			if _is_mouse_over_ball(mouse_pos):
				is_dragging = true
				drag_start = mouse_pos
				if pong: pong.visible = true
				if golf_line: golf_line.visible = true
		elif is_dragging and not event.pressed:
			is_dragging = false
			drag_end = get_viewport().get_mouse_position()
			var drag_vector = drag_start - drag_end

			var ball_node = get_node(ball)

			# Flip pong vertical drag
			if ball_node.current_mode == ball_node.PlayMode.CUPPONG:
				drag_vector.y = -drag_vector.y

			ball_node.launch_ball(drag_vector, camera)

			if pong: pong.visible = false
			if golf_line: golf_line.visible = false



func _process(delta):
	if not is_dragging or camera == null:
		return

	var current_mouse = get_viewport().get_mouse_position()
	var drag_vector = drag_start - current_mouse

	# Clamp drag vector
	var ball_node = get_node(ball)
	if drag_vector.length() > ball_node.max_drag_length:
		drag_vector = drag_vector.normalized() * ball_node.max_drag_length

	# Flip pong Y drag for preview
	if ball_node.current_mode == ball_node.PlayMode.CUPPONG:
		drag_vector.y = drag_vector.y

	# --- Pong Preview ---
	if pong and ball_node.current_mode == ball_node.PlayMode.CUPPONG:
		pong.visible = true
		ball_node.update_preview(drag_vector, camera)

	# --- Golf Preview ---
	if golf_line and ball_node.current_mode == ball_node.PlayMode.GOLF:
		golf_line.visible = true
		var mm = golf_line.multimesh
		if mm:
			var steps = 20
			mm.instance_count = steps

			var start = ball_node.BallMesh.global_transform.origin
			var ground_normal = Vector3.UP
			var ray = ball_node.get_node_or_null("GroundRayCast") as RayCast3D
			if ray and ray.is_colliding():
				start = ray.get_collision_point()
				ground_normal = ray.get_collision_normal().normalized()

			# Camera basis
			var cam_basis = camera.global_transform.basis
			var forward = -cam_basis.z.normalized()
			var right = cam_basis.x.normalized()

			# Flatten forward/right onto XZ before drag mapping
			forward.y = 0
			right.y = 0
			forward = forward.normalized()
			right = right.normalized()

			var horizontal_dir = (-forward * drag_vector.y + right * drag_vector.x).normalized()
			var power = drag_vector.length() * drag_power_scale

			# Slide along ground
			var velocity = (horizontal_dir * power).slide(ground_normal)

			var pos = start
			for i in range(steps):
				var t = Transform3D(Basis.IDENTITY, pos)
				mm.set_instance_transform(i, t)
				pos += velocity * 0.1

func _physics_process(delta):
	respawn_Player()

func respawn_Player():
	if Input.is_action_just_pressed("Respawn"):
		var ball_node = get_node(ball)
		print("Respawn")
		if ball_node and respawnPoint:
			# Teleport the ball to the Marker3D position
			ball_node.global_transform.origin = respawnPoint.global_transform.origin
			# Reset velocity so it doesn't keep moving
			ball_node.linear_velocity = Vector3.ZERO
			ball_node.angular_velocity = Vector3.ZERO
