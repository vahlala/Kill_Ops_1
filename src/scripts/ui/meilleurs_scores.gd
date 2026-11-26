extends Control
## Écran des 10 meilleurs scores. Échap, J ou RETOUR : retour au menu.

const MENU := "res://scenes/ui/menu_principal.tscn"
const WIN_MARK := "VICTOIRE"

@onready var table: VBoxContainer = $Tableau


func _ready() -> void:
	var board := Leaderboard.load_board()
	for i in Leaderboard.SIZE:
		var row: HBoxContainer = table.get_child(i)
		if i < board.entries.size():
			var entry := board.entries[i]
			row.get_node("Initiales").text = entry.initials
			row.get_node("Score").text = "%06d" % entry.score
			row.get_node("Victoire").text = WIN_MARK if entry.won else ""
		else:
			row.get_node("Initiales").text = "---"
			row.get_node("Score").text = "------"
			row.get_node("Victoire").text = ""
	$Retour.pressed.connect(_back)
	$Retour.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("Shoot") or event.is_action_pressed("Jump"):
		get_viewport().set_input_as_handled()
		_back()


func _back() -> void:
	get_tree().change_scene_to_file(MENU)
