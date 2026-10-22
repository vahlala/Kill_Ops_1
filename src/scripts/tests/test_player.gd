extends Node2D
## Terrain d'essai du soldat : sol, pente, plateforme, mur.

@onready var player: Player = $Player


func _ready() -> void:
	# x de 0 à 1600, y de -200 à 384 : la caméra ne sort pas de cette zone.
	player.set_camera_limits(Rect2i(0, -200, 1600, 584))
