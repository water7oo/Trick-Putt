extends CharacterBody3D

@onready var state_machine: LimboHSM = $LimboHSM
@onready var idle_state = $LimboHSM/IdleState
@onready var walk_state = $LimboHSM/WalkState
@onready var jump_state = $LimboHSM/JumpState 
@onready var run_state = $LimboHSM/RunStatee
@onready var aim_state = $LimboHSM/AimState
@onready var reload_state = $LimboHSM/ReloadState
@onready var take_damage_state = $LimboHSM/TakeDamageState
@onready var recover_state = $LimboHSM/RecoverState

@export var projectile_scene: PackedScene
@export var muzzle: Node3D
@export var max_ammo: int = 99
@export var attack_cooldown_amount: float = 0.2

var ammo: int
var attack_cooldown: float = 0.0

func _ready():
	initialize_state_machine()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ammo = max_ammo
	
func initialize_state_machine():
	state_machine.add_transition(state_machine.ANYSTATE, idle_state, "to_idle")
	state_machine.add_transition(state_machine.ANYSTATE, walk_state, "to_walk")
	state_machine.add_transition(state_machine.ANYSTATE, run_state, "to_run")
	state_machine.add_transition(state_machine.ANYSTATE, jump_state, "to_jump")
	state_machine.add_transition(state_machine.ANYSTATE, aim_state, "to_aim")
	state_machine.add_transition(state_machine.ANYSTATE, reload_state, "to_reload")
	state_machine.add_transition(state_machine.ANYSTATE, take_damage_state, "to_damaged")
	state_machine.add_transition(take_damage_state, recover_state, "to_recover")

	state_machine.initial_state = idle_state  
	state_machine.initialize(self)
	state_machine.set_active(true)

func _physics_process(delta: float) -> void:
	playerGravity(delta)

	# handle cooldown
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# shooting input
	if Input.is_action_just_pressed("Fire"): 
		shoot()

func playerCamera(delta: float) -> void:
	pass

func playerGravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta


func shoot() -> void:
	if attack_cooldown > 0.0:
		return
	if ammo <= 0:
		print("Out of ammo!")
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	# Give the projectile the same transform as the muzzle (position + rotation)
	projectile.global_transform = muzzle.global_transform

	# If projectile has a set_direction method, pass muzzle forward
	if projectile.has_method("set_direction"):
		projectile.set_direction(-muzzle.global_transform.basis.z)

	ammo -= 1
	attack_cooldown = attack_cooldown_amount
	print("Ammo left: %s" % ammo)


func _on_hurt_box_area_exited(area): pass
func _on_attack_box_area_entered(area): pass

func _on_hurt_box_area_entered(area):
	if area.name == "enemyBox":
		Global.last_enemy_hit = area.get_parent()
		state_machine.dispatch("to_damaged")

func _on_attack_box_area_exited(area): pass
