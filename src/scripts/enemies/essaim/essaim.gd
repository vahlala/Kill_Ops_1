class_name Essaim
extends Node2D
## Essaim de criquets : algorithme d'agrégation (boids, cours 05A).
## Crée ses criquets au démarrage, leur donne leurs voisins à chaque frame
## et porte tous les réglages (vitesses, rayons, poids) dans l'Inspecteur.
## Il attend sur place jusqu'à ce que le joueur approche, puis l'attaque.

@export var criquet_scene: PackedScene
@export var count: int = 10
@export var activation_distance: float = 250.0   # distance horizontale qui réveille l'essaim
@export var debug_draw: bool = false             # dessine les rayons et les vitesses

@export_group("Vitesses")
@export var top_speed: float = 130.0             # px/s (le soldat court à 120)
@export var top_steer: float = 260.0             # force de braquage max (px/s²)

@export_group("Rayons")
@export var radius_separation: float = 14.0
@export var radius_alignment: float = 32.0
@export var radius_cohesion: float = 48.0
@export var radius_flee: float = 28.0
@export var max_neighbors: int = 8

@export_group("Poids")
@export_range(0.0, 5.0, 0.1) var weight_separation: float = 1.8
@export_range(0.0, 5.0, 0.1) var weight_alignment: float = 1.0
@export_range(0.0, 5.0, 0.1) var weight_cohesion: float = 0.9
@export_range(0.0, 5.0, 0.1) var weight_seek: float = 1.1      # attraction vers le joueur
@export_range(0.0, 5.0, 0.1) var weight_flee: float = 1.2      # fuite des balles
@export_range(0.0, 5.0, 0.1) var weight_bounds: float = 2.0    # rester dans l'écran
@export_range(0.0, 5.0, 0.1) var weight_ground: float = 3.0    # ne pas descendre sous les pieds du joueur

var boids: Array[Criquet] = []
var chasing: bool = false


func _ready() -> void:
	add_to_group("Essaim")
	for i in count:
		var boid: Criquet = criquet_scene.instantiate()
		boid.swarm = self
		boid.position = Vector2(randf_range(-24.0, 24.0), randf_range(-16.0, 16.0))
		add_child(boid)
		boid.died.connect(_on_boid_died.bind(boid))
		boids.append(boid)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("Player") as Player
	if not chasing and player and absf(player.global_position.x - global_position.x) < activation_distance:
		chasing = true

	# Cible : le torse du joueur s'il est vivant, sinon on tourne sur place.
	var target := global_position
	var floor_y := INF                 # hauteur à ne pas dépasser vers le bas
	var hunting := chasing and player != null and not player.is_dead
	if hunting:
		target = player.global_position + Vector2(0, 2)
		floor_y = player.global_position.y + 14.0   # environ les genoux du soldat

	var view := _camera_rect()
	for boid in boids:
		boid.flock(_neighbors(boid), target, view, floor_y, hunting, delta)
	if debug_draw:
		queue_redraw()


## Voisins proches (dans le plus grand rayon), au plus max_neighbors.
func _neighbors(boid: Criquet) -> Array[Criquet]:
	var result: Array[Criquet] = []
	var r2 := radius_cohesion * radius_cohesion
	for other in boids:
		if other != boid and boid.global_position.distance_squared_to(other.global_position) < r2:
			result.append(other)
			if result.size() >= max_neighbors:
				break
	return result


## Zone visible de la caméra (en coordonnées du monde), un peu rétrécie.
func _camera_rect() -> Rect2:
	var vp := get_viewport()
	var top_left := vp.get_canvas_transform().affine_inverse().origin
	return Rect2(top_left, vp.get_visible_rect().size).grow(-12.0)


func _on_boid_died(boid: Criquet) -> void:
	boids.erase(boid)
	if boids.is_empty():
		queue_free.call_deferred()      # nuée détruite : l'essaim disparaît aussi


func _draw() -> void:
	if not debug_draw:
		return
	for boid in boids:
		var p := to_local(boid.global_position)
		draw_arc(p, radius_separation, 0.0, TAU, 16, Color(1, 0.3, 0.3, 0.6))
		draw_arc(p, radius_cohesion, 0.0, TAU, 24, Color(0.3, 0.6, 1, 0.3))
		draw_line(p, p + boid.velocity * 0.25, Color(1, 1, 0.3))
