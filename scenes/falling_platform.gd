extends Area3D
@export var animation_player: AnimationPlayer
@export var animation_name: StringName = &"movimiento"
@export var delay: float = 0.0
## Group the player belongs to.
@export var player_group: StringName = &"player"

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if triggered:
		return
	if not body.is_in_group(player_group):
		return

	triggered = true

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	else:
		push_warning("FallingPlatform: AnimationPlayer or animation '%s' not found." % animation_name)
