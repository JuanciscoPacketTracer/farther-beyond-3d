extends Area3D
@export var speed:=60.0
@export var damage:=2.5
var dir:=Vector3.ZERO

func _ready():
	connect("area_entered",Callable(self,"_hit"))
	connect("body_entered",Callable(self,"_hit")) 

@export var max_distance := 100.0
@onready var player := get_tree().get_nodes_in_group("player")[0]

func _physics_process(delta):
	global_position += dir * speed * delta

	if is_instance_valid(player):
		if global_position.distance_to(player.global_position) > max_distance:
			queue_free()


func _hit(a):
	if a.has_method("take_damage"):
		a.take_damage(damage)
	queue_free()
