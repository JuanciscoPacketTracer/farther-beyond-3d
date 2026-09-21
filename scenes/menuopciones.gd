extends Control
@onready var botones: VBoxContainer = $CenterContainer/Botones
@onready var volumen: Panel = $Volumen
func _ready():
	botones.visible = true
	volumen.visible = false

func _on_btnvolumen_pressed() -> void:
	botones.visible = false
	volumen.visible = true


func _on_btnconfiguracion_pressed() -> void:
	pass # Replace with function body.


func _on_btnvolver_pressed() -> void:
	Transcicion.go_to_scene("menu")


func _on_btnvolver_2_pressed() -> void:
	botones.visible = true
	volumen.visible = false
