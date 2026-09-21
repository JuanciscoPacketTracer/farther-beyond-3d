extends Area3D



func _on_body_entered(body: Node3D) -> void:
	if body.name == "Astronaut13D":
		Transcicion.go_to_scene("viajeespacial")
