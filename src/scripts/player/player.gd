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
@export var shoot_interval: float = 0.15
@export var shoot_anim_time: float = 0.25   # durée de la pose de tir après une balle

## Pose de tir à utiliser selon l'animation du corps (Jump et Fall partagent « Air »).
const SHOOT_POSE := {"Idle": "Stand", "Run": "Run", "Jump": "Air", "Fall": "Air", "Crouch": "Crouch"}

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _invulnerable_timer: float = 0.0
var _last_shot: float = 0.0
var _shoot_anim_timer: float = 0.0
var _aim: Vector2 = Vector2.RIGHT          # direction de tir courante
var _body_animation: String = "Idle"       # animation demandée par l'état actif

var _stand_size: Vector2
var _stand_position: Vector2

@onready var camera: Camera2D = $Camera2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_up: Marker2D = $MuzzleUp
@onready var muzzle_down: Marker2D = $MuzzleDown
@onready var muzzle_crouch: Marker2D = $MuzzleCrouch

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
	_aim = get_aim_direction()
	_last_shot += delta
	if wants_to_shoot() and can_shoot() and _last_shot >= shoot_interval:
		shoot()


## Le choix de l'animation se fait ici, après la physique de la frame.
func _process(delta: float) -> void:
	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer -= delta
	_update_animation()

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


## Haut : vers le haut. Bas : vers le bas, seulement en l'air
## (au sol, Bas sert à s'accroupir). Sinon : devant soi.
func get_aim_direction() -> Vector2:
	if Input.is_action_pressed("Up"):
		return Vector2.UP
	if Input.is_action_pressed("Down") and not is_on_floor():
		return Vector2.DOWN
	return Vector2(facing, 0)


## Le canon d'où sort la balle, selon la visée et la posture.
func get_muzzle() -> Marker2D:
	if _aim == Vector2.UP:
		return muzzle_up
	if _aim == Vector2.DOWN:
		return muzzle_down
	if state_machine.get_current_state_name() == "Crouch":
		return muzzle_crouch
	return muzzle


func shoot() -> void:
	_last_shot = 0.0
	_shoot_anim_timer = shoot_anim_time
	var bullet := BulletPool.get_bullet()
	if bullet:                # null = toutes les balles sont déjà en vol
		bullet.fire(get_muzzle().global_position, _aim.angle())
	_update_animation()       # la pose de tir apparaît dès cette frame


## On retourne aussi le canon quand le soldat change de côté.
func set_facing(direction: float) -> void:
	super(direction)
	for m: Marker2D in [muzzle, muzzle_up, muzzle_down, muzzle_crouch]:
		m.position.x = absf(m.position.x) * facing
#endregion

#region Animation
## Les états appellent play_animation("Run"), etc. On garde leur demande
## et on décide ici s'il faut plutôt afficher la version « qui tire ».
func play_animation(anim_name: String) -> void:
	_body_animation = anim_name
	_update_animation()


func _update_animation() -> void:
	var anim := _body_animation
	if _shoot_anim_timer > 0.0 and SHOOT_POSE.has(_body_animation):
		var shoot_anim: String = SHOOT_POSE[_body_animation] + "_Shoot" + _aim_suffix()
		if anim_player.has_animation(shoot_anim):
			anim = shoot_anim
	_play_synced(anim)


func _aim_suffix() -> String:
	if _aim == Vector2.UP:
		return "Up"
	if _aim == Vector2.DOWN:
		return "Down"
	return ""


## Change d'animation sans faire sauter les jambes : si l'ancienne et la
## nouvelle ont la même durée (Run et Run_Shoot), on reprend au même instant.
func _play_synced(anim: String) -> void:
	if anim_player.current_animation == anim or not anim_player.has_animation(anim):
		return
	var old := anim_player.current_animation
	if old == "":                 # rien ne joue encore (tout premier appel)
		anim_player.play(anim)
		return
	var pos := anim_player.current_animation_position
	anim_player.play(anim)
	if is_equal_approx(anim_player.get_animation(old).length, anim_player.get_animation(anim).length):
		anim_player.seek(pos, true)
#endregion


#region Caméra

func set_camera_limits(area: Rect2i) -> void:
	camera.limit_left = area.position.x
	camera.limit_top = area.position.y
	camera.limit_right = area.end.x
	camera.limit_bottom = area.end.y
#endregion
