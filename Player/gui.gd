extends CanvasLayer

@onready var hearts_container: HBoxContainer = $hearts_container
@onready var heart_template: MarginContainer = $hearts_container/heart_template

var current_health := 0
var max_health := 0

func _ready():
	heart_template.visible = false

func update_health(new_health: int, new_max: int = -1, pulse: bool = false):
	if new_max != -1:
		max_health = new_max
		_update_max_hearts()

	new_health = clamp(new_health, 0, max_health)
	var old_health = current_health
	current_health = new_health

	_update_heart_states(old_health, pulse)

func _update_max_hearts():
	var hearts = hearts_container.get_children().filter(func(n): return n != heart_template)

	while hearts.size() < max_health:
		var h = heart_template.duplicate()
		h.visible = true
		hearts_container.add_child(h)
		hearts.append(h)

	while hearts.size() > max_health:
		var h = hearts.pop_back()
		h.queue_free()

func _update_heart_states(old_health: int, pulse: bool):
	var hearts = hearts_container.get_children().filter(func(n): return n != heart_template)

	for i in range(max_health):
		var sprite: AnimatedSprite2D = hearts[i].get_node("heart")
		if i < current_health:
			sprite.play("full")
			sprite.modulate = Color(1,1,1,1)
		else:
			sprite.play("empty")
			sprite.modulate = Color(0,0,0,0.8)
		if pulse and i >= old_health and i < current_health:
			_heart_pulse(hearts[i])

func _heart_pulse(node: Node):
	var tween = create_tween()
	node.scale = Vector2(1,1)
	tween.tween_property(node, "scale", Vector2(1.35,1.35), 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2(1,1), 0.12).set_trans(Tween.TRANS_SINE)
