extends RigidBody3D

@export var roam_speed:=3.0
@export var chase_speed:=6.0
@export var detection_radius:=20.0
@export var damage:=1
@export var min_chillido_interval:=4.0
@export var max_chillido_interval:=8.0
@export var rebound_force:=4.0
@export var stun_time:=2.0
@export var max_health:=5
var health:=5
var tiempo_para_chillido:=0.0
var state:="roaming"
var roam_direction:=Vector3.ZERO
var roam_timer:=0.0
var can_damage:=true
var stunned:=false

@onready var bat_model:Node3D=$bat2
@onready var harmparticles:GPUParticles3D=$harmparticles
@onready var aturdido:AudioStreamPlayer3D=$Aturdido
@onready var ataque:AudioStreamPlayer3D=$Ataque
@onready var chillido:AudioStreamPlayer3D=$chillido
@onready var player:CharacterBody3D=null


func die():
	stunned=true
	linear_velocity=Vector3.ZERO
	angular_velocity=Vector3.ZERO
	var tilt=30 if randf()>0.5 else -30
	var sr=bat_model.rotation_degrees
	var er=sr+Vector3(0,0,tilt)
	var sy=bat_model.position.y
	var ey=sy-0.5
	var t:=0.0
	var d:=0.4
	while t<d:
		var k=t/d
		bat_model.rotation_degrees=sr.lerp(er,k)
		bat_model.position.y=lerp(sy,ey,k)
		t+=get_physics_process_delta_time()
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	queue_free()

func take_damage(d):
	health -= d
	harmparticles.emitting = true
	if health <= 0:
		die()

func _ready():
	contact_monitor=true
	max_contacts_reported=4
	var players=get_tree().get_nodes_in_group("player")
	if players.size()>0: player=players[0]
	tiempo_para_chillido=randf_range(min_chillido_interval,max_chillido_interval)
	_set_new_roam_direction()
	connect("body_entered",Callable(self,"_on_body_entered"))
func _physics_process(delta):
	if not is_instance_valid(player):
		return
	if stunned:
		return
	match state:
		"roaming":
			_process_roaming(delta)
			_check_detection()
		"chasing":
			_process_chasing(delta)
			_check_lost_player()
	if linear_velocity.length() > 0.1:
		var dir = linear_velocity.normalized()
		var target_rot = atan2(dir.x, dir.z)
		bat_model.rotation.y = lerp_angle(bat_model.rotation.y, target_rot, delta * 5.0)
	tiempo_para_chillido -= delta
	if tiempo_para_chillido <= 0:
		if not chillido.playing:
			chillido.play()
		tiempo_para_chillido = randf_range(min_chillido_interval, max_chillido_interval)

func _process_roaming(delta):
	roam_timer-=delta
	if roam_timer<=0: _set_new_roam_direction()
	linear_velocity=roam_direction*roam_speed

func _set_new_roam_direction():
	var a=randf_range(0,TAU)
	roam_direction=Vector3(sin(a),0,cos(a)).normalized()
	roam_timer=randf_range(2.0,5.0)

func _process_chasing(delta):
	var d=(player.global_position-global_position).normalized()
	d.y=clamp(d.y,-0.3,0.3)
	linear_velocity=d*chase_speed

func _check_detection():
	if global_position.distance_to(player.global_position)<=detection_radius:
		state="chasing"

func _check_lost_player():
	if global_position.distance_to(player.global_position)>detection_radius*1.5:
		state="roaming"

func _on_body_entered(body):
	if body==player and can_damage:
		if body.has_method("take_damage"): body.take_damage(damage)
		if not ataque.playing: ataque.play()
		var aw=(global_position-body.global_position)
		if aw.length()==0: aw=Vector3(0,1,0)
		aw=aw.normalized()
		linear_velocity=aw*rebound_force
		apply_central_impulse(aw*(rebound_force*0.2))
		stunned=true
		if not aturdido.playing: aturdido.play()
		harmparticles.restart()
		harmparticles.emitting=true
		var orig_rot = bat_model.rotation_degrees
		var shake = 15.0
		for i in range(4):
			bat_model.rotation_degrees.y = orig_rot.y + shake
			await get_tree().create_timer(0.05).timeout
			bat_model.rotation_degrees.y = orig_rot.y - shake
			await get_tree().create_timer(0.05).timeout
			shake *= 0.6
		bat_model.rotation_degrees = orig_rot

		can_damage=false
		await get_tree().create_timer(stun_time).timeout
		stunned=false
		harmparticles.emitting=false
		await get_tree().create_timer(1.0-stun_time).timeout
		can_damage=true
