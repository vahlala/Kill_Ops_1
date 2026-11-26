extends CanvasLayer
## Menu de pause. L'action « Pause Play » (P ou Échap) fige tout le jeu
## avec get_tree().paused : chaque nœud en mode « Inherit » s'arrête.
## Ce menu est en mode « Always » : c'est lui qui continue de répondre.

const MENU := "res://scenes/ui/menu_principal.tscn"
const CONFIGURATION := preload("res://scenes/ui/configuration.tscn")

var _config: Control = null

@onready var panel: Control = $Panneau
@onready var buttons: VBoxContainer = $Panneau/Boutons


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	$Panneau/Boutons/Reprendre.pressed.connect(resume)
	$Panneau/Boutons/Configuration.pressed.connect(_open_configuration)
	$Panneau/Boutons/Menu.pressed.connect(_go_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if _config:
		return                                  # l'écran de configuration a la main
	if event.is_action_pressed("Pause Play"):
		get_viewport().set_input_as_handled()
		if panel.visible:
			resume()
		else:
			pause()
		return
	if not panel.visible:
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


func pause() -> void:
	get_tree().paused = true
	panel.show()
	$Panneau/Boutons/Reprendre.grab_focus()


func resume() -> void:
	get_tree().paused = false
	panel.hide()


func _open_configuration() -> void:
	panel.hide()
	_config = CONFIGURATION.instantiate()
	_config.embedded = true
	_config.closed.connect(_on_configuration_closed)
	add_child(_config)


func _on_configuration_closed() -> void:
	_config = null
	panel.show()
	$Panneau/Boutons/Configuration.grab_focus()


func _go_to_menu() -> void:
	get_tree().paused = false           # sinon le menu principal serait figé lui aussi
	get_tree().change_scene_to_file(MENU)
