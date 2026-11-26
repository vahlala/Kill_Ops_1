extends Control
## Écran d'instructions en 3 pages : but du jeu et contrôles, ennemis, objets.
## ← / → (ou A / D) changent de page ; Retour, Échap ou J reviennent au menu.
## Les touches affichées sont lues dans l'Input Map : elles restent justes
## même si on change les contrôles dans les paramètres du projet.

const MENU := "res://scenes/ui/menu_principal.tscn"

## [action(s), description]
const CONTROLS := [
	[["Left", "Right"], "Se déplacer"],
	[["Up"], "Viser vers le haut"],
	[["Down"], "S'accroupir / viser vers le bas (en l'air)"],
	[["Jump"], "Sauter"],
	[["Shoot"], "Tirer (maintenir pour une rafale)"],
]

## [texture, région, nom, description]
const ENEMIES := [
	["res://assets/sprites/enemies/fourmi.png", Rect2(0, 0, 48, 24), "Fourmi soldat",
		"Patrouille et charge dès qu'elle te voit. 3 balles."],
	["res://assets/sprites/enemies/criquet.png", Rect2(0, 0, 20, 14), "Essaim de criquets",
		"Nuée rapide qui fond sur toi et esquive les tirs. 1 balle chacun."],
	["res://assets/sprites/enemies/cracheur.png", Rect2(0, 0, 28, 20), "Guêpe cracheuse",
		"Garde ses distances et crache de l'acide. Saute pour l'éviter."],
	["res://assets/sprites/enemies/reine.png", Rect2(0, 0, 64, 48), "La Reine",
		"Boss final en 3 phases : acide, nuées, puis piqués. Vise vers le haut !"],
]

const ITEMS := [
	[Rect2(177, 112, 14, 16), "Trousse de soin", "Rend 50 PV."],
	[Rect2(144, 80, 25, 16), "Mitrailleuse", "Tir presque deux fois plus rapide, 120 balles."],
	[Rect2(17, 112, 14, 16), "Munitions", "+60 balles de mitrailleuse."],
]

var _page: int = 0
var _pages: Array[Control] = []

@onready var holder: Control = $Pages
@onready var page_label: Label = $Navigation/Page
@onready var back_button: Button = $Navigation/Retour


func _ready() -> void:
	_pages = [_build_goal_page(), _build_enemies_page(), _build_items_page()]
	for page in _pages:
		holder.add_child(page)
	back_button.pressed.connect(_back)
	back_button.grab_focus()
	_show_page(0)


func _input(event: InputEvent) -> void:
	# _input passe AVANT l'interface : les flèches gauche/droite changent de page
	# au lieu de déplacer la sélection.
	if event.is_action_pressed("ui_left") or event.is_action_pressed("Left"):
		_show_page(_page - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("Right"):
		_show_page(_page + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("Shoot"):
		get_viewport().set_input_as_handled()
		_back()


func _show_page(index: int) -> void:
	_page = wrapi(index, 0, _pages.size())
	for i in _pages.size():
		_pages[i].visible = i == _page
	page_label.text = "<  %d / %d  >" % [_page + 1, _pages.size()]


func _back() -> void:
	get_tree().change_scene_to_file(MENU)


#region Construction des pages
func _build_goal_page() -> Control:
	var page := _page_root("MISSION")
	var goal := _text("Des insectes géants envahissent la Terre. Traverse la jungle, élimine les insectes, ramasse armes et soins, puis abats la Reine pour sauver la planète.", Vector2(0, 14), Vector2(320, 30), 8, true)
	page.add_child(goal)
	page.add_child(_text("CONTRÔLES", Vector2(0, 50), Vector2(320, 10), 8, false, Color(1, 0.85, 0.3)))
	var y := 62.0
	for c in CONTROLS:
		var keys := []
		for action in c[0]:
			keys.append(_key_name(action))
		page.add_child(_text(" / ".join(keys), Vector2(10, y), Vector2(90, 10), 8, false, Color(0.7, 1, 0.7)))
		page.add_child(_text(c[1], Vector2(105, y), Vector2(215, 10), 8))
		y += 11.0
	return page


func _build_enemies_page() -> Control:
	var page := _page_root("LES INSECTES")
	var y := 14.0
	for e in ENEMIES:
		var icon := _icon(load(e[0]), e[1], Vector2(0, y), Vector2(40, 24))
		page.add_child(icon)
		page.add_child(_text(e[2], Vector2(46, y), Vector2(270, 10), 8, false, Color(1, 0.85, 0.3)))
		page.add_child(_text(e[3], Vector2(46, y + 9), Vector2(274, 18), 8, true))
		y += 30.0
	return page


func _build_items_page() -> Control:
	var page := _page_root("OBJETS")
	var weapons: Texture2D = load("res://assets/sprites/weapons/weapons.png")
	var y := 18.0
	for item in ITEMS:
		page.add_child(_icon(weapons, item[0], Vector2(4, y), item[0].size))
		page.add_child(_text(item[1], Vector2(46, y), Vector2(270, 10), 8, false, Color(1, 0.85, 0.3)))
		page.add_child(_text(item[2], Vector2(46, y + 9), Vector2(274, 10), 8))
		y += 30.0
	page.add_child(_text("Chaque objet rapporte 100 points. La mitrailleuse est perdue si tu meurs.", Vector2(0, y + 4), Vector2(320, 20), 8, true, Color(0.8, 0.85, 0.8)))
	return page


func _page_root(title: String) -> Control:
	var page := Control.new()
	page.position = Vector2(32, 34)
	page.size = Vector2(320, 150)
	page.add_child(_text(title, Vector2(0, 0), Vector2(320, 12), 8, false, Color(1, 0.85, 0.3)))
	return page


func _text(content: String, pos: Vector2, size: Vector2, font_size: int, wrap := false, color := Color(0.92, 0.95, 0.92)) -> Label:
	var label := Label.new()
	label.text = content
	# Les options AVANT la taille : sinon Godot ramène la taille à son minimum.
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(size.x, 0)
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	return label


func _icon(texture: Texture2D, region: Rect2, pos: Vector2, size: Vector2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var rect := TextureRect.new()
	rect.texture = atlas
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE        # avant la taille (voir _text)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.position = pos
	rect.size = size
	return rect


## Nom de la première touche clavier associée à une action de l'Input Map.
func _key_name(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			return OS.get_keycode_string(code)
	return "?"
#endregion
