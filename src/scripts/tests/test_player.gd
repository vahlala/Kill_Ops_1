extends Node2D
## Terrain d'essai du soldat : sol, pente, plateforme, mur.
## Touches de test : H = 10 dégâts, K = mort, R = recharger la scène.

@onready var player: Player = $Player


func _ready() -> void:
	# x de 0 à 1600, y de -200 à 384 : la caméra ne sort pas de cette zone.
	player.set_camera_limits(Rect2i(0, -200, 1600, 584))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_H:
			player.take_damage(10)
			print("PV : %d / %d" % [player.hp, player.max_hp])
		KEY_K:
			player.take_damage(player.max_hp)
		KEY_R:
			get_tree().reload_current_scene()
