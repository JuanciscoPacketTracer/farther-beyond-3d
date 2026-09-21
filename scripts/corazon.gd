extends Node3D
@onready var player_inventory: PanelContainer = $UI/inventory_interface2/PlayerInventory

@export var slot_data: SlotData
@onready var astronaut_13d: CharacterBody3D = $"."

func player_interact() -> void:
	player_inventory.pick_up_slot_data(slot_data)
