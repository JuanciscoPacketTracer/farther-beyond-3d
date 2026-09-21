extends TextureRect

var tiempo := 0.0
@export var amplitud_y := 10.0    # cuánto sube/baja (en píxeles)
@export var velocidad := 1.5      # velocidad de balanceo
@export var rotacion_max := 3.0   # grados de rotación

var posicion_inicial := Vector2.ZERO

func _ready():
	posicion_inicial = position

func _process(delta):
	tiempo += delta * velocidad
	# Movimiento suave arriba/abajo
	position.y = posicion_inicial.y + sin(tiempo) * amplitud_y
	# Leve rotación alternante
	rotation_degrees = sin(tiempo * 0.8) * rotacion_max
