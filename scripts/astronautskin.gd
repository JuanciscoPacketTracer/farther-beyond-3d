class_name AstronautSkin
extends Node3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

func _ready():
	if state_machine == null:
		push_error("❌ No se encontró parameters/playback. Revisa que AnimationTree → Parameters tenga 'playback'")
		return
	animation_tree.active = true

func idle():
	if state_machine:
		state_machine.travel("Idle")

func move():
	if state_machine:
		state_machine.travel("Walking_A")

func run():
	if state_machine:
		state_machine.travel("Running_A")

func jump():
	if state_machine:
		state_machine.travel("Jump_Start")

func fall():
	if state_machine:
		state_machine.travel("Jump_Idle")  # Caída con "Jump_Idle"

func land():
	if state_machine:
		state_machine.travel("Jump_Land")

func hit():
	if state_machine:
		state_machine.travel("Hit_A")

func die():
	if state_machine:
		state_machine.travel("Death_A")

func edge_grab():
	if state_machine:
		state_machine.travel("EdgeGrab")
