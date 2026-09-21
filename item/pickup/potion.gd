extends RigidBody3D
@export var slot_data: SlotData

@onready var bottle: MeshInstance3D = $bottle_B_green
@onready var pickup: AudioStreamPlayer3D = $pickup
@onready var area: Area3D = $Area3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var healparticles: GPUParticles3D = $healparticles

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.inventory_data.pick_up_slot_data(slot_data):
		area.monitoring = false
		area.set_deferred("monitorable", false)
		if collision:
			collision.disabled = true
		if bottle:
			healparticles.emitting = false
			bottle.visible = false
		pickup.play()
		await get_tree().create_timer(pickup.stream.get_length()).timeout
		queue_free()
func _physics_process(delta: float) -> void:
	bottle.rotate_y(delta)
