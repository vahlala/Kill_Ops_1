class_name Pickup
extends Area2D
## Objet à ramasser (cours 07C) : Area2D qui ne détecte que la couche Joueur.
## Une seule scène pour tous les objets : le type choisit l'icône et l'effet.

enum Kind { SOIN, MUNITIONS, MITRAILLEUSE }

## Région de chaque icône dans weapons.png
const ICONS := {
	Kind.SOIN: Rect2(177, 112, 14, 16),          # trousse de soin
	Kind.MUNITIONS: Rect2(17, 112, 14, 16),      # deux balles
	Kind.MITRAILLEUSE: Rect2(144, 80, 25, 16),   # mitrailleuse
}

@export var kind: Kind = Kind.SOIN:
	set(value):
		kind = value
		if is_node_ready():
			_update_icon()
@export var amount: int = 50        # PV soignés, ou balles données
@export var score: int = 100        # points gagnés en le ramassant

var _time: float = 0.0
var _taken: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_icon()
	_time = randf() * TAU            # les objets ne flottent pas tous en même temps


func _process(delta: float) -> void:
	_time += delta
	sprite.position.y = roundf(sin(_time * 3.0) * 2.0)   # flotte de ±2 px (pixels entiers)


func _update_icon() -> void:
	$Sprite2D.region_rect = ICONS[kind]


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	Audio.play_sfx("ramassage", 0.0)
	_apply(body)
	GameState.add_score(score)
	set_deferred("monitoring", false)
	# petite disparition : grossit et s'efface, puis est supprimé
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2(1.6, 1.6), 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)


func _apply(player: Player) -> void:
	match kind:
		Kind.SOIN:
			player.heal(amount)
		Kind.MUNITIONS:
			player.add_heavy_ammo(amount)
		Kind.MITRAILLEUSE:
			player.give_heavy_machine_gun(amount)
