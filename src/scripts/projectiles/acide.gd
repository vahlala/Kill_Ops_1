class_name Acide
extends Area2D
## Crachat d'acide du cracheur : part en ligne droite vers le joueur,
## retombe un peu (gravité légère) et éclate sur le joueur ou le décor.

@export var damage: int = 15
@export var knockback: Vector2 = Vector2(100.0, -100.0)
@export var gravity_force: float = 60.0     # px/s² : courbe légère
@export var lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)


func launch(from: Vector2, initial_velocity: Vector2) -> void:
	global_position = from
	velocity = initial_velocity


func _physics_process(delta: float) -> void:
	velocity.y += gravity_force * delta
	position += velocity * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage, Vector2(knockback.x * signf(velocity.x), knockback.y))
	queue_free()
