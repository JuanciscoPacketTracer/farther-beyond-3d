extends TextureRect
@export var velocidad_rotacion := 1.0
func _ready():
	set_pivot_offset(Vector2(size.x / 2, size.y / 2))
func _process(delta):
	rotation_degrees += velocidad_rotacion * delta
