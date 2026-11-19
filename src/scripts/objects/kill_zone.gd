class_name KillZone
extends Area2D
## Zone mortelle réutilisable (cours 07D) : le joueur qui y entre meurt,
## même s'il est invincible. La forme se donne sur chaque instance
## (ex. : WorldBoundaryShape2D sous le bas de la caméra pour les trous).


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.kill()
