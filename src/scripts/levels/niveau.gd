extends Node2D
## Script commun des niveaux.
## - place le joueur au marqueur « Depart » ;
## - limite la caméra à la zone peinte du TileMapLayer « Sol » ;
## - affiche PV / vies / score / arme (affichage provisoire en attendant le HUD) ;
## - F9 (action goto_end) : déverrouille l'arrivée et téléporte juste avant ;
## - barre de vie du boss (groupe « Boss ») ; sa mort déverrouille l'arrivée ;
## - affiche « MISSION ACCOMPLIE » quand l'arrivée est touchée ;
## - F2 (TEMPORAIRE, en attendant l'écran de configuration) : change la difficulté
##   et recommence le niveau.

@onready var player: Player = $Player
@onready var sol: TileMapLayer = $Sol
@onready var depart: Marker2D = $Depart
@onready var arrivee: Arrivee = $Arrivee
@onready var info: Label = $Interface/Info
@onready var message: Label = $Interface/Message
@onready var boss_bar: Control = get_node_or_null("Interface/BarreBoss")


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

	if boss_bar:
		boss_bar.hide()
	for boss in get_tree().get_nodes_in_group("Boss"):
		boss.fight_started.connect(_on_boss_fight_started.bind(boss))
		boss.health_changed.connect(_on_boss_health_changed)
		boss.died.connect(_on_boss_died)


func _update_info() -> void:
	var arme := "Mitrailleuse %d" % player.heavy_ammo if player.heavy_ammo > 0 else "Pistolet"
	info.text = "PV %d / %d   Vies %d   Score %d   %s   %s" % [
			player.hp, player.max_hp, GameState.lives, GameState.score, arme,
			GameState.get_difficulty_settings().name]


func _on_level_completed() -> void:
	message.text = "MISSION ACCOMPLIE !"
	message.show()


func _on_boss_fight_started(boss: GenericCharacter) -> void:
	if boss_bar:
		var gauge: ProgressBar = boss_bar.get_node("Jauge")
		gauge.max_value = boss.max_hp
		gauge.value = boss.hp
		boss_bar.show()


func _on_boss_health_changed(hp: int, _max_hp: int) -> void:
	if boss_bar:
		boss_bar.get_node("Jauge").value = hp


func _on_boss_died() -> void:
	if boss_bar:
		boss_bar.hide()
	arrivee.unlock()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		GameState.set_difficulty((GameState.difficulty + 1) % 3 as GameState.Difficulty)
		get_tree().reload_current_scene()
		return
	if event.is_action_pressed("goto_end"):
		arrivee.unlock()
		player.global_position = arrivee.global_position + Vector2(-48, -16)
		player.velocity = Vector2.ZERO
