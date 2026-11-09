extends FlyingEnemy
class_name ShooterEnemy

@export_group("Shooting")
@export var projectile_scene: PackedScene
@export var muzzle: Marker3D     
@export var shoot_sound: AudioStreamPlayer3D  
@export var projectile_speed: float = 10.0
@export var fire_interval_min: float = 2.5
@export var fire_interval_max: float = 4.0
@export var shoot_range: float = 25.0
@export var min_shoot_distance: float = 4.0  
@export var aim_spread_degrees: float = 3.0

var _fire_timer: float = 0.0

func _on_custom_ready() -> void:
	super._on_custom_ready()
	_reset_fire_timer()

func _process_movement(delta: float) -> void:
	super._process_movement(delta)
	if current_state == State.CHASE:
		_tick_shooting(delta)
func _tick_shooting(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	_reset_fire_timer()
	var dist := global_position.distance_to(player.global_position)
	if dist <= shoot_range and dist >= min_shoot_distance:
		_fire()
func _fire() -> void:
	if projectile_scene == null:
		return
	var origin := muzzle.global_position if muzzle else global_position
	var dir := (player.global_position - origin).normalized()
	var spread := tan(deg_to_rad(aim_spread_degrees))
	dir = (dir + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * spread).normalized()

	var p := projectile_scene.instantiate() as EnemyProjectile
	get_tree().current_scene.add_child(p)
	p.global_position = origin
	p.dir = dir
	p.speed = projectile_speed
	if absf(dir.dot(Vector3.UP)) < 0.99:
		p.look_at(origin + dir)
	_play_sound(shoot_sound)

func _reset_fire_timer() -> void:
	_fire_timer = randf_range(fire_interval_min, fire_interval_max)
