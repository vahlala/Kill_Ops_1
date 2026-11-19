class_name Arrivee
extends Area2D
## Point d'arrivée du niveau : le joueur qui le touche termine la mission.

var _reached: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not _reached:
		_reached = true
		GameState.complete_level()
