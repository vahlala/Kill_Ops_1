extends Node
## Réglages du joueur (autoload Settings) : volume de la musique, volume des
## effets, sourdine et difficulté. Enregistrés dans user://settings.cfg à
## chaque changement et rechargés au démarrage du jeu.
## Ctrl+M (action Mute) coupe ou rétablit le son partout, même en pause.

signal changed

const PATH := "user://settings.cfg"
const MUSIC_BUS := "Musique"
const SFX_BUS := "Effets"

var music_volume: float = 0.8     # 0 à 1 (linéaire, comme le curseur)
var sfx_volume: float = 0.8
var muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # Ctrl+M marche aussi quand le jeu est en pause
	load_settings()
	apply()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Mute"):
		toggle_mute()


## Applique les volumes aux bus audio. Les bus travaillent en décibels :
## linear_to_db convertit 0..1 en dB (1 -> 0 dB, 0.5 -> environ -6 dB).
func apply() -> void:
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(SFX_BUS, sfx_volume)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(linear))
	AudioServer.set_bus_mute(index, linear <= 0.0)      # linear_to_db(0) = -infini : on coupe plutôt


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_changed()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_changed()


func set_muted(value: bool) -> void:
	muted = value
	_changed()


func toggle_mute() -> void:
	set_muted(not muted)


func set_difficulty(value: GameState.Difficulty) -> void:
	GameState.set_difficulty(value)
	_changed()


func _changed() -> void:
	apply()
	save_settings()
	changed.emit()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "musique", music_volume)
	config.set_value("audio", "effets", sfx_volume)
	config.set_value("audio", "sourdine", muted)
	config.set_value("jeu", "difficulte", GameState.difficulty)
	config.save(PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return                          # premier lancement : on garde les valeurs par défaut
	music_volume = config.get_value("audio", "musique", music_volume)
	sfx_volume = config.get_value("audio", "effets", sfx_volume)
	muted = config.get_value("audio", "sourdine", muted)
	GameState.set_difficulty(config.get_value("jeu", "difficulte", GameState.difficulty))
