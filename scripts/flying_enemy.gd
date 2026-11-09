extends EnemyBase
class_name FlyingEnemy
@export_group("Flying")
@export var max_vertical_chase_slope: float = 0.3
@export var billboard_turn_speed: float = 10.0
@export var billboard_yaw_offset_degrees: float = -90.0

@export_group("Stun / Death FX")
@export var shake_angle_degrees: float = 15.0
@export var death_tilt_degrees: float = 30.0
@export var death_drop: float = 0.5
@export var death_fall_time: float = 0.4
var _facing_yaw: float = 0.0
var _shake_yaw: float = 0.0
var _shake_tween: Tween
func _on_custom_ready() -> void:
	gravity_scale = 0.0
	_facing_yaw = visual.global_rotation.y
func _get_chase_direction() -> Vector3:
	var dir := (player.global_position - global_position).normalized()
	dir.y = clampf(dir.y, -max_vertical_chase_slope, max_vertical_chase_slope)
	return dir.normalized()
func _apply_velocity(v: Vector3) -> void:
	linear_velocity = v 
func _update_billboard(delta: float) -> void:
	var camera := _get_camera()
	if camera == null:
		return
	var to_camera := camera.global_position - visual.global_position
	to_camera.y = 0.0
	if to_camera.length_squared() > 0.000001:
		var target := atan2(to_camera.x, to_camera.z) + deg_to_rad(billboard_yaw_offset_degrees)
		_facing_yaw = lerp_angle(_facing_yaw, target, delta * billboard_turn_speed)
	visual.global_rotation.y = _facing_yaw + _shake_yaw
func _on_stun_start() -> void:
	_kill_shake()
	var angle := deg_to_rad(shake_angle_degrees)
	_shake_tween = create_tween()
	for i in 4:
		_shake_tween.tween_property(self, "_shake_yaw", angle, 0.05)
		_shake_tween.tween_property(self, "_shake_yaw", -angle, 0.05)
	_shake_tween.tween_property(self, "_shake_yaw", 0.0, 0.05)

func _play_death() -> void:
	_kill_shake()
	var tilt := deg_to_rad(death_tilt_degrees) * (1.0 if randf() > 0.5 else -1.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual, "rotation:z", visual.rotation.z + tilt, death_fall_time)
	tween.tween_property(visual, "position:y", visual.position.y - death_drop, death_fall_time)
	await tween.finished
	await super._play_death()
func _kill_shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_yaw = 0.0
