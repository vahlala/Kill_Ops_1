extends Node2D
## Script commun des niveaux.
## - place le joueur au marqueur « Depart » ;
## - limite la caméra à la zone peinte du TileMapLayer « Sol » ;
## - affiche PV / vies / score / arme (affichage provisoire en attendant le HUD) ;
## - F9 (action goto_end) : téléporte juste avant l'arrivée ;
## - affiche « MISSION ACCOMPLIE » quand l'arrivée est touchée.

@onready var player: Player = $Player
@onready var sol: TileMapLayer = $Sol
@onready var depart: Marker2D = $Depart
@onready var arrivee: Arrivee = $Arrivee
@onready var info: Label = $Interface/Info
@onready var message: Label = $Interface/Message


func _ready() -> void:
	player.global_position = depart.global_position

	var cell := sol.tile_set.tile_size
	var used := sol.get_used_rect()
	var area := Rect2i(used.position * cell, used.size * cell)
	area = area.grow_side(SIDE_TOP, 160)      # du ciel au-dessus des plus hauts murs
	area = area.grow_side(SIDE_BOTTOM, -16)   # cache la rangée d'herbe sous le sol
	player.set_camera_limits(area)

	player.health_changed.connect(_update_info.unbind(2))
	GameState.lives_changed.connect(_update_info.unbind(1))
	GameState.score_changed.connect(_update_info.unbind(1))
	player.ammo_changed.connect(_update_info.unbind(1))
	GameState.level_completed.connect(_on_level_completed)
	_update_info()
	message.hide()


func _update_info() -> void:
	var arme := "Mitrailleuse %d" % player.heavy_ammo if player.heavy_ammo > 0 else "Pistolet"
	info.text = "PV %d / %d   Vies %d   Score %d   %s" % [
			player.hp, player.max_hp, GameState.lives, GameState.score, arme]


func _on_level_completed() -> void:
	message.text = "MISSION ACCOMPLIE !"
	message.show()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("goto_end"):
		player.global_position = arrivee.global_position + Vector2(-48, -16)
		player.velocity = Vector2.ZERO
