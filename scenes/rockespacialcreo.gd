extends CharacterBody3D

@export var rock_scale:=20.0
@export var rock_speed:=2.0
@export var health:=8.0
var dir:=Vector3.ZERO
var rot_speed:=Vector2.ZERO
@onready var rompe: AudioStreamPlayer3D = $romperoca
@onready var choque: AudioStreamPlayer3D = $choqueroca
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var rocasparticulas: GPUParticles3D = $rocasparticulas

func take_damage(d):
	health -= d
	if health <= 0:
		die()

func die():
	if not rompe.playing:
		rompe.play()
	rocasparticulas.restart()
	rocasparticulas.emitting = true
	mesh_instance_3d.visible = false
	collision_shape_3d.disabled = true
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _ready():
	scale = Vector3.ONE * rock_scale
	dir = Vector3(randf()*2-1, randf()*2-1, randf()*2-1).normalized() * rock_speed
	rot_speed = Vector2(randf_range(-0.5,0.5), randf_range(-0.5,0.5))
func _physics_process(delta):
	velocity = dir
	move_and_slide()
	rotation.x += rot_speed.x * delta
	rotation.y += rot_speed.y * delta

	if get_slide_collision_count() > 0:
		dir = -dir
		choque.play()
