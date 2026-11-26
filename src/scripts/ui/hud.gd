class_name HUD
extends CanvasLayer
## Interface de jeu : vies, PV, arme et munitions, score, difficulté.
## Rien n'est relu à chaque frame : chaque élément se met à jour quand
## le joueur ou GameState émet le signal correspondant.

const PISTOL_ICON := Rect2(80, 80, 28, 16)    # régions de weapons.png
const HEAVY_ICON := Rect2(144, 80, 25, 16)

@export var life_icon: Texture2D               # petite tête du soldat (AtlasTexture)

var _shown_score: int = 0

@onready var lives_box: HBoxContainer = $Haut/Vies
@onready var health_bar: GenericProgressBar = $Haut/PV/Jauge
@onready var weapon_icon: TextureRect = $Haut/Arme/Icone
@onready var ammo_label: Label = $Haut/Arme/Munitions
@onready var score_label: Label = $Haut/Score
@onready var difficulty_label: Label = $Haut/Difficulte


func _ready() -> void:
	# Le joueur est trouvé par son groupe ; il est prêt avant le HUD (placé après lui).
	var player := get_tree().get_first_node_in_group("Player") as Player
	if player:
		player.health_changed.connect(_on_health_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		_on_health_changed(player.hp, player.max_hp)
		_on_ammo_changed(player.heavy_ammo)
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.difficulty_changed.connect(_on_difficulty_changed)
	_on_lives_changed(GameState.lives)
	_shown_score = GameState.score
	_set_score_text(_shown_score)
	_on_difficulty_changed(GameState.difficulty)


func _on_health_changed(hp: int, max_hp: int) -> void:
	health_bar.update_value(hp, max_hp)


## Une petite tête par vie restante.
func _on_lives_changed(lives: int) -> void:
	for icon in lives_box.get_children():
		icon.queue_free()
	for i in lives:
		var icon := TextureRect.new()
		icon.texture = life_icon
		lives_box.add_child(icon)


func _on_ammo_changed(heavy_ammo: int) -> void:
	var atlas := weapon_icon.texture as AtlasTexture
	if heavy_ammo > 0:
		atlas.region = HEAVY_ICON
		ammo_label.text = str(heavy_ammo)
		ammo_label.add_theme_font_size_override("font_size", 8)
	else:
		atlas.region = PISTOL_ICON
		ammo_label.text = "∞"                  # le pistolet ne manque jamais de balles
		ammo_label.add_theme_font_size_override("font_size", 14)   # le symbole est petit dans la police


## Le score défile jusqu'à sa nouvelle valeur au lieu de sauter.
func _on_score_changed(score: int) -> void:
	var tween := create_tween()
	tween.tween_method(_set_score_text, _shown_score, score, 0.4)
	_shown_score = score


func _set_score_text(value: int) -> void:
	score_label.text = "SCORE %06d" % value


func _on_difficulty_changed(difficulty: GameState.Difficulty) -> void:
	difficulty_label.text = GameState.DIFFICULTY_SETTINGS[difficulty].name
