class_name Bullet
extends Area2D
## Balle du joueur : avance tout droit vers sa droite locale (transform.x).
## Disparaît en touchant le monde ou un ennemi, ou en sortant de l'écran.

@export var speed: float = 400.0   # px/s
@export var damage: int = 1

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func _on_screen_exited() -> void:
	queue_free()
