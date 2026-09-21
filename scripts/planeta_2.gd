extends TextureRect
@export var velocidad_rotacion := 1.0
func _ready():
	set_pivot_offset(Vector2(size.x / 2, size.y / 2))
var tiempo := 0.0
func _process(delta):
	tiempo += delta
	modulate.a = 0.25 + sin(tiempo * 1.2) * 0.1
	rotation_degrees += velocidad_rotacion * delta
