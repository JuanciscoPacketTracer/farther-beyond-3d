extends CanvasLayer

@export var switch_duration: float = 1.0
var current_scene: String = ""

@onready var transcicion: CanvasLayer = $"." 
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var label: Label = $Label
@onready var color_rect: ColorRect = $ColorRect

var loading_dots_timer: Timer
var dot_count := 0
var max_dots := 3
var is_loading := false

func _ready():
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0
	sprite_2d.visible = false
	label.visible = false
	current_scene = get_tree().current_scene.name
	
	# Timer para animar los puntos del texto
	loading_dots_timer = Timer.new()
	loading_dots_timer.wait_time = 0.5
	loading_dots_timer.one_shot = false
	add_child(loading_dots_timer)
	loading_dots_timer.timeout.connect(_on_loading_dots_timeout)

func _on_loading_dots_timeout():
	if not is_loading:
		return
	dot_count = (dot_count + 1) % (max_dots + 1)
	var dots = ".".repeat(dot_count)
	label.text = "Cargando" + dots

func go_to_scene(scene_name: String, awaitable = null) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Mostrar logo y texto
	sprite_2d.visible = true
	label.visible = true
	label.text = "Cargando"
	is_loading = true
	loading_dots_timer.start()

	# Iniciar animación de rotación
	if animation_player.has_animation("rotacion"):
		animation_player.play("rotacion")

	# Fundido de entrada
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 1, switch_duration / 2.0)
	await tween.finished

	# Cambio de escena
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name)
	get_tree().paused = false

	if awaitable:
		await awaitable

	current_scene = scene_name

	# Fundido de salida
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 0, switch_duration / 2.0)
	await tween.finished

	# Detener animación y ocultar
	if animation_player.is_playing():
		animation_player.stop()
	sprite_2d.visible = false
	label.visible = false
	is_loading = false
	loading_dots_timer.stop()

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
