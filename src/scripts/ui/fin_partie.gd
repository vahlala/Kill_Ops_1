extends Control
## Scène de fin, gagnante ou perdante selon GameState.last_game_won.
## Redémarrer (nouvelle partie), Menu principal ou Quitter, au clavier ou à la manette.

const MENU := "res://scenes/ui/menu_principal.tscn"
const LEVEL := "res://scenes/levels/niveau_1.tscn"

@onready var title: Label = $Titre
@onready var subtitle: Label = $SousTitre
@onready var bonus: Label = $Bonus
@onready var score: Label = $Score


func _ready() -> void:
	if GameState.last_game_won:
		title.text = "MISSION ACCOMPLIE !"
		title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		subtitle.text = "La Reine est vaincue. La Terre est sauvée !"
		bonus.text = "Bonus vies : %d x %d = %d" % [GameState.lives, GameState.bonus_per_life, GameState.lives_bonus]
	else:
		title.text = "GAME OVER"
		title.add_theme_color_override("font_color", Color(0.95, 0.25, 0.2))
		subtitle.text = "Les insectes ont envahi la Terre..."
		bonus.hide()
	score.text = "SCORE FINAL  %06d" % GameState.score
	$Boutons/Redemarrer.pressed.connect(_restart)
	$Boutons/Menu.pressed.connect(get_tree().change_scene_to_file.bind(MENU))
	$Boutons/Quitter.pressed.connect(get_tree().quit)
	$Boutons/Redemarrer.grab_focus()


func _restart() -> void:
	GameState.reset()
	get_tree().change_scene_to_file(LEVEL)


func _unhandled_input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	if event.is_action_pressed("Shoot") or event.is_action_pressed("Jump"):
		get_viewport().set_input_as_handled()
		if focused is BaseButton:
			focused.pressed.emit()
	elif event.is_action_pressed("Down"):
		get_viewport().set_input_as_handled()
		var next := focused.find_next_valid_focus()
		if next: next.grab_focus()
	elif event.is_action_pressed("Up"):
		get_viewport().set_input_as_handled()
		var previous := focused.find_prev_valid_focus()
		if previous: previous.grab_focus()
