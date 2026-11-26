extends Control
## Scène de fin, gagnante ou perdante selon GameState.last_game_won.
## Si le score entre dans le top 10 : saisie de 3 initiales façon borne d'arcade
## (haut / bas : lettre, gauche / droite : position, J ou Entrée : valider).
## Puis Redémarrer (nouvelle partie), Menu principal ou Quitter.

const MENU := "res://scenes/ui/menu_principal.tscn"
const LEVEL := "res://scenes/levels/niveau_1.tscn"

@onready var title: Label = $Titre
@onready var subtitle: Label = $SousTitre
@onready var bonus: Label = $Bonus
@onready var score: Label = $Score
@onready var record: Control = $Record
@onready var buttons: VBoxContainer = $Boutons

const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var _board: Leaderboard
var _letters: Array[int] = [0, 0, 0]
var _cursor: int = 0
var _entering: bool = false
var _time: float = 0.0


func _ready() -> void:
	Audio.play_music("victoire" if GameState.last_game_won else "defaite")
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

	_board = Leaderboard.load_board()
	if _board.qualifies(GameState.score):
		_entering = true
		buttons.hide()                      # pas de bouton sélectionné pendant la saisie
		record.show()
		_update_letters()
	else:
		record.hide()
		$Boutons/Redemarrer.grab_focus()


func _process(delta: float) -> void:
	if _entering:
		_time += delta
		_update_letters()                  # la lettre en cours clignote


func _update_letters() -> void:
	for i in 3:
		var letter: Label = record.get_node("Lettres/L%d" % (i + 1))
		letter.text = ALPHABET[_letters[i]]
		var current := i == _cursor and _entering
		letter.modulate = Color(1, 0.85, 0.3) if current else Color.WHITE
		letter.modulate.a = 0.35 if current and int(_time * 4.0) % 2 == 1 else 1.0


func _handle_entry(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("Up"):
		_letters[_cursor] = wrapi(_letters[_cursor] + 1, 0, ALPHABET.length())
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("Down"):
		_letters[_cursor] = wrapi(_letters[_cursor] - 1, 0, ALPHABET.length())
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("Right"):
		_cursor = mini(_cursor + 1, 2)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("Left"):
		_cursor = maxi(_cursor - 1, 0)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("Shoot") or event.is_action_pressed("Jump"):
		if _cursor < 2:
			_cursor += 1
		else:
			_confirm()
	else:
		return
	get_viewport().set_input_as_handled()
	if _entering:
		Audio.play_sfx("ui_deplacer", 0.0)
	_update_letters()


func _confirm() -> void:
	_entering = false
	Audio.play_sfx("ramassage", 0.0)
	var initials := ""
	for i in 3:
		initials += ALPHABET[_letters[i]]
	var rank := _board.add(initials, GameState.score, GameState.last_game_won)
	_board.save()
	record.get_node("Consigne").text = "%s : classé %d%s !" % [initials, rank, "er" if rank == 1 else "e"]
	record.get_node("Aide").hide()
	_update_letters()
	record.get_node("Lettres").hide()
	buttons.position.y = 128.0            # juste sous le message « classé Ne »
	buttons.show()
	$Boutons/Redemarrer.grab_focus()


func _restart() -> void:
	GameState.reset()
	get_tree().change_scene_to_file(LEVEL)


func _unhandled_input(event: InputEvent) -> void:
	if _entering:
		_handle_entry(event)
		return
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
