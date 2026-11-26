extends Node
## État global de la partie (autoload GameState) : vies, score et difficulté.
## Il survit aux rechargements de scène, contrairement au joueur.

signal lives_changed(lives: int)
signal score_changed(score: int)
signal game_over
signal level_completed
signal difficulty_changed(difficulty: Difficulty)

enum Difficulty { FACILE, NORMAL, DIFFICILE }

## Effet de chaque difficulté sur les vagues : nombre et vitesse des ennemis.
const DIFFICULTY_SETTINGS := {
	Difficulty.FACILE: {"name": "Facile", "count": 0.6, "speed": 0.8},
	Difficulty.NORMAL: {"name": "Normal", "count": 1.0, "speed": 1.0},
	Difficulty.DIFFICILE: {"name": "Difficile", "count": 1.5, "speed": 1.25},
}

const END_SCENE := "res://scenes/ui/fin_partie.tscn"

@export var starting_lives: int = 3
@export var respawn_delay: float = 2.0   # le temps de voir l'animation de mort
@export var victory_delay: float = 2.5   # le temps de lire « MISSION ACCOMPLIE »
@export var bonus_per_life: int = 1000   # bonus de fin pour chaque vie restante

var lives: int = 0
var score: int = 0
var difficulty: Difficulty = Difficulty.NORMAL   # n'est PAS remise à zéro par reset()
var last_game_won: bool = false                  # lu par la scène de fin
var lives_bonus: int = 0
var _just_respawned: bool = false
var _level_done: bool = false                    # arrivée touchée : plus de mort possible


func _ready() -> void:
	reset()


## Nouvelle partie : vies et score remis à leur valeur de départ.
func reset() -> void:
	lives = starting_lives
	score = 0
	lives_bonus = 0
	_level_done = false
	lives_changed.emit(lives)
	score_changed.emit(score)


func get_difficulty_settings() -> Dictionary:
	return DIFFICULTY_SETTINGS[difficulty]


func set_difficulty(value: Difficulty) -> void:
	difficulty = value
	difficulty_changed.emit(difficulty)


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


## Branché sur le signal `died` du joueur.
func on_player_died() -> void:
	if _level_done:
		return
	lives -= 1
	lives_changed.emit(lives)
	# false : le délai s'arrête pendant la pause (sinon le niveau se rechargerait
	# en pleine pause et le jeu resterait figé).
	await get_tree().create_timer(respawn_delay, false).timeout
	if lives > 0:
		_just_respawned = true
		get_tree().reload_current_scene()
	else:
		game_over.emit()
		end_game(false)


## Appelé par l'arrivée du niveau : on laisse lire le message, puis fin gagnante.
func complete_level() -> void:
	if _level_done:
		return
	_level_done = true
	level_completed.emit()
	await get_tree().create_timer(victory_delay, false).timeout
	end_game(true)


## Fin de partie : bonus de vies en cas de victoire, puis scène de fin.
func end_game(won: bool) -> void:
	last_game_won = won
	lives_bonus = lives * bonus_per_life if won else 0
	if lives_bonus > 0:
		add_score(lives_bonus)
	get_tree().paused = false
	get_tree().change_scene_to_file(END_SCENE)


## Vrai une seule fois juste après une réapparition (le joueur clignote alors).
func consume_respawn() -> bool:
	var respawned := _just_respawned
	_just_respawned = false
	return respawned
