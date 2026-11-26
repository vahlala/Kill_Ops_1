class_name Arrivee
extends Area2D
## Point d'arrivée du niveau : le joueur qui le touche termine la mission.
## Verrouillé (invisible et inactif) tant que le boss n'est pas vaincu.

@export var locked: bool = false

var _reached: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = not locked


func unlock() -> void:
	locked = false
	show()
	for body in get_overlapping_bodies():   # le joueur est peut-être déjà dessus
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if locked:
		return
	if body is Player and not _reached:
		_reached = true
		GameState.complete_level()
