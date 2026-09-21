extends CharacterBody3D
@export_group("Inventory")
@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip
var is_dead := false
@export_group("Camera")
@export_range(0.0001, 0.02) var mouse_sensitivity := 0.004
@export var min_zoom := 1.0     # Minimum camera distance
@export var max_zoom := 20.0    # Maximum camera distance
@export var zoom_speed := 1.0   # Speed of zoom change
@export var zoom_smoothing := 10.0 # Smoothness of zoom transition
var max_health: int = 3
var health: int = max_health
signal toggle_inventory()
var inventory_open = false

@export_group("Movement")
@export var move_speed := 4.0
@export var sprint_speed := 14.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 14.0

# Camera State Variables (Roblox Style)
var _is_right_click_held := false
var _camera_input_direction := Vector2.ZERO
var _current_zoom := 5.0 
var _last_movement_direction := Vector3.BACK
var _gravity := -30.0
var _paso_timer := 0.0
var _paso_interval_base := 0.35
var _was_on_floor := false

@onready var edge_check: RayCast3D = $astronautskin/edge_check
@onready var edge_top_check: RayCast3D = $astronautskin/edge_top_check
var is_paused_menu_open = false
signal pause_toggled(is_open)
var is_hanging = false
var edge_grab_height = 1.8 
var hang_gravity = -0.2

