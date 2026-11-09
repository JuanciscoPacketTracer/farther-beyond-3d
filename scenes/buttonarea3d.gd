extends Area3D
@onready var animation_player_door: AnimationPlayer = $"../../ship/door/AnimationPlayerDoor"
var is_open := false
var is_busy := false
func player_interact() -> void:
	if is_busy:
		return
	is_busy = true
	if is_open:
		animation_player_door.play("doorclose")
	else:
		animation_player_door.play("dooropen")
	await animation_player_door.animation_finished
	is_open = not is_open
	is_busy = false
