class_name Fourmi
extends GenericCharacter
## Fourmi soldat : patrouille sans tomber des plateformes (FloorDetector),
## fait demi-tour devant un mur (WallDetector), charge le joueur quand elle
## le voit (PlayerDetector) et le blesse au contact (Hitbox).

@export_group("Déplacement")
@export var patrol_speed: float = 30.0
@export var charge_speed: float = 90.0
@export_range(-1, 1, 2) var start_facing: int = -1   # -1 : regarde vers la gauche

@export_group("Combat")
@export var contact_damage: int = 20
@export var contact_knockback: Vector2 = Vector2(140.0, -120.0)
@export var hurt_time: float = 0.2          # durée de l'étourdissement quand on la touche
@export var give_up_distance: float = 220.0 # abandonne la charge si le joueur est trop loin
@export var score_value: int = 100

@onready var state_machine: StateMachine = $StateMachine
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var wall_detector: RayCast2D = $WallDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	super()
	set_facing(start_facing)


## Indépendant de l'état : la fourmi blesse le joueur dès qu'ils se touchent.
func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	for body in hitbox.get_overlapping_bodies():
		if body is Player:
			var side := signf(body.global_position.x - global_position.x)
			if side == 0.0:
				side = facing
			body.take_damage(contact_damage, Vector2(contact_knockback.x * side, contact_knockback.y))


## Retourne aussi les rayons pour qu'ils regardent toujours devant.
func set_facing(direction: float) -> void:
	super(direction)
	for ray: RayCast2D in [floor_detector, wall_detector, player_detector]:
		ray.position.x = absf(ray.position.x) * facing
		ray.target_position.x = absf(ray.target_position.x) * facing


func turn_around() -> void:
	set_facing(-facing)


## Plus de sol devant les pattes : il faut s'arrêter ou faire demi-tour.
func at_edge() -> bool:
	return is_on_floor() and not floor_detector.is_colliding()


func at_wall() -> bool:
	return wall_detector.is_colliding()


## Le rayon s'arrête sur le premier obstacle : un mur cache le joueur.
func sees_player() -> bool:
	return player_detector.is_colliding() and player_detector.get_collider() is Player


## Le joueur est trouvé par son groupe (jamais par un chemin de nœud).
func get_player() -> Player:
	return get_tree().get_first_node_in_group("Player") as Player


func move(speed: float, delta: float) -> void:
	velocity.x = speed * facing
	apply_gravity(delta)
	move_and_slide()


func set_flash(on: bool) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("flash_modifier", 0.8 if on else 0.0)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	super(amount, knockback)
	if is_dead:
		GameState.add_score(score_value)
		state_machine.transition_to("Dead")
	else:
		state_machine.transition_to("Hurt")
