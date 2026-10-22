class_name Player
extends GenericCharacter
## Le soldat contrôlé par le joueur.

@export_group("Déplacement")
@export var acceleration: float = 900.0     # px/s² pour atteindre move_speed
@export var friction: float = 1200.0        # px/s² pour s'arrêter
@export_range(0.0, 1.0) var air_control: float = 0.6   # contrôle en l'air (fraction)

@export_group("Saut")
@export var jump_velocity: float = -280.0
@export_range(0.0, 1.0) var jump_cut: float = 0.45     # relâcher tôt = saut plus court
@export var coyote_time: float = 0.1        # on peut encore sauter juste après le bord
@export var jump_buffer_time: float = 0.1   # un saut pressé juste avant l'atterrissage compte

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	super()                       # initialise PV et références (GenericCharacter)
	add_to_group("Player")        # les ennemis trouveront le joueur par ce groupe
	floor_snap_length = 6.0       # reste collé au sol dans les pentes
	floor_constant_speed = true   # même vitesse en montée et en descente


# TEMPORAIRE (tâche 5) : cette fonction sera remplacée par la machine à états (tâche 6).
# Les états réutiliseront exactement les fonctions ci-dessous.
func _physics_process(delta: float) -> void:
	update_jump_timers(delta)
	apply_gravity(delta)

	var direction := get_input_direction()
	apply_horizontal_movement(direction, delta)
	set_facing(direction)

	if wants_to_jump() and can_jump():
		jump()
	handle_jump_cut()

	move_and_slide()
	_update_animation_temp(direction)

# TEMPORAIRE (tâche 5) : à la tâche 6, chaque état jouera sa propre animation.
func _update_animation_temp(direction: float) -> void:
	if not is_on_floor():
		play_animation("Jump" if velocity.y < 0.0 else "Fall")
	elif direction != 0.0:
		play_animation("Run")
	else:
		play_animation("Idle")
		
#region Mouvement horizontal
func get_input_direction() -> float:
	return Input.get_axis("Left", "Right")


func apply_horizontal_movement(direction: float, delta: float) -> void:
	var control := 1.0 if is_on_floor() else air_control
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)
#endregion


#region Saut
func update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if Input.is_action_just_pressed("Jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta


func wants_to_jump() -> bool:
	return _jump_buffer_timer > 0.0


## Au sol, ou quitté le sol depuis moins de coyote_time : jamais de saut en plein vol.
func can_jump() -> bool:
	return _coyote_timer > 0.0


func jump() -> void:
	velocity.y = jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func handle_jump_cut() -> void:
	if Input.is_action_just_released("Jump") and velocity.y < 0.0:
		velocity.y *= jump_cut
#endregion


#region Caméra

func set_camera_limits(area: Rect2i) -> void:
	camera.limit_left = area.position.x
	camera.limit_top = area.position.y
	camera.limit_right = area.end.x
	camera.limit_bottom = area.end.y
#endregion
