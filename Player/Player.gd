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
@onready var chargeSmash_state = $LimboHSM/ChargeSmashState
@onready var slide_state = $LimboHSM/SlideState
@onready var swing_state = $LimboHSM/SwingState


@onready var take_damage_state = $LimboHSM/TakeDamageState
@onready var smash_state = $LimboHSM/SmashState


func _ready():
	initialize_state_machine()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func initialize_state_machine():
	state_machine.add_transition(state_machine.ANYSTATE, idle_state, "to_idle")
	state_machine.add_transition(state_machine.ANYSTATE, walk_state, "to_walk")
	state_machine.add_transition(state_machine.ANYSTATE, run_state, "to_run")
	state_machine.add_transition(state_machine.ANYSTATE, jump_state, "to_jump")
	state_machine.add_transition(state_machine.ANYSTATE, swing_state, "to_swing")
	state_machine.add_transition(state_machine.ANYSTATE, take_damage_state, "to_damaged")
	state_machine.add_transition(state_machine.ANYSTATE, smash_state, "to_smash")
	state_machine.add_transition(state_machine.ANYSTATE, chargeSmash_state, "to_chargeSmash")
	
	state_machine.add_transition(run_state, runJump_state, "to_runJump")
	state_machine.add_transition(walk_state, burst_state, "to_burst")
	state_machine.add_transition(run_state, burst_state, "to_burst")
	
	state_machine.add_transition(idle_state, crouch_state, "to_crouch")
	state_machine.add_transition(run_state, crouch_state, "to_crouch")
	state_machine.add_transition(walk_state, crouch_state, "to_crouch")
	
	

	state_machine.initial_state = idle_state  
	state_machine.initialize(self)
	state_machine.set_active(true)
	
	
	



func _physics_process(delta: float) -> void:
	$VariableDebug.text = str(Global.is_player_hit).to_upper()
	playerGravity(delta)
	
func playerCamera(delta: float) -> void:
	pass

func playerGravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta

func _on_hurt_box_area_entered(area):
	if area.name == "enemyBox":
		Global.last_enemy_hit = area.get_parent()  # Set the enemy that hit the player

		# Optionally, transition to TakeDamage state
		state_machine.dispatch("to_damaged")
