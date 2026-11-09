extends EnemyBase

@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0
@export var min_walk_time: float = 1.5
@export var max_walk_time: float = 3.5
@export var sprite_faces_right: bool = true

@onready var animation_player: AnimationPlayer = $Toadli/AnimationPlayer
@onready var visual: Node3D = $Toadli

var state_timer: float = 0.0
var move_dir: Vector3 = Vector3.ZERO
var base_scale_x: float = 1.0

enum RoamState { IDLE, WALK }
var roam_state: RoamState = RoamState.IDLE

func _on_custom_ready() -> void:
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	base_scale_x = absf(visual.scale.x)
	_enter_roam_idle()

# --- MOVIMIENTO CAMINANTE ---
func _process_movement(delta: float) -> void:
	state_timer -= delta
	
	if stunned:
		_set_horizontal_velocity(Vector3.ZERO)
		return
	
	if current_state == State.CHASE:
		var dir = (player.global_position - global_position)
		dir.y = 0
		if dir.length() > 0.1:
			move_dir = dir.normalized()
			_set_horizontal_velocity(move_dir * chase_speed)
			_play("Walk")
	else:
		if state_timer <= 0.0:
			if roam_state == RoamState.IDLE:
				_enter_roam_walk()
			else:
				_enter_roam_idle()
		else:
			if roam_state == RoamState.WALK:
				_set_horizontal_velocity(move_dir * roam_speed)
			else:
				_set_horizontal_velocity(Vector3.ZERO)

func _set_horizontal_velocity(v: Vector3) -> void:
	linear_velocity = Vector3(v.x, linear_velocity.y, v.z)

func _enter_roam_idle() -> void:
	roam_state = RoamState.IDLE
	state_timer = randf_range(min_idle_time, max_idle_time)
	move_dir = Vector3.ZERO
	_play("Idle")

func _enter_roam_walk() -> void:
	roam_state = RoamState.WALK
	state_timer = randf_range(min_walk_time, max_walk_time)
	var a = randf_range(0.0, TAU)
	move_dir = Vector3(sin(a), 0.0, cos(a)).normalized()
	_play("Walk")
	_update_facing()
func _update_billboard() -> void:
	_update_facing()

func _update_facing() -> void:
	var camera = get_viewport().get_camera_3d()
	if camera == null or move_dir == Vector3.ZERO: return
	
	var screen_right = camera.global_basis.x
	screen_right.y = 0.0
	screen_right = screen_right.normalized()
	
	var side = move_dir.dot(screen_right)
	if absf(side) < 0.1: return
	
	var moving_right = side > 0.0
	var flip = moving_right != sprite_faces_right
	visual.scale.x = -base_scale_x if flip else base_scale_x

# --- EFECTOS DE STUN ---
func _on_stun_start() -> void:
	_play("Stun")

func _on_stun_end() -> void:
	if current_state == State.CHASE:
		_play("Walk")
	else:
		_play("Idle" if roam_state == RoamState.IDLE else "Walk")

func _on_take_damage_visual() -> void:
	pass

func _on_custom_death() -> void:
	_play("Death")
	await get_tree().create_timer(0.5).timeout
	super._on_custom_death()

func _play(anim_name: StringName) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)
