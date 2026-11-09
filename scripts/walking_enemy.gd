extends EnemyBase
class_name WalkingEnemy
@export var sprite_faces_right: bool = true
var _base_scale_x: float = 1.0
func _on_custom_ready() -> void:
	_base_scale_x = absf(visual.scale.x)
func _update_billboard(_delta: float) -> void:
	var camera := _get_camera()
	if camera == null or move_direction == Vector3.ZERO:
		return
	var screen_right := camera.global_basis.x
	screen_right.y = 0.0
	screen_right = screen_right.normalized()

	var side := move_direction.dot(screen_right)
	if absf(side) < 0.1:
		return

	var flip := (side > 0.0) != sprite_faces_right
	visual.scale.x = -_base_scale_x if flip else _base_scale_x
