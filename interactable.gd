class_name Interactable
extends Area3D

signal interacted(player)

func player_interact() -> void:
	interacted.emit(PlayerManager.player)
	_on_interact()

func _on_interact() -> void:
	pass  # override in child scripts