@onready var hearts_hud: CanvasLayer = $ui_hearts
@onready var pausa: Control = $"../Pausa"
@onready var _camera_pivot: Node3D = %camerapivot
@onready var _spring_arm: SpringArm3D = $camerapivot/SpringArm3D 
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: AstronautSkin = $astronautskin
@onready var pasos_sonidos := [$paso1,$paso2,$paso3,$paso4,$paso5]
@onready var saltar: AudioStreamPlayer3D = $saltar
@onready var aterrizar: AudioStreamPlayer3D = $aterrizar
@onready var interact_ray: RayCast3D = $camerapivot/SpringArm3D/Camera3D/InteractRay
@onready var healparticles: GPUParticles3D = $healparticles
@onready var harmparticles: GPUParticles3D = $harmparticles
func exit_pause_menu():
	if is_paused_menu_open:
		is_paused_menu_open = false
		pausa.visible = false
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_toggled.emit(false)
func _ready() -> void:
	inventory_open = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	PlayerManager.player = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not toggle_inventory.is_connected(_on_toggle_inventory):
		toggle_inventory.connect(_on_toggle_inventory)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	inventory_open = false
	if hearts_hud:
		hearts_hud.update_health(health, max_health)
	if _spring_arm:
		_spring_arm.add_excluded_object(self) 
		_current_zoom = _spring_arm.spring_length
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_current_zoom = clamp(_current_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_current_zoom = clamp(_current_zoom + zoom_speed, min_zoom, max_zoom)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_is_right_click_held = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				_is_right_click_held = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion:
		if _is_right_click_held:
			_camera_input_direction = -event.screen_relative * mouse_sensitivity
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("pause"):
		if is_paused_menu_open:
			exit_pause_menu()
			return
		if inventory_open:
			toggle_inventory.emit()
		is_paused_menu_open = true
		pausa.visible = is_paused_menu_open
		get_tree().paused = is_paused_menu_open
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_toggled.emit(is_paused_menu_open)
	if Input.is_action_just_pressed("interact"):
		interact()

func _process(delta: float) -> void:
	if _spring_arm:
		_spring_arm.spring_length = lerpf(_spring_arm.spring_length, _current_zoom, delta * zoom_smoothing)

func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x = clamp(
		_camera_pivot.rotation.x + _camera_input_direction.y,
		deg_to_rad(-60),
		deg_to_rad(60)
	)
	_camera_pivot.rotation.y += _camera_input_direction.x
	_camera_pivot.rotation.z = 0.0
	_camera_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector("move_left","move_right","move_up","move_down")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var move_direction := (forward * raw_input.y + right * raw_input.x).normalized()
	var y_velocity := velocity.y
	velocity.y = 0
	var velocidad_actual = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	velocity = velocity.move_toward(move_direction * velocidad_actual, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta
	var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_starting_jump:
		velocity.y += jump_impulse
		_instanciar_sonido(saltar)
	if not is_on_floor() and velocity.y < 0 and not is_hanging:
		if edge_check.is_colliding() and edge_top_check.is_colliding():
			var top_point = edge_top_check.get_collision_point()
			var wall_normal = edge_check.get_collision_normal()
			if wall_normal.dot(-global_transform.basis.z) > 0.5:
				if top_point.y > global_position.y + 0.35 and top_point.y - global_position.y < edge_grab_height:
					is_hanging = true
					velocity = Vector3.ZERO
					_skin.edge_grab()
	if is_hanging:
		velocity = Vector3(0, hang_gravity, 0)
		move_and_slide()
		if Input.is_action_just_pressed("jump"):
			is_hanging = false
			velocity.y = jump_impulse * 0.8
			_skin.jump()
		if Input.is_action_just_pressed("ui_down"):
			is_hanging = false
			velocity.y = -5.0
			_skin.fall()
		return
	move_and_slide()
	var on_floor_now = is_on_floor()

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction

	if move_direction.length() > 0.1:
		_skin.global_rotation.y = lerp_angle(
			_skin.rotation.y,
			Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP),
			rotation_speed * delta
		)
	if is_starting_jump:
		_skin.jump()
	elif not on_floor_now:
		if velocity.y > 0:
			_skin.jump()
		else:
			_skin.fall()
	elif on_floor_now:
		if velocidad_actual > move_speed + 0.5 and velocity.length() > 0.2:
			_skin.run()
			_reproducir_paso(delta, velocidad_actual)
		elif velocity.length() > 0.2:
			_skin.move()
			_reproducir_paso(delta, velocidad_actual)
		else:
			_skin.idle()
	if on_floor_now and not _was_on_floor:
		_instanciar_sonido(aterrizar)
		_skin.land()
		_paso_timer = 0

	_was_on_floor = on_floor_now

func _reproducir_paso(delta: float, speed: float):
	_paso_timer -= delta
	if _paso_timer <= 0:
		var paso = pasos_sonidos[randi() % pasos_sonidos.size()]
		_instanciar_sonido(paso)
		var speed_ratio = speed / move_speed if move_speed != 0 else 1.0
		_paso_timer = _paso_interval_base / speed_ratio * randf_range(1.85, 2.15)
func _instanciar_sonido(original: AudioStreamPlayer3D):
	var s = original.duplicate() as AudioStreamPlayer3D
	add_child(s)
	s.play()
	await get_tree().create_timer(s.stream.get_length()).timeout
	s.queue_free()
func _on_toggle_inventory():
	inventory_open = !inventory_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func interact() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.has_method("player_interact"):
			collider.player_interact()
func get_drop_position() -> Vector3:
	var direction = -_skin.global_basis.z 
	return _skin.global_position + direction * 1.5 + Vector3.UP * 1.0
func heal(amount: int) -> void:
	health = clamp(health + amount, 0, max_health)
	healparticles.emitting = true
	if hearts_hud:
		hearts_hud.update_health(health, max_health, true) 
func take_damage(amount: int):
	if is_dead:
		return 
	health -= amount
	harmparticles.emitting = true
	if hearts_hud:
		hearts_hud.update_health(health, max_health)
	if health <= 0:
		die()

func add_max_health(amount: int):
	max_health += amount
	health = max_health 
	if hearts_hud:
		hearts_hud.update_health(health, max_health, true)
func die():
	if is_dead:
		return
	is_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	velocity = Vector3.ZERO
	set_physics_process(false)
	if _skin and _skin.has_method("die"):
		_skin.die()
	if _skin and _skin.has_signal("animation_finished"):
		await _skin.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://muerte.tscn")
