extends PanelContainer
const Slot = preload("uid://d2oclpork4lvf")
@onready var itemgrid: GridContainer = $MarginContainer/itemgrid
func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)
func clear_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.disconnect(populate_item_grid)
func populate_item_grid(inventory_data: InventoryData) -> void:
	for child in itemgrid.get_children():
		child.queue_free()
	for slot_data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		itemgrid.add_child(slot)
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		if slot_data:
			slot.set_slot_data(slot_data)
