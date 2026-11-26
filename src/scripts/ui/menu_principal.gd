extends Control
## Menu principal, utilisable sans souris :
## - flèches / manette (actions ui_*) : la navigation par focus de Godot ;
## - W / S (actions Up / Down) : déplacent aussi la sélection ;
## - Entrée, ou Tirer / Sauter (pratique sur la borne) : valident.
## Un bouton dont l'écran n'existe pas encore est grisé automatiquement.

const SCENES := {
	"Jouer": "res://scenes/levels/niveau_1.tscn",
	"Instructions": "res://scenes/ui/instructions.tscn",
	"Configuration": "res://scenes/ui/configuration.tscn",
	"Scores": "res://scenes/ui/meilleurs_scores.tscn",
}

@onready var buttons: VBoxContainer = $Boutons
@onready var title: Label = $Titre

var _time: float = 0.0


func _ready() -> void:
	Audio.play_music("menu")
	for button: Button in buttons.get_children():
		button.pressed.connect(_on_button_pressed.bind(button.name))
		if SCENES.has(button.name) and not ResourceLoader.exists(SCENES[button.name]):
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE   # la sélection saute ce bouton
	$Boutons/Jouer.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	title.position.y = 22.0 + roundf(sin(_time * 2.0) * 2.0)   # le titre flotte doucement


func _on_button_pressed(button_name: String) -> void:
	match button_name:
		"Jouer":
			GameState.reset()                     # nouvelle partie : vies et score à zéro
			get_tree().change_scene_to_file(SCENES["Jouer"])
		"Quitter":
			get_tree().quit()
		_:
			get_tree().change_scene_to_file(SCENES[button_name])


func _unhandled_input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	if event.is_action_pressed("Shoot") or event.is_action_pressed("Jump"):
		if focused is BaseButton and not focused.disabled:
			get_viewport().set_input_as_handled()   # AVANT : le bouton peut changer de scène
			focused.pressed.emit()
	elif event.is_action_pressed("Down"):
		var next := focused.find_next_valid_focus()
		if next:
			next.grab_focus()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Up"):
		var previous := focused.find_prev_valid_focus()
		if previous:
			previous.grab_focus()
			get_viewport().set_input_as_handled()
