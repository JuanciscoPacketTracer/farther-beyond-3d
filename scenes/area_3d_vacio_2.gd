extends Area3D
var can_damage:bool=true
@export var damage:int=1
@export var respawn_point:Node3D
@onready var player:CharacterBody3D=null
@onready var sonidocaida: AudioStreamPlayer = $"../../Sonidocaida"

func _ready():
	var players=get_tree().get_nodes_in_group("player")
	if players.size()>0:
		player=players[0]

func _on_body_entered(body: Node3D) -> void:
	if body==player and can_damage:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		elif body.has_variable("health"):
			body.health-=damage
			body.health=max(body.health,0)
		sonidocaida.playing=true
		if respawn_point:
			body.global_transform.origin=respawn_point.global_transform.origin
