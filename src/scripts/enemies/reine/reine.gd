class_name Reine
extends GenericCharacter
## Boss : la Reine insecte. Machine à états par phases (patron État) :
## c'est la proportion de PV restants qui décide de la phase.
##   Phase 1 (100 % -> 67 %) : vole au-dessus de l'arène et crache des salves d'acide.
##   Phase 2 (67 % -> 34 %)  : invoque des nuées de criquets.
##   Phase 3 (< 34 %)        : enragée, crache plus et fonce en piqué sur le joueur.
## Entre deux phases, un état Transition la rend invincible un instant.

signal fight_started
signal phase_changed(phase: int)

@export var acid_scene: PackedScene
@export var essaim_scene: PackedScene
@export var arena: Rect2 = Rect2(2464, 96, 736, 288)   # zone de combat, caméra verrouillée dessus

@export_group("Vol")
@export var max_speed: float = 80.0
@export var max_force: float = 200.0
@export var slow_radius: float = 50.0
@export var hover_y: float = 222.0                    # altitude de vol (le haut de l'écran est à ~168)

@export_group("Attaques")
@export var contact_damage: int = 20
@export var spit_speed: float = 140.0
@export var score_value: int = 5000

var phase: int = 0
var time: float = 0.0
var _flash_timer: float = 0.0
var _arena_wall: StaticBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var mouth: Marker2D = $Mouth
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	super()
	add_to_group("Boss")          # le niveau trouve le boss par ce groupe (barre de vie)
	play_animation("Fly")


func _physics_process(delta: float) -> void:
	time += delta
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			set_flash(false)
	if is_dead:
		return
	for body in hitbox.get_overlapping_bodies():
		if body is Player:
			body.take_damage(contact_damage, Vector2(120.0 * signf(body.global_position.x - global_position.x), -120.0))


func get_player() -> Player:
	return get_tree().get_first_node_in_group("Player") as Player


## La phase découle des PV : c'est ce qui pilote les transitions.
func phase_for_hp() -> int:
	var ratio := float(hp) / float(max_hp)
	if ratio > 0.67:
		return 1
	if ratio > 0.34:
		return 2
	return 3


## Point de vol qui balaie l'arène de gauche à droite.
func hover_point(amplitude: float, speed: float) -> Vector2:
	return Vector2(arena.get_center().x + sin(time * speed) * amplitude, hover_y)


## Arrive (cours 05) : va vers la cible en ralentissant à l'approche.
func fly_to(target: Vector2, delta: float, speed_factor: float = 1.0) -> void:
	var offset := target - global_position
	var distance := offset.length()
	var top := max_speed * speed_factor
	var desired := Vector2.ZERO
	if distance > 1.0:
		desired = offset / distance * top * minf(distance / slow_radius, 1.0)
	velocity = (velocity + (desired - velocity).limit_length(max_force * speed_factor) * delta).limit_length(top)
	move_and_slide()
	var player := get_player()
	if player:
		set_facing(signf(player.global_position.x - global_position.x))


## Début du combat : verrouille la caméra sur l'arène et ferme l'arène à gauche.
func wake() -> void:
	var player := get_player()
	if player:
		player.set_camera_limits(Rect2i(arena))
	# Mur fin et haut au bord gauche de l'arène. Surtout PAS un WorldBoundaryShape2D :
	# c'est un demi-plan infini qui éjecterait tous les corps situés à gauche
	# (les fourmis du niveau se retrouveraient téléportées dans l'arène).
	_arena_wall = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(16, arena.size.y + 200)
	shape.shape = box
	_arena_wall.add_child(shape)
	_arena_wall.position = Vector2(arena.position.x - 8, arena.get_center().y)
	get_parent().add_child(_arena_wall)
	fight_started.emit()


## Salve d'acide en éventail, centrée sur le joueur.
func spit_volley(count: int, spread_degrees: float) -> void:
	var player := get_player()
	if player == null or player.is_dead:
		return
	var aim := (player.global_position + Vector2(0, 2) - mouth.global_position).angle()
	for i in count:
		var offset := 0.0 if count == 1 else lerpf(-spread_degrees, spread_degrees, float(i) / (count - 1))
		var acid: Acide = acid_scene.instantiate()
		get_tree().current_scene.add_child(acid)
		acid.launch(mouth.global_position, Vector2.from_angle(aim + deg_to_rad(offset)) * spit_speed)


## Invoque une petite nuée qui attaque tout de suite.
func summon_swarm(count: int) -> void:
	var swarm: Essaim = essaim_scene.instantiate()
	swarm.count = count
	swarm.activation_distance = 100000.0
	swarm.position = global_position + Vector2(0, 24)
	get_tree().current_scene.add_child(swarm)


func set_flash(on: bool) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("flash_modifier", 0.8 if on else 0.0)


func set_facing(direction: float) -> void:
	super(direction)
	mouth.position.x = absf(mouth.position.x) * facing


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	var state := state_machine.get_current_state_name()
	if is_dead or state == "Sleep" or state == "Transition":
		return                                   # invincible avant le combat et entre deux phases
	super(amount, Vector2.ZERO)                  # une reine ne recule pas
	set_flash(true)
	_flash_timer = 0.08
	if is_dead:
		GameState.add_score(score_value)
		state_machine.transition_to("Dead")
	elif phase_for_hp() != phase:
		state_machine.transition_to("Transition")


func remove_arena_wall() -> void:
	if is_instance_valid(_arena_wall):
		_arena_wall.queue_free()
