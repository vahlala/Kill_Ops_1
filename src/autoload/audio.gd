extends Node
## Autoload Audio : musique d'ambiance et effets sonores de tout le jeu.
##
## Musique : deux lecteurs en fondu enchaîné. Comme l'autoload n'est jamais
## détruit, la musique continue pendant les changements de scène. Si la scène
## suivante demande la même piste, rien ne change (aucune coupure).
## Pendant la pause, la musique baisse un peu au lieu de s'arrêter.
##
## Effets : une réserve (pool) de lecteurs réutilisés, comme le BulletPool.
## Les musiques vont sur le bus « Musique », les effets sur « Effets » :
## les curseurs de la configuration et Ctrl+M agissent donc sur tout.

const MUSIC := {
	"menu": preload("res://assets/audio/music/menu.ogg"),
	"jeu": preload("res://assets/audio/music/jeu.ogg"),
	"boss": preload("res://assets/audio/music/boss.ogg"),
	"victoire": preload("res://assets/audio/music/victoire.ogg"),
	"defaite": preload("res://assets/audio/music/defaite.ogg"),
}
## Courtes pistes jouées une seule fois ; ensuite on revient à la musique du menu.
const JINGLES := ["victoire", "defaite"]

const SFX := {
	"tir": preload("res://assets/audio/sfx/tir.wav"),
	"tir_lourd": preload("res://assets/audio/sfx/tir_lourd.wav"),
	"saut": preload("res://assets/audio/sfx/saut.wav"),
	"degat": preload("res://assets/audio/sfx/degat.wav"),
	"mort_joueur": preload("res://assets/audio/sfx/mort_joueur.wav"),
	"ramassage": preload("res://assets/audio/sfx/ramassage.wav"),
	"impact": preload("res://assets/audio/sfx/impact.wav"),
	"mort_insecte": preload("res://assets/audio/sfx/mort_insecte.wav"),
	"crachat": preload("res://assets/audio/sfx/crachat.wav"),
	"explosion": preload("res://assets/audio/sfx/explosion.wav"),
	"reine_cri": preload("res://assets/audio/sfx/reine_cri.wav"),
	"ui_deplacer": preload("res://assets/audio/sfx/ui_deplacer.wav"),
	"ui_valider": preload("res://assets/audio/sfx/ui_valider.wav"),
}

const SFX_PLAYERS := 16          # nombre de sons simultanés au maximum
const MIN_REPEAT := 0.035        # un même son n'est pas rejoué plus vite (mitrailleuse, impacts)
const PAUSE_DUCK_DB := -10.0     # baisse de la musique pendant la pause

@export var fade_time: float = 0.8

var current_music: String = ""

var _music: Array[AudioStreamPlayer] = []
var _active: int = 0                        # index du lecteur de musique en cours
var _fade: Tween
var _sfx: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _last_played: Dictionary = {}           # nom du son -> heure de la dernière lecture
var _duck: float = 0.0
var _last_focus: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS      # sons du menu pause, musique pendant la pause
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Musique"
		player.finished.connect(_on_music_finished.bind(player))
		add_child(player)
		_music.append(player)
	for i in SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "Effets"
		add_child(player)
		_sfx.append(player)
	# Les musiques d'ambiance tournent en boucle, les jingles non.
	for key in MUSIC:
		MUSIC[key].loop = not key in JINGLES
	# Sons d'interface pour TOUS les menus, sans toucher à leurs scripts :
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	# Baisse douce de la musique en pause, remontée à la reprise.
	var target := PAUSE_DUCK_DB if get_tree().paused else 0.0
	_duck = move_toward(_duck, target, 40.0 * delta)
	for player in _music:
		player.volume_db = player.get_meta("fade_db", 0.0) + _duck


#region Musique
## Change de musique avec un fondu enchaîné. Même piste qu'avant : on ne fait rien.
func play_music(key: String) -> void:
	if key == current_music or not MUSIC.has(key):
		return
	current_music = key
	var old := _music[_active]
	_active = 1 - _active
	var new := _music[_active]
	new.stream = MUSIC[key]
	new.set_meta("fade_db", -40.0)
	new.play()
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()
	_fade.tween_method(_set_fade.bind(new), -40.0, 0.0, fade_time)
	if old.playing:
		_fade.tween_method(_set_fade.bind(old), old.get_meta("fade_db", 0.0), -40.0, fade_time)
		_fade.chain().tween_callback(old.stop)


func stop_music() -> void:
	current_music = ""
	if _fade:
		_fade.kill()
	_fade = create_tween()
	var player := _music[_active]
	_fade.tween_method(_set_fade.bind(player), player.get_meta("fade_db", 0.0), -40.0, fade_time)
	_fade.tween_callback(player.stop)


func _set_fade(db: float, player: AudioStreamPlayer) -> void:
	player.set_meta("fade_db", db)


func _on_music_finished(player: AudioStreamPlayer) -> void:
	# Fin d'un jingle de victoire ou de défaite : retour à l'ambiance du menu.
	if player == _music[_active] and current_music in JINGLES:
		play_music("menu")
#endregion


#region Effets sonores
## Joue un effet. pitch_variation : petite variation aléatoire de hauteur pour
## que 30 tirs de suite ne sonnent pas tous exactement pareil.
func play_sfx(key: String, pitch_variation: float = 0.06, volume_db: float = 0.0) -> void:
	if not SFX.has(key):
		push_warning("Son inconnu : %s" % key)
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(key, -1.0) < MIN_REPEAT:
		return
	_last_played[key] = now
	var player := _get_free_player()
	player.stream = SFX[key]
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.volume_db = volume_db
	player.play()


## Un lecteur libre, sinon le plus ancien (on coupe le son le plus vieux).
func _get_free_player() -> AudioStreamPlayer:
	for i in SFX_PLAYERS:
		var player := _sfx[(_next_sfx + i) % SFX_PLAYERS]
		if not player.playing:
			_next_sfx = (_next_sfx + i + 1) % SFX_PLAYERS
			return player
	var oldest := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_PLAYERS
	return oldest
#endregion


#region Sons d'interface
func _on_focus_changed(control: Control) -> void:
	# Pas de « bip » pour le premier focus donné à l'ouverture d'un écran.
	if is_instance_valid(_last_focus) and _last_focus.is_inside_tree():
		play_sfx("ui_deplacer", 0.0)
	_last_focus = control


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play_sfx.bind("ui_valider", 0.0, 0.0))
#endregion
