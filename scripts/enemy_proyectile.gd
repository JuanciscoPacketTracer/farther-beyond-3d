extends Area3D
class_name EnemyProjectile

@export var speed: float = 10.0
@export var damage: int = 1
@export var lifetime: float = 6.0
@export var shootable: bool = true
var dir: Vector3 = Vector3.FORWARD
var _spent: bool = false


func _ready() -> void:
	body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_hit(body: Node) -> void:
	if _spent or body is EnemyBase:
		return
	_spent = true
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func take_damage(_amount: float) -> void:
	if shootable and not _spent:
		_spent = true
		queue_free()
