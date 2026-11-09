extends EnemyBase

@export var min_chillido_interval: float = 4.0
@export var max_chillido_interval: float = 8.0
@export var roam_pause_min: float = 2.0
@export var roam_pause_max: float = 4.0
@export var roam_time_min: float = 2.0
@export var roam_time_max: float = 5.0

@onready var bat_model: Node3D = $batling
@onready var harmparticles: GPUParticles3D = $harmparticles
@onready var aturdido: AudioStreamPlayer3D = $Aturdido
@onready var ataque: AudioStreamPlayer3D = $Ataque
@onready var chillido: AudioStreamPlayer3D = $chillido
var tiempo_para_chillido: float = 0.0
var roam_substate: String = "moving"
var roam_direction: Vector3 = Vector3.ZERO
var roam_timer: float = 0.0
var roam_wait_timer: float = 0.0
func _on_custom_ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	tiempo_para_chillido = randf_range(min_chillido_interval, max_chillido_interval)
	_set_new_roam_direction()
func _process(delta: float) -> void:
	if is_dead: return
	_update_billboard()
	tiempo_para_chillido -= delta
	if tiempo_para_chillido <= 0:
		if not chillido.playing:
			chillido.play()
		tiempo_para_chillido = randf_range(min_chillido_interval, max_chillido_interval)
func _process_movement(delta: float) -> void:
	if stunned: return
	if current_state == State.CHASE:
		_process_chasing()
	else:
		_process_roaming(delta)
func _process_chasing() -> void:
	var d = (player.global_position - global_position).normalized()
	d.y = clamp(d.y, -0.3, 0.3)
	d = d.normalized()
	linear_velocity = d * chase_speed
func _process_roaming(delta: float) -> void:
	if roam_substate == "moving":
		roam_timer -= delta
		linear_velocity.x = roam_direction.x * roam_speed
		linear_velocity.z = roam_direction.z * roam_speed
		if roam_timer <= 0:
			roam_substate = "waiting"
			roam_wait_timer = randf_range(roam_pause_min, roam_pause_max)
			linear_velocity.x = 0
			linear_velocity.z = 0
	else:
		roam_wait_timer -= delta
		linear_velocity.x = 0
		linear_velocity.z = 0
		if roam_wait_timer <= 0:
			_set_new_roam_direction()

func _set_new_roam_direction() -> void:
	var a = randf_range(0, TAU)
	roam_direction = Vector3(sin(a), 0, cos(a)).normalized()
	roam_timer = randf_range(roam_time_min, roam_time_max)
	roam_substate = "moving"

func _update_billboard() -> void:
	if not is_instance_valid(get_viewport().get_camera_3d()): return
	var camera = get_viewport().get_camera_3d()
	var direction = camera.global_position - bat_model.global_position
	direction.y = 0
	if direction.length() > 0.001:
		var target = atan2(direction.x, direction.z) - PI / 2
		var dt = get_physics_process_delta_time() 
		bat_model.global_rotation.y = lerp_angle(bat_model.global_rotation.y, target, dt * 10.0)
func _on_stun_start() -> void:
	if not aturdido.playing:
		aturdido.play()
	harmparticles.restart()
	harmparticles.emitting = true
	_shake_model()

func _on_stun_end() -> void:
	harmparticles.emitting = false

func _on_attack_sound() -> void:
	if not ataque.playing:
		ataque.play()

func _shake_model() -> void:
	var orig_rot = bat_model.rotation_degrees
	var shake = 15.0
	for i in range(4):
		bat_model.rotation_degrees.y = orig_rot.y + shake
		await get_tree().create_timer(0.05).timeout
		bat_model.rotation_degrees.y = orig_rot.y - shake
		await get_tree().create_timer(0.05).timeout
	shake = 0.6
	bat_model.rotation_degrees = orig_rot

func _on_take_damage_visual() -> void:
	harmparticles.emitting = true

func _on_custom_death() -> void:
	var tilt = 30 if randf() > 0.5 else -30
	var sr = bat_model.rotation_degrees
	var er = sr + Vector3(0, 0, tilt)
	var sy = bat_model.position.y
	var ey = sy - 0.5
	var t: float = 0.0
	var duration: float = 0.4
	while t < duration:
		var k = t / duration
		bat_model.rotation_degrees = sr.lerp(er, k)
		bat_model.position.y = lerp(sy, ey, k)
		t += get_physics_process_delta_time()
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	super._on_custom_death()
