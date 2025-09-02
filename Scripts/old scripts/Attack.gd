extends LimboState

@export var projectile_scene: PackedScene
@export var muzzle: Marker3D   
@export var max_ammo: int = 99
@export var attack_cooldown_amount: float = 0.2

var ammo: int
var is_attacking: bool = false
var attack_cooldown: float = 0.0

func _ready() -> void:
	ammo = max_ammo

func _enter() -> void:
	_start_attack()

func _update(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if is_attacking:
		if attack_cooldown <= 0.0:
			_exit_attack_state()

	agent.move_and_slide()

func _start_attack() -> void:
	if ammo <= 0:
		print("Out of ammo!")
		
		if Input.is_action_just_pressed("reload"):
			agent.state_machine.dispatch("to_reload")
		return

	is_attacking = true
	attack_cooldown = attack_cooldown_amount

	var projectile = projectile_scene.instantiate()

	projectile.global_transform = muzzle.global_transform
	get_tree().current_scene.add_child(projectile)

	# Pass forward direction if projectile supports it
	if projectile.has_method("set_direction"):
		projectile.set_direction(-muzzle.global_transform.basis.z)

	ammo -= 1
	print("Ammo left: %s" % ammo)

func _exit_attack_state() -> void:
	is_attacking = false
	attack_cooldown = 0.0
	agent.state_machine.dispatch("to_idle")
