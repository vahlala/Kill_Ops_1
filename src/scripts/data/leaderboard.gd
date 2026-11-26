class_name Leaderboard
extends Resource
## Tableau des 10 meilleurs scores : une Resource personnalisée, enregistrée
## avec ResourceSaver dans user:// (le dossier de données du joueur, qui
## survit aux redémarrages et existe aussi sur la borne).

const PATH := "user://meilleurs_scores.tres"
const SIZE := 10

@export var entries: Array[ScoreEntry] = []


## Charge le tableau sauvegardé, ou en crée un vide au premier lancement.
## duplicate(true) : on travaille sur une copie, pas sur la ressource en cache.
static func load_board() -> Leaderboard:
	if ResourceLoader.exists(PATH):
		var saved := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if saved is Leaderboard:
			return saved.duplicate(true)
	return Leaderboard.new()


## Ce score entre-t-il dans le top 10 ?
func qualifies(score: int) -> bool:
	return score > 0 and (entries.size() < SIZE or score > entries.back().score)


## Ajoute un score à sa place (ordre décroissant) et renvoie son rang (1 = premier),
## ou -1 s'il ne rentre pas dans le top 10.
func add(initials: String, score: int, won: bool) -> int:
	if not qualifies(score):
		return -1
	var entry := ScoreEntry.new()
	entry.initials = initials
	entry.score = score
	entry.won = won
	var index := entries.size()
	for i in entries.size():
		if score > entries[i].score:       # à égalité, l'ancien score reste devant
			index = i
			break
	entries.insert(index, entry)
	if entries.size() > SIZE:
		entries.resize(SIZE)
	return index + 1


func save() -> Error:
	return ResourceSaver.save(self, PATH)
