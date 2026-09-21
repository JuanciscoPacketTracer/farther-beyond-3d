extends Control

func _on_btncontinuar_pressed() -> void:
	for player_node in get_tree().get_nodes_in_group("player"):
		if player_node.has_method("exit_pause_menu"):
			player_node.exit_pause_menu()
	visible = false
	get_tree().paused = false

func _on_btnconfiguracion_pressed() -> void:
	pass

func _on_btnsalir_pressed() -> void:
	Transcicion.go_to_scene("menu")
