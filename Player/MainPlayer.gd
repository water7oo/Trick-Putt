extends CharacterBody3D

@onready var state_machine: LimboHSM = $LimboHSM
@onready var idle_state = $LimboHSM/IdleState
@onready var walk_state = $LimboHSM/WalkState
@onready var jump_state = $LimboHSM/JumpState 
@onready var run_state = $LimboHSM/RunState
@onready var runJump_state = $LimboHSM/RunJumpState
@onready var burst_state = $LimboHSM/BurstState
@onready var crouch_state = $LimboHSM/CrouchState
@onready var groundDive_state = $LimboHSM/GroundDiveState
@onready var airDive_state = $LimboHSM/AirDiveState
@onready var slide_state = $LimboHSM/SlideState
@onready var attack_state = $LimboHSM/AttackState

@onready var attack1_state = $LimboHSM/AttackState/Attack1
@onready var attack2_state = $LimboHSM/AttackState/Attack2
@onready var attack3_state = $LimboHSM/AttackState/Attack3

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
	state_machine.add_transition(state_machine.ANYSTATE, attack_state, "to_attack")
	state_machine.add_transition(state_machine.ANYSTATE, take_damage_state, "to_damaged")
	
	
	
	state_machine.add_transition(run_state, runJump_state, "to_runJump")
	state_machine.add_transition(walk_state, burst_state, "to_burst")
	state_machine.add_transition(run_state, burst_state, "to_burst")
	
	state_machine.add_transition(idle_state, crouch_state, "to_crouch")
	state_machine.add_transition(run_state, crouch_state, "to_crouch")
	state_machine.add_transition(walk_state, crouch_state, "to_crouch")
	
	
	state_machine.add_transition(take_damage_state, recover_state, "to_recover")


	state_machine.initial_state = idle_state  
	state_machine.initialize(self)
	state_machine.set_active(true)
	
	
	
	state_machine.add_transition(attack_state, attack1_state, "to_attack1")
	state_machine.add_transition(attack1_state, attack2_state, "to_attack2")
	state_machine.add_transition(attack2_state, attack3_state, "to_attack3")
	state_machine.add_transition(attack1_state, idle_state, "to_idle")
	state_machine.add_transition(attack2_state, idle_state, "to_idle")
	state_machine.add_transition(attack3_state, idle_state, "to_idle")



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
