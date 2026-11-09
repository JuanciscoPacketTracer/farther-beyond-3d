extends CharacterBody3D
@onready var button_boost: TouchScreenButton = $ui_buttons/buttonBoost
@onready var button_attack: TouchScreenButton = $ui_buttons/buttonAttack
@onready var joystick_ship: VirtualJoystickDX = $ui_buttons/JoystickShip
signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 10
@export var invulnerability_time: float = 0.6
@onready var health_bar: HealthBar = $CanvasLayer/healthbar

var health: int
var _invulnerable: bool = false
var _dead: bool = false
@onready var gun: Marker3D = $disparo_spawn
@export var speed:=12.0
@export var boost_speed:=36.0
@export var rotation_speed:=3.0
@export var mouse_sensitivity:=0.25
@export var min_zoom:=1.0
@export var max_zoom:=20.0
@export var zoom_speed:=1.0
@export var zoom_smoothing:=10.0
@export var bullet_scene:PackedScene
var _current_zoom:=6.0
var _is_paused=false
var can_shoot=true
@onready var propulsor:GPUParticles3D=$propulsor
@onready var propulsor2:GPUParticles3D=$propulsor2
@onready var _arm:SpringArm3D=$camerapivot/SpringArm3D
@onready var _pause_ui:Control=$"../Pausa"
@onready var shootsound: AudioStreamPlayer3D = $shoot
@onready var propulsorsonido: AudioStreamPlayer3D = $propulsorsonido

func toggle_pause_state(is_paused: bool) -> void:
	_is_paused = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func _ready():
	health = max_health
	health_changed.connect(func(c, m): health_bar.set_health(c))
	health_bar.init_health(health, max_health)
	_arm.add_excluded_object(self)
	_current_zoom=_arm.spring_length
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(_pause_ui):
		_pause_ui.visible=false

func _unhandled_input(e):
	if e.is_action_pressed("boost"):
		propulsorsonido.playing = true
	if e.is_action_pressed("shoot") and can_shoot and gun.is_inside_tree():
		_shoot()
	if e.is_action_pressed("pause"):
		_is_paused=!_is_paused
		get_tree().paused=_is_paused
		if is_instance_valid(_pause_ui):
			_pause_ui.visible=_is_paused
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if _is_paused else Input.MOUSE_MODE_CAPTURED
		return
	if _is_paused:
		return
	if e is InputEventMouseButton:
		if e.button_index==MOUSE_BUTTON_WHEEL_UP:
			_current_zoom=clamp(_current_zoom-zoom_speed,min_zoom,max_zoom)
		elif e.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			_current_zoom=clamp(_current_zoom+zoom_speed,min_zoom,max_zoom)
	if e is InputEventMouseMotion:
		rotate_object_local(Vector3.UP,-e.relative.x*mouse_sensitivity*0.01)
		rotate_object_local(Vector3.RIGHT,-e.relative.y*mouse_sensitivity*0.01)

func _process(delta):
	_arm.spring_length=lerpf(_arm.spring_length,_current_zoom,delta*zoom_smoothing)

func _physics_process(delta):
	if get_tree().paused:
		return
	var boosting=Input.is_action_pressed("boost")
	
	propulsor.emitting=boosting
	propulsor2.emitting=boosting
	var current_speed=boost_speed if boosting else speed
	velocity=transform.basis.z*current_speed

	if Input.is_action_pressed("roll_left"):
		rotate_object_local(Vector3.FORWARD,rotation_speed*delta)
	if Input.is_action_pressed("roll_right"):
		rotate_object_local(Vector3.BACK,rotation_speed*delta)
	move_and_slide()

func _shoot():
	var b=bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	shootsound.playing = true
	b.global_position=gun.global_position
	b.dir=global_transform.basis.z
func take_damage(amount: float) -> void:
	if _dead or _invulnerable:
		return
	health = maxi(health - int(ceil(amount)), 0)
	health_changed.emit(health, max_health)
	if health == 0:
		_die()
		return
	_start_invulnerability()


func heal(amount: int) -> void:
	if _dead:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func _start_invulnerability() -> void:
	_invulnerable = true
	await get_tree().create_timer(invulnerability_time).timeout
	_invulnerable = false

@export_file("*.tscn") var game_over_scene: String = "res://muerte.tscn"
@export var death_delay: float = 1.0

func _die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector3.ZERO
	set_physics_process(false)
	propulsor.emitting = false
	propulsor2.emitting = false
	propulsorsonido.stop()
	died.emit()

	await get_tree().create_timer(death_delay).timeout

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	get_tree().change_scene_to_file(game_over_scene)
