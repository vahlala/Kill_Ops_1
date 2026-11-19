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

@export_group("Accroupi")
@export_range(0.0, 1.0) var crouch_speed_factor: float = 0.35   # vitesse en marchant accroupi
@export var crouch_height: float = 16.0     # hauteur de la hitbox accroupie (debout : 25)

@export_group("Dégâts")
@export var invulnerable_time: float = 1.2  # invincibilité après un coup
@export var hit_stun_time: float = 0.35     # durée de l'état Hit (pas de contrôle)
@export var default_knockback: Vector2 = Vector2(120.0, -140.0)

@export_group("Tir")
@export var bullet_scene: PackedScene
@export var shoot_interval: float = 0.15

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _invulnerable_timer: float = 0.0
var _last_shot: float = 0.0

var _stand_size: Vector2
var _stand_position: Vector2

@onready var camera: Camera2D = $Camera2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	super()                       # initialise PV et références (GenericCharacter)
	add_to_group("Player")        # les ennemis trouveront le joueur par ce groupe
	floor_snap_length = 6.0       # reste collé au sol dans les pentes
	floor_constant_speed = true   # même vitesse en montée et en descente

	# Copie propre à cette instance : on modifie la forme en s'accroupissant.
	collision_shape.shape = collision_shape.shape.duplicate()
	_stand_size = collision_shape.shape.size
	_stand_position = collision_shape.position
	_last_shot = shoot_interval

## Ce qui tourne à chaque frame quel que soit l'état.
## Le parent est traité avant ses enfants : ceci s'exécute AVANT l'état actif.
func _physics_process(delta: float) -> void:
	update_jump_timers(delta)
	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta
	_last_shot += delta
	if wants_to_shoot() and can_shoot() and _last_shot >= shoot_interval:
		shoot()

#region Mouvement horizontal
func get_input_direction() -> float:
	return Input.get_axis("Left", "Right")


func apply_horizontal_movement(direction: float, delta: float, speed_factor: float = 1.0) -> void:
	var control := 1.0 if is_on_floor() else air_control
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed * speed_factor, acceleration * control * delta)
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


#region Accroupi
func wants_to_crouch() -> bool:
	return Input.is_action_pressed("Down")


## Rapetisse la hitbox en gardant les pieds au même endroit.
func set_crouching(crouching: bool) -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if crouching:
		shape.size.y = crouch_height
		collision_shape.position.y = _stand_position.y + (_stand_size.y - crouch_height) / 2.0
	else:
		shape.size = _stand_size
		collision_shape.position = _stand_position


## Vrai s'il y a la place de se relever (pas de plafond juste au-dessus).
func can_stand_up() -> bool:
	return not test_move(global_transform, Vector2.UP * (_stand_size.y - crouch_height))
#endregion


#region Dégâts
func is_invulnerable() -> bool:
	return _invulnerable_timer > 0.0


## Point d'entrée des dégâts. Sans knockback fourni, le soldat recule
## dans le dos (opposé à la direction où il regarde).
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invulnerable():
		return
	if knockback == Vector2.ZERO:
		knockback = Vector2(default_knockback.x * -facing, default_knockback.y)
	velocity = Vector2.ZERO           # le recul remplace la vitesse actuelle
	super(amount, knockback)
	if is_dead:
		state_machine.transition_to("Dead")
	else:
		_invulnerable_timer = invulnerable_time
		state_machine.transition_to("Hit")
#endregion

#region Tir
func wants_to_shoot() -> bool:
	return Input.is_action_pressed("Shoot")


## Pas de tir pendant l'étourdissement ni après la mort.
func can_shoot() -> bool:
	var state := state_machine.get_current_state_name()
	return state != "Hit" and state != "Dead"


func shoot() -> void:
	_last_shot = 0.0
	var bullet: Bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.rotation = 0.0 if facing > 0 else PI


## On retourne aussi le canon quand le soldat change de côté.
func set_facing(direction: float) -> void:
	super(direction)
	muzzle.position.x = absf(muzzle.position.x) * facing
#endregion

#region Caméra

func set_camera_limits(area: Rect2i) -> void:
	camera.limit_left = area.position.x
	camera.limit_top = area.position.y
	camera.limit_right = area.end.x
	camera.limit_bottom = area.end.y
#endregion
