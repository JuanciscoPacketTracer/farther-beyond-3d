extends ProgressBar
class_name HealthBar

@export var damage_delay: float = 0.4   ## cuánto se queda visible el daño
@export var drain_time: float = 0.25    ## cuánto tarda en vaciarse la estela

@onready var damagebar: ProgressBar = $damagebar
@onready var timer: Timer = $Timer

var _tween: Tween


func _ready() -> void:
	timer.one_shot = true
	timer.wait_time = damage_delay
	timer.timeout.connect(_on_timer_timeout)


func init_health(current: int, maximum: int) -> void:
	max_value = maximum
	damagebar.max_value = maximum
	value = current
	damagebar.value = current


func set_health(new_value: int) -> void:
	var previous := value
	value = clampf(new_value, 0.0, max_value)

	if _tween and _tween.is_valid():
		_tween.kill()

	if value < previous:
		timer.start()             # la estela espera un instante
	else:
		damagebar.value = value   # curación: sin estela


func _on_timer_timeout() -> void:
	_tween = create_tween()
	_tween.tween_property(damagebar, "value", value, drain_time)
