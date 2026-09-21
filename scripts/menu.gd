extends Control
func _ready() -> void:
	Musicaintro.playing = false

func _on_btniniciar_pressed() -> void:
	Transcicion.go_to_scene("shipscene")




func _on_btnsalir_pressed() -> void:
	get_tree().quit()
