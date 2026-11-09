extends RigidBody3D

@export var slot_data: SlotData
@onready var heart_red: MeshInstance3D = $heart_red
@onready var pickup: AudioStreamPlayer3D = $pickup
@onready var area: Area3D = $Area3D
@onready var collision: CollisionShape3D = $CollisionShape3D

var _picked_up := false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if _picked_up:
		return
	if not body.get("inventory_data"):
		return
	if body.inventory_data.pick_up_slot_data(slot_data):
		_picked_up = true
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		if collision:
			collision.set_deferred("disabled", true)
		if heart_red:
			heart_red.visible = false
		pickup.play()
		await get_tree().create_timer(pickup.stream.get_length()).timeout
		queue_free()

func _physics_process(delta: float) -> void:
	if not _picked_up:
		heart_red.rotate_y(delta)
