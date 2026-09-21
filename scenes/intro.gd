extends Control

@onready var animation_player = $AnimationPlayer

func _ready():
	if not animation_player.has_animation("GODOT"):
		push_error("No existe la animación 'GODOT'")
		return

	animation_player.play("GODOT")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res:///scenes/intro_2.tscn")
