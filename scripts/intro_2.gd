extends Control

@onready var animation_player = $AnimationPlayer

func _ready():
	if not animation_player.has_animation("intro2"):
		push_error("No existe la animación 'intro2'")
		return

	animation_player.play("intro2")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
