extends CharacterBody3D


@onready var state_machine: LimboHSM = $LimboHSM
@onready var idle_state =  $LimboHSM/IdleState
@onready var walk_state = $LimboHSM/WalkState
@onready var jump_state = $LimboHSM/JumpState 
@onready var run_state = $LimboHSM/RunStatee
@onready var shoot_state = $LimboHSM/ShootState
@onready var aim_state = $LimboHSM/AimState
@onready var reload_state = $LimboHSM/ReloadState

@onready var take_damage_state = $LimboHSM/TakeDamageState
@onready var recover_state = $LimboHSM/RecoverState


func _ready():
	initialize_state_machine()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func initialize_state_machine():
	state_machine.add_transition(state_machine.ANYSTATE, idle_state, "to_idle")
	state_machine.add_transition(state_machine.ANYSTATE, walk_state, "to_walk")
	state_machine.add_transition(state_machine.ANYSTATE, run_state, "to_run")
	state_machine.add_transition(state_machine.ANYSTATE, jump_state, "to_jump")
	state_machine.add_transition(state_machine.ANYSTATE, aim_state, "to_aim")
	state_machine.add_transition(state_machine.ANYSTATE, shoot_state, "to_shoot")
	state_machine.add_transition(state_machine.ANYSTATE, take_damage_state, "to_damaged")
	state_machine.add_transition(state_machine.ANYSTATE, reload_state, "to_reload")
	

	
	
	state_machine.add_transition(take_damage_state, recover_state, "to_recover")


	state_machine.initial_state = idle_state  
	state_machine.initialize(self)
	state_machine.set_active(true)
	
	

func _physics_process(delta: float) -> void:
	playerGravity(delta)
	
func playerCamera(delta: float) -> void:
	pass

func playerGravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta





func _on_hurt_box_area_exited(area):
	pass # Replace with function body.


func _on_attack_box_area_entered(area):
	pass # Replace with function body.



func _on_hurt_box_area_entered(area):
	if area.name == "enemyBox":
		Global.last_enemy_hit = area.get_parent()  # Set the enemy that hit the player

		# Optionally, transition to TakeDamage state
		state_machine.dispatch("to_damaged")


func _on_attack_box_area_exited(area):
	pass # Replace with function body.
