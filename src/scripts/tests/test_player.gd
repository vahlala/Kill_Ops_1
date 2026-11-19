extends Node2D
## Terrain d'essai du soldat : sol, pente, plateforme, mur.
## Touches de test : H = 10 dégâts, K = mort, R = recharger la scène.
## En haut à gauche : PV, vies et état, mis à jour par les signaux.

@onready var player: Player = $Player
@onready var info: Label = $Interface/Info


func _ready() -> void:
	# x de 0 à 1600, y de -200 à 384 : la caméra ne sort pas de cette zone.
	player.set_camera_limits(Rect2i(0, -200, 1600, 584))

	# Les signaux préviennent l'affichage : il ne surveille rien lui-même.
	player.health_changed.connect(_on_info_changed.unbind(2))
	player.state_machine.state_changed.connect(_on_info_changed.unbind(2))
	GameState.lives_changed.connect(_on_info_changed.unbind(1))
	_on_info_changed()


func _on_info_changed() -> void:
	info.text = "PV %d / %d   Vies %d   %s" % [
			player.hp, player.max_hp, GameState.lives, player.state_machine.get_current_state_name()]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_H:
			player.take_damage(10)
		KEY_K:
			player.take_damage(player.max_hp)
		KEY_R:
			get_tree().reload_current_scene()
