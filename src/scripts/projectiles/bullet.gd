class_name Bullet
extends Area2D
## Balle du joueur : avance tout droit vers sa droite locale (transform.x).
## Elle n'est jamais détruite : quand elle touche quelque chose ou sort de
## l'écran, elle émet `finished` et le BulletPool la remet au repos.

signal finished(bullet: Bullet)

@export var speed: float = 400.0   # px/s
@export var damage: int = 1
@export var lifetime: float = 2.0  # filet de sécurité : retour au pool après 2 s quoi qu'il arrive

var _active: bool = false
var _age: float = 0.0

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta
	_age += delta
	if _age >= lifetime:
		finished.emit(self)


## Sort la balle du pool et la lance depuis `pos`, orientée selon `angle`.
func fire(pos: Vector2, angle: float) -> void:
	global_position = pos
	rotation = angle
	_age = 0.0
	_active = true
	show()
	set_physics_process(true)
	set_deferred("monitoring", true)


## Met la balle au repos : invisible, immobile, sans collision.
func deactivate() -> void:
	_active = false
	hide()
	set_physics_process(false)
	set_deferred("monitoring", false)


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	finished.emit(self)


func _on_screen_exited() -> void:
	if _active:
		finished.emit(self)
