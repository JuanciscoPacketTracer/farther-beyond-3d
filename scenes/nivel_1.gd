extends Node3D

@onready var player: CharacterBody3D = $Astronaut13D
@onready var inventory_interface: Control = $UI/inventory_interface2
@onready var hot_bat_inventory: PanelContainer = $UI/HotBatInventory
@onready var texture_rect: TextureRect = $UI/inventory_interface2/TextureRect
@onready var hotbartexture: TextureRect = $UI/hotbartexture

const heart = preload("uid://vvt8eumme3mt")
const potion = preload("uid://du42drel8o3mb")

var ITEM_SCENES = {
	"Corazon": heart,
	"Pocion": potion,
}
func _ready() -> void:
	Musicaintro.playing = false
	player.toggle_inventory.connect(toggle_inventory_interface)
	player.pause_toggled.connect(_on_player_pause_toggled)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.force_close.connect(toggle_inventory_interface)
	hot_bat_inventory.set_inventory_data(player.inventory_data)
	inventory_interface.visible = false
	texture_rect.visible = false
	hot_bat_inventory.show()
	hotbartexture.show()
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.visible = not inventory_interface.visible
	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hot_bat_inventory.hide()
		texture_rect.visible = true
		hotbartexture.visible = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hot_bat_inventory.show()
		hotbartexture.visible = true
		texture_rect.visible = false
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()

func _on_player_pause_toggled(is_open: bool) -> void:
	if is_open:
		close_inventory_interface()

func close_inventory_interface() -> void:
	if not inventory_interface.visible:
		inventory_interface.clear_external_inventory()
		return
	inventory_interface.hide()
	hot_bat_inventory.show()
	hotbartexture.show()
	texture_rect.hide()
	inventory_interface.clear_external_inventory()
func _on_inventory_interface_2_drop_slot_data(slot_data: SlotData) -> void:
	if slot_data == null or slot_data.item_data == null:
		return
	var item_name = slot_data.item_data.name
	if ITEM_SCENES.has(item_name):
		var pick_up_scene = ITEM_SCENES[item_name]
		var pick_up = pick_up_scene.instantiate()
		pick_up.slot_data = slot_data
		pick_up.global_position = player.global_position + Vector3(0, 1.5, -2)
		get_tree().current_scene.add_child(pick_up)
	else:
		push_warning("No se encontró escena para el ítem: %s" % item_name)


func _on_area_3d_vacio_body_entered(_body: Node3D) -> void:
	pass # Replace with function body.


func _on_area_3d_vacio_ready() -> void:
	pass # Replace with function body.
