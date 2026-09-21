extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_toggle_reverb(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _toggle_reverb(enable: bool) -> void:
	var bus_index = AudioServer.get_bus_index("Efectos")
	var effect = AudioServer.get_bus_effect(bus_index, 0) # 0 = primer efecto del bus

	if effect is AudioEffectReverb:
		AudioServer.set_bus_effect_enabled(bus_index, 0, enable)
		print("Reverb activado:", enable)
