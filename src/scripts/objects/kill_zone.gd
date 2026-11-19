class_name KillZone
extends Area2D
## Zone mortelle réutilisable (cours 07D) : le joueur qui y entre meurt,


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.kill()
