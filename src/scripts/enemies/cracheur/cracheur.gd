class_name Cracheur
extends GenericCharacter
## Insecte cracheur : agent autonome (comportements de braquage, cours 05).
## Son comportement change selon la distance au joueur (un état par cas) :
##   loin -> Approach : seek vers un point de tir
##   bonne distance -> Position : arrive sur ce point et crache de l'acide
##   trop près -> Flee : s'enfuit
## Dans tous les états, il esquive les balles qui foncent vers lui.

@export var acid_scene: PackedScene

@export_group("Braquage")
@export var max_speed: float = 90.0         # px/s
@export var max_force: float = 220.0        # braquage max (px/s²)
@export var slow_radius: float = 60.0       # arrive : commence à freiner à cette distance

@export_group("Distances")
@export var activation_distance: float = 260.0   # distance horizontale qui le réveille
@export var keep_distance: float = 110.0         # écart horizontal voulu avec le joueur
@export var hover_height: float = 55.0           # hauteur voulue au-dessus du joueur
@export var flee_distance: float = 60.0          # plus près : il s'enfuit
@export var safe_distance: float = 110.0         # assez loin : il arrête de fuir
@export var approach_distance: float = 190.0     # plus loin : il se rapproche

@export_group("Poids des forces de sécurité")
@export_range(0.0, 5.0, 0.1) var weight_dodge: float = 2.5
@export_range(0.0, 5.0, 0.1) var weight_bounds: float = 2.0
@export_range(0.0, 5.0, 0.1) var weight_ground: float = 3.0

@export_group("Combat")
@export var spit_interval: float = 1.6
@export var spit_speed: float = 150.0
@export var dodge_radius: float = 60.0
@export var contact_damage: int = 10
@export var score_value: int = 200

var home: Vector2
var chasing: bool = false
var _spit_timer: float = 0.0
var _flash_timer: float = 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var mouth: Marker2D = $Mouth
@onready var sight: RayCast2D = $Sight
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	super()
	home = global_position
	_spit_timer = spit_interval
	play_animation("Fly")


func _physics_process(delta: float) -> void:
	_spit_timer = maxf(_spit_timer - delta, 0.0)
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_set_flash(false)
	if is_dead:
		return
	for body in hitbox.get_overlapping_bodies():
		if body is Player:
			body.take_damage(contact_damage, Vector2(80.0 * signf(body.global_position.x - global_position.x), -80.0))


func get_player() -> Player:
	return get_tree().get_first_node_in_group("Player") as Player


func player_chest(player: Player) -> Vector2:
	return player.global_position + Vector2(0, 2)


func distance_to_player(player: Player) -> float:
	return global_position.distance_to(player_chest(player))


## Point de tir : à keep_distance du joueur, du côté où il se trouve déjà, et au-dessus.
func firing_point(player: Player) -> Vector2:
	var side := signf(global_position.x - player.global_position.x)
	if side == 0.0:
		side = 1.0
	return player.global_position + Vector2(side * keep_distance, -hover_height)


#region Comportements de braquage
## Seek : aller vers la cible à pleine vitesse.
func seek(target: Vector2) -> Vector2:
	return _steer((target - global_position).normalized() * max_speed)


## Flee : le contraire de seek, s'éloigner à pleine vitesse.
func flee(target: Vector2) -> Vector2:
	return _steer((global_position - target).normalized() * max_speed)


## Arrive : comme seek, mais ralentit en approchant pour s'arrêter pile sur la cible.
func arrive(target: Vector2) -> Vector2:
	var offset := target - global_position
	var distance := offset.length()
	if distance < 1.0:
		return _steer(Vector2.ZERO)
	var speed := max_speed * minf(distance / slow_radius, 1.0)
	return _steer(offset / distance * speed)


## Esquive : si une balle fonce vers lui, il s'écarte perpendiculairement à sa trajectoire.
func dodge_bullets() -> Vector2:
	var force := Vector2.ZERO
	for bullet in BulletPool.get_children():
		if not bullet.visible:
			continue
		var to_me: Vector2 = global_position - bullet.global_position
		if to_me.length() > dodge_radius:
			continue
		var heading: Vector2 = bullet.transform.x                # direction de la balle
		if heading.dot(to_me.normalized()) < 0.6:                 # elle ne vient pas vers lui
			continue
		var side := heading.orthogonal()
		if side.dot(to_me) < 0.0:
			side = -side                                          # s'écarter du bon côté
		force += _steer(side * max_speed)
	return force


## Désirée - actuelle, limitée à max_force (la base de tous les comportements).
func _steer(desired: Vector2) -> Vector2:
	return (desired - velocity).limit_length(max_force)
#endregion


## Appelé par les états : ajoute les forces de sécurité, puis déplace l'agent.
func apply_steering(force: Vector2, delta: float) -> void:
	force += dodge_bullets() * weight_dodge
	var player := get_player()
	if chasing and player and not player.is_dead:
		force += _stay_in_view() * weight_bounds
		if global_position.y > player.global_position.y - 6.0:      # trop bas : remonter
			force += _steer(Vector2.UP * max_speed) * weight_ground
		set_facing(signf(player.global_position.x - global_position.x))   # regarde le joueur
	velocity = (velocity + force * delta).limit_length(max_speed)
	move_and_slide()


func _stay_in_view() -> Vector2:
	var vp := get_viewport()
	var view := Rect2(vp.get_canvas_transform().affine_inverse().origin, vp.get_visible_rect().size).grow(-16.0)
	if view.has_point(global_position):
		return Vector2.ZERO
	return seek(global_position.clamp(view.position, view.end))


## Peut cracher : délai écoulé et rien entre sa bouche et le joueur.
func can_spit(player: Player) -> bool:
	if _spit_timer > 0.0:
		return false
	sight.target_position = sight.to_local(player_chest(player))
	sight.force_raycast_update()
	return not sight.is_colliding()


func spit(player: Player) -> void:
	_spit_timer = spit_interval
	Audio.play_sfx("crachat")
	var acid: Acide = acid_scene.instantiate()
	get_tree().current_scene.add_child(acid)
	var direction := (player_chest(player) - mouth.global_position).normalized()
	acid.launch(mouth.global_position, direction * spit_speed)


func set_facing(direction: float) -> void:
	super(direction)
	mouth.position.x = absf(mouth.position.x) * facing


func _set_flash(on: bool) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("flash_modifier", 0.8 if on else 0.0)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	super(amount, knockback)
	_set_flash(true)
	_flash_timer = 0.1
	if is_dead:
		Audio.play_sfx("mort_insecte", 0.15)
		GameState.add_score(score_value)
		state_machine.transition_to("Dead")
