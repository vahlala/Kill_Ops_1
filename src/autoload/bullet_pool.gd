extends Node
## Pool de balles (patron Object Pool), chargé en autoload sous le nom BulletPool.
## Toutes les balles sont créées UNE fois au démarrage, puis réutilisées :
## aucune instanciation ni destruction pendant la partie.

const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/bullet.tscn")

@export var pool_size: int = 30

var _available: Array[Bullet] = []     # balles au repos, prêtes à partir


func _ready() -> void:
	for i in pool_size:
		var bullet: Bullet = BULLET_SCENE.instantiate()
		add_child(bullet)
		bullet.finished.connect(release)
		bullet.deactivate()
		_available.append(bullet)


## Donne une balle au repos, ou null si elles sont toutes en vol.
func get_bullet() -> Bullet:
	if _available.is_empty():
		return null
	return _available.pop_back()


## Remet une balle dans le pool. Ignorée si elle y est déjà (pas de doublon).
func release(bullet: Bullet) -> void:
	if bullet in _available:
		return
	bullet.deactivate()
	_available.append(bullet)


## Pour le debug : combien de balles sont prêtes.
func get_available_count() -> int:
	return _available.size()
