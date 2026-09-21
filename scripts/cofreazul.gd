extends StaticBody3D
signal toggle_inventory(external_inventory_owner)
@export var inventory_data: InventoryData
@onready var chest_lid: MeshInstance3D = $chest2/chest_lid
var is_open := false

func player_interact() -> void:
	toggle_inventory.emit(self)
	if is_open:
		chest_lid.rotation_degrees.x = 0
	else:
		chest_lid.rotation_degrees.x = -90
	is_open = !is_open
