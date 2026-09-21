extends Control

signal sequence_finished
@onready var bg_sprite: Sprite2D = $CanvasLayer/Sprite2D
@onready var lbl: Label = $Label
@onready var rich_text_label: RichTextLabel = $CanvasLayer/RichTextLabel
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var textos = [
	"Y así fue como exploraste la estación abandonada!",
	"A pesar de los obstaculos, lograste cumplir tus objetivos!",
	"Demostraste hasta donde puedes llegar....",
	"Pero, siempre podemos ir más lejos!",
	"Continuará...",
	"Creado por 
	Juan Francisco Hernández Camacho
	Raul Sanchez Heredia",
	"Programación general
	Juan Francisco Hernández Camacho",
	"Dirección de Arte
	Raul Sanchez Heredia",
	"Creación y Programación de Enemigos
	Juan Francisco Hernández Camacho",
	"Project Manager
	Juan Francisco Hernández Camacho",
	"Dirección de Audio
	Juan Francisco Hernández Camacho",
	"Recursos extraidos de Itch.io y OpenGameArt.com",
	"Sonidos y musica:
	Extraidos de OpengameArt",
	"Proyecto creado para la materia Diseño y Desarrollo de Videojuegos 
	Impartida por el Maestro Yoshitaro Castro Romo
	en la Institución Universitaria UAdeO Unidad Regional Guamúchil",
	"Gracias por jugar"
]

func _ready() -> void:
	rich_text_label.text = ""
	bg_sprite.modulate.a = 0.0
	connect("sequence_finished", Callable(self, "_on_sequence_finished"))
	_start_sequence()


func _start_sequence() -> void:
	await fade_bus_volume("Musica", -40.0, 0.0, 2.0)

	
	await get_tree().create_timer(1.0).timeout
	for t in textos:
		await _mostrar_texto(t)
		await get_tree().create_timer(1.0).timeout
	
	
	emit_signal("sequence_finished")


func _mostrar_texto(t: String) -> void:
	rich_text_label.text = t
	rich_text_label.modulate.a = 0
	bg_sprite.modulate.a = 0

	await _fade(bg_sprite, 0.0, 1.0, 0.8)
	await _fade(rich_text_label, 0.0, 1.0, 0.8)

	await get_tree().create_timer(2.0).timeout

	await _fade(rich_text_label, 1.0, 0.0, 0.8)
	await _fade(bg_sprite, 1.0, 0.0, 0.8)


func _fade(node, from_a, to_a, time):
	var t := 0.0
	while t < time:
		t += get_process_delta_time()
		var alpha = lerp(from_a, to_a, t / time)
		node.modulate.a = alpha
		await get_tree().process_frame


func _on_sequence_finished() -> void:
	await fade_bus_volume("Musica", 0.0, -40.0, 2.0)
	Transcicion.go_to_scene("menu")
func fade_bus_volume(bus_name: String, from_db: float, to_db: float, duration: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		var v = lerp(from_db, to_db, t / duration)
		AudioServer.set_bus_volume_db(bus, v)
		await get_tree().process_frame
