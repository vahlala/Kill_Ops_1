extends Control
## Écran de configuration, utilisable sans souris :
## haut / bas (flèches ou W / S) : choisir un réglage ;
## gauche / droite (flèches ou A / D) : le modifier ; Entrée : cocher la sourdine ;
## Échap ou RETOUR : revenir au menu. Chaque changement est sauvegardé tout de suite.
## Peut aussi s'ouvrir par-dessus le menu de pause (embedded = true) : RETOUR
## ferme alors l'écran au lieu de changer de scène.

signal closed

const MENU := "res://scenes/ui/menu_principal.tscn"

var embedded: bool = false

@onready var music: HSlider = $Reglages/Musique/Curseur
@onready var sfx: HSlider = $Reglages/Effets/Curseur
@onready var mute: CheckButton = $Reglages/Sourdine/Case
@onready var difficulty: HSlider = $Reglages/Difficulte/Curseur
@onready var back_button: Button = $Retour


func _ready() -> void:
	if embedded:
		$FondJungle.hide()                    # on laisse voir le jeu figé, assombri
	# Valeurs actuelles d'abord, connexions ensuite (sinon on sauvegarderait pour rien).
	music.value = Settings.music_volume * 100.0
	sfx.value = Settings.sfx_volume * 100.0
	mute.button_pressed = Settings.muted
	difficulty.value = GameState.difficulty
	music.value_changed.connect(func(v: float) -> void: Settings.set_music_volume(v / 100.0); _refresh())
	sfx.value_changed.connect(func(v: float) -> void: Settings.set_sfx_volume(v / 100.0); _refresh())
	mute.toggled.connect(func(on: bool) -> void: Settings.set_muted(on); _refresh())
	difficulty.value_changed.connect(func(v: float) -> void: Settings.set_difficulty(int(v) as GameState.Difficulty); _refresh())
	back_button.pressed.connect(_back)
	Settings.changed.connect(_sync)           # ex. : Ctrl+M pendant que l'écran est ouvert
	# Le réglage sélectionné a son nom en jaune.
	for control: Control in [music, sfx, mute, difficulty]:
		var name_label: Label = control.get_parent().get_node("Nom")
		control.focus_entered.connect(name_label.add_theme_color_override.bind("font_color", Color(1, 0.85, 0.3)))
		control.focus_exited.connect(name_label.remove_theme_color_override.bind("font_color"))
	music.grab_focus()
	_refresh()


## Remet la case de sourdine d'accord avec Settings, sans redéclencher de sauvegarde.
func _sync() -> void:
	mute.set_pressed_no_signal(Settings.muted)
	_refresh()


func _refresh() -> void:
	$Reglages/Musique/Valeur.text = "%d %%" % music.value
	$Reglages/Effets/Valeur.text = "%d %%" % sfx.value
	$Reglages/Sourdine/Valeur.text = "OUI" if mute.button_pressed else "NON"
	$Reglages/Difficulte/Valeur.text = GameState.DIFFICULTY_SETTINGS[int(difficulty.value)].name


func _input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()
	# W / S / A / D : les flèches sont déjà gérées par l'interface de Godot.
	elif event.is_action_pressed("Down") and not event.is_action_pressed("ui_down") and focused:
		var next := focused.find_next_valid_focus()
		if next: next.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Up") and not event.is_action_pressed("ui_up") and focused:
		var previous := focused.find_prev_valid_focus()
		if previous: previous.grab_focus()
		get_viewport().set_input_as_handled()
	elif focused is HSlider and not event.is_action_pressed("ui_left") and not event.is_action_pressed("ui_right"):
		if event.is_action_pressed("Left"):
			focused.value -= focused.step
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("Right"):
			focused.value += focused.step
			get_viewport().set_input_as_handled()


func _back() -> void:
	if embedded:
		closed.emit()
		queue_free()
	else:
		get_tree().change_scene_to_file(MENU)
