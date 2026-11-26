class_name Criquet
extends GenericCharacter
## Un criquet de l'essaim : un « boid » (cours 05A).
## L'Essaim lui donne ses voisins et ses réglages ; lui calcule ses forces
## de braquage, les additionne avec leurs poids et se déplace.

@export var contact_damage: int = 10
@export var contact_knockback: Vector2 = Vector2(80.0, -80.0)
@export var score_value: int = 50

var swarm: Essaim          # réglages partagés : vitesses, rayons, poids

@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	super()
	velocity = Vector2.from_angle(randf() * TAU) * 30.0   # chacun part dans sa direction
	play_animation("Fly")


func _physics_process(delta: float) -> void:
	if is_dead:
		_fall(delta)
		return
	for body in hitbox.get_overlapping_bodies():
		if body is Player:
			var side := signf(body.global_position.x - global_position.x)
			body.take_damage(contact_damage, Vector2(contact_knockback.x * side, contact_knockback.y))


## Appelé par l'Essaim à chaque frame physique.
func flock(neighbors: Array[Criquet], target: Vector2, view: Rect2, floor_y: float, chasing: bool, delta: float) -> void:
	var acceleration := separation(neighbors) * swarm.weight_separation \
			+ alignment(neighbors) * swarm.weight_alignment \
			+ cohesion(neighbors) * swarm.weight_cohesion \
			+ seek(target) * swarm.weight_seek \
			+ flee_bullets() * swarm.weight_flee
	if chasing:
		acceleration += stay_in_view(view) * swarm.weight_bounds
		acceleration += stay_above(floor_y) * swarm.weight_ground

	velocity = (velocity + acceleration * delta).limit_length(swarm.top_speed)
	global_position += velocity * delta
	if absf(velocity.x) > 5.0:
		sprite.flip_h = velocity.x < 0.0


#region Forces de braquage (toutes limitées à top_steer)
## Braquage vers une cible : vitesse désirée - vitesse actuelle.
func seek(target: Vector2) -> Vector2:
	return steer_toward(target - global_position)


## Braquage pour aller dans une direction à pleine vitesse.
func steer_toward(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	var desired := direction.normalized() * swarm.top_speed
	return (desired - velocity).limit_length(swarm.top_steer)


## Séparation : s'éloigner des voisins trop proches (plus ils sont près, plus on fuit).
func separation(neighbors: Array[Criquet]) -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for other in neighbors:
		var d := global_position.distance_to(other.global_position)
		if d > 0.0 and d < swarm.radius_separation:
			sum += (global_position - other.global_position).normalized() / d
			count += 1
	if count == 0:
		return Vector2.ZERO
	return steer_toward(sum / count)


## Alignement : voler dans la même direction que les voisins.
func alignment(neighbors: Array[Criquet]) -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for other in neighbors:
		if global_position.distance_to(other.global_position) < swarm.radius_alignment:
			sum += other.velocity
			count += 1
	if count == 0:
		return Vector2.ZERO
	return steer_toward(sum / count)


## Cohésion : se rapprocher du centre des voisins.
func cohesion(neighbors: Array[Criquet]) -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for other in neighbors:
		if global_position.distance_to(other.global_position) < swarm.radius_cohesion:
			sum += other.global_position
			count += 1
	if count == 0:
		return Vector2.ZERO
	return seek(sum / count)


## Fuite des balles : comme la séparation, mais avec les balles en vol.
func flee_bullets() -> Vector2:
	var sum := Vector2.ZERO
	for bullet in BulletPool.get_children():
		if not bullet.visible:          # balle au repos dans le pool
			continue
		var d := global_position.distance_to(bullet.global_position)
		if d > 0.0 and d < swarm.radius_flee:
			sum += (global_position - bullet.global_position).normalized() / d
	return steer_toward(sum)


## Limites : revenir dans la zone visible de la caméra si on en sort.
func stay_in_view(view: Rect2) -> Vector2:
	if view.has_point(global_position):
		return Vector2.ZERO
	var inside := global_position.clamp(view.position, view.end)
	return steer_toward(inside - global_position)


## Sol : les criquets traversent les tuiles, cette force les garde
## au-dessus des genoux du joueur pour qu'ils restent visibles et touchables.
func stay_above(floor_y: float) -> Vector2:
	if global_position.y <= floor_y:
		return Vector2.ZERO
	return steer_toward(Vector2.UP)
#endregion


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	super(amount, knockback)
	if is_dead:
		GameState.add_score(score_value)
		set_deferred("collision_layer", 0)          # souvent appelé pendant le signal de la balle
		hitbox.set_deferred("monitoring", false)
		velocity = Vector2(velocity.x * 0.3, -60.0)
		var tween := create_tween()
		tween.tween_interval(0.4)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)


## Mort : tombe en tournoyant.
func _fall(delta: float) -> void:
	velocity.y += 600.0 * delta
	global_position += velocity * delta
	rotation += 10.0 * delta
