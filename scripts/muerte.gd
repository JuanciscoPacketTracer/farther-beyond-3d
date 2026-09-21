extends Control
@onready var animation_player = $AnimationPlayer

func _ready():
	if not animation_player.has_animation("aaa"):
		push_error("No existe la animación 'aaa'")
		return
	animation_player.play("aaa")

func _on_btnrendirse_pressed() -> void:
	animation_player.play("rendirse")
	await $AnimationPlayer.animation_finished
	Transcicion.go_to_scene("menu")


func _on_btnreintentar_pressed() -> void:
	Transcicion.go_to_scene("viajeespacial")
