extends RigidBody3D
class_name EnemyBase
signal died(enemy: EnemyBase)
enum State { IDLE, CHASE }
enum RoamPhase { PAUSED, MOVING }

@export_group("Stats")
@export var max_health: int = 5
@export var damage: int = 1
@export var chase_speed: float = 6.0
@export var roam_speed: float = 3.0
@export var detection_radius: float = 20.0
@export_group("Stun")
@export var stun_time: float = 2.0
@export var rebound_force: float = 4.0
@export var knockback_friction: float = 12.0
@export var post_stun_grace: float = 0.5
@export_group("Roaming")
@export var roam_move_time_min: float = 2.0
@export var roam_move_time_max: float = 5.0
@export var roam_pause_time_min: float = 2.0
@export var roam_pause_time_max: float = 4.0

@export_group("Nodes")
@export var visual: Node3D
@export var animation_player: AnimationPlayer
@export var harm_particles: GPUParticles3D

@export_group("Animations (vacío = no se usa)")
@export var anim_idle: StringName = &""
@export var anim_move: StringName = &""

@export_group("Audio (opcional)")
@export var stun_sound: AudioStreamPlayer3D
@export var attack_sound: AudioStreamPlayer3D
@export var ambient_sound: AudioStreamPlayer3D
@export var ambient_interval_min: float = 4.0
@export var ambient_interval_max: float = 8.0

@export_group("Death")
@export var death_delay: float = 0.5
var health: int
var player: CharacterBody3D
var is_dead: bool = false
var current_state: State = State.IDLE
var move_direction: Vector3 = Vector3.ZERO
var stunned: bool:
	get: return _stun_remaining > 0.0
var _stun_remaining: float = 0.0
var _grace_remaining: float = 0.0
var _roam_phase: RoamPhase = RoamPhase.PAUSED
var _roam_timer: float = 0.0
var _ambient_timer: float = 0.0
var _is_moving: bool = false
var _camera: Camera3D

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	contact_monitor = true
	max_contacts_reported = 4
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_ambient_timer = randf_range(ambient_interval_min, ambient_interval_max)
	_enter_roam_pause()
	_on_custom_ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_ambient_sound(delta)
	_tick_stun(delta)
	if not is_instance_valid(player):
		return
	_update_state()
	if stunned:
		_apply_stun_friction(delta)
	else:
		_process_movement(delta)
	_update_billboard(delta)

func _update_state() -> void:
	var dist_sq := global_position.distance_squared_to(player.global_position)
	var radius_sq := detection_radius * detection_radius
	if current_state == State.IDLE:
		if dist_sq <= radius_sq:
			current_state = State.CHASE
	elif dist_sq > radius_sq * 2.25: # radio * 1.5
		current_state = State.IDLE
		_enter_roam_pause()

func _process_movement(delta: float) -> void:
	if current_state == State.CHASE:
		_chase()
	else:
		_roam(delta)

func _chase() -> void:
	var dir := _get_chase_direction()
	if dir != Vector3.ZERO:
		move_direction = dir
	_apply_velocity(dir * chase_speed)
	_set_moving(dir != Vector3.ZERO)

func _roam(delta: float) -> void:
	_roam_timer -= delta
	if _roam_phase == RoamPhase.MOVING:
		_apply_velocity(move_direction * roam_speed)
		if _roam_timer <= 0.0:
			_enter_roam_pause()
	else:
		_apply_velocity(Vector3.ZERO)
		if _roam_timer <= 0.0:
			_enter_roam_move()

func _enter_roam_pause() -> void:
	_roam_phase = RoamPhase.PAUSED
	_roam_timer = randf_range(roam_pause_time_min, roam_pause_time_max)
	_set_moving(false)

func _enter_roam_move() -> void:
	var angle := randf_range(0.0, TAU)
	move_direction = Vector3(sin(angle), 0.0, cos(angle))
	_roam_phase = RoamPhase.MOVING
	_roam_timer = randf_range(roam_move_time_min, roam_move_time_max)
	_set_moving(true)

func _get_chase_direction() -> Vector3:
	var dir := player.global_position - global_position
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.1 else Vector3.ZERO

func _apply_velocity(v: Vector3) -> void:
	linear_velocity = Vector3(v.x, linear_velocity.y, v.z)


func apply_stun(attacker_position: Vector3) -> void:
	if is_dead or stunned:
		return
	_stun_remaining = stun_time

	var dir := global_position - attacker_position
	dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector3.UP
	_apply_velocity(dir * rebound_force)
	_emit_harm_particles()
	_play_sound(stun_sound)
	_on_stun_start()

func _tick_stun(delta: float) -> void:
	if _stun_remaining > 0.0:
		_stun_remaining -= delta
		if _stun_remaining <= 0.0:
			_grace_remaining = post_stun_grace
			if harm_particles:
				harm_particles.emitting = false
			_on_stun_end()
	elif _grace_remaining > 0.0:
		_grace_remaining -= delta

func _apply_stun_friction(delta: float) -> void:
	_apply_velocity(linear_velocity.move_toward(Vector3.ZERO, knockback_friction * delta))

func _can_attack() -> bool:
	return not is_dead and not stunned and _grace_remaining <= 0.0


func _on_body_entered(body: Node) -> void:
	if body != player or not _can_attack():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_play_sound(attack_sound)
	apply_stun(body.global_position)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	_emit_harm_particles()
	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	_stun_remaining = 0.0
	linear_velocity = Vector3.ZERO
	for shape in find_children("*", "CollisionShape3D", true, false):
		shape.set_deferred("disabled", true)
	set_deferred("freeze", true)
	died.emit(self)
	await _play_death()
	queue_free()

func _play_death() -> void:
	await get_tree().create_timer(death_delay).timeout
func _set_moving(moving: bool) -> void:
	_is_moving = moving
	_play(anim_move if moving else anim_idle)
func _play(anim: StringName) -> void:
	if anim.is_empty() or animation_player == null:
		return
	if animation_player.current_animation != anim:
		animation_player.play(anim)
func _play_sound(sound: AudioStreamPlayer3D) -> void:
	if sound and not sound.playing:
		sound.play()
func _tick_ambient_sound(delta: float) -> void:
	if ambient_sound == null:
		return
	_ambient_timer -= delta
	if _ambient_timer <= 0.0:
		_play_sound(ambient_sound)
		_ambient_timer = randf_range(ambient_interval_min, ambient_interval_max)
func _emit_harm_particles() -> void:
	if harm_particles:
		harm_particles.restart()
		harm_particles.emitting = true
func _get_camera() -> Camera3D:
	if not is_instance_valid(_camera) or not _camera.current:
		_camera = get_viewport().get_camera_3d()
	return _camera

func _on_custom_ready() -> void: pass
func _update_billboard(_delta: float) -> void: pass
func _on_stun_start() -> void: pass
func _on_stun_end() -> void: pass
