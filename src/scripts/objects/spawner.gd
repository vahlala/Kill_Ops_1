class_name Spawner
extends Marker2D
## Générateur de vagues : quand le joueur arrive à trigger_distance (horizontale),
## fait apparaître `waves` vagues de `count` ennemis, espacées de wave_interval.
## La difficulté (GameState) multiplie le nombre d'ennemis et leur vitesse.

## Propriétés de vitesse connues des ennemis (multipliées par la difficulté).
const SPEED_PROPERTIES := ["patrol_speed", "charge_speed", "max_speed", "top_speed"]

@export var enemy_scene: PackedScene
@export var count: int = 2                      # ennemis par vague, en Normal
@export var waves: int = 1
@export var wave_interval: float = 3.0
@export var trigger_distance: float = 220.0     # un peu plus qu'un demi-écran : apparition hors champ
@export var spacing: Vector2 = Vector2(40, 0)   # écart entre les ennemis d'une même vague

var _triggered: bool = false
var _waves_left: int = 0
var _timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not _triggered:
		var player := get_tree().get_first_node_in_group("Player") as Node2D
		if player and absf(player.global_position.x - global_position.x) < trigger_distance:
			_triggered = true
			_waves_left = waves
		return
	if _waves_left <= 0:
		set_physics_process(false)          # travail terminé
		return
	_timer -= delta
	if _timer <= 0.0:
		spawn_wave()
		_waves_left -= 1
		_timer = wave_interval


func spawn_wave() -> void:
	var settings := GameState.get_difficulty_settings()
	var n := count
	var is_swarm := false
	var probe := enemy_scene.instantiate()
	if probe is Essaim:
		is_swarm = true                 # pour un essaim, c'est le nombre de criquets qui varie
	probe.free()
	if not is_swarm:
		n = maxi(1, roundi(count * settings.count))
	for i in n:
		var enemy: Node2D = enemy_scene.instantiate()
		enemy.position = position + spacing * (i - (n - 1) / 2.0)
		for prop in SPEED_PROPERTIES:
			if prop in enemy:
				enemy.set(prop, enemy.get(prop) * settings.speed)
		if is_swarm:
			enemy.count = maxi(1, roundi(enemy.count * settings.count))
		get_parent().add_child(enemy)
