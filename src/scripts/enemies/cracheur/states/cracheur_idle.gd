class_name CracheurIdle
extends CracheurState
## Attend chez lui en flottant, jusqu'à ce que le joueur approche.

var _time: float = 0.0


func physics_update(delta: float) -> void:
	_time += delta
	var bob := Vector2(sin(_time * 1.3) * 10.0, sin(_time * 2.1) * 6.0)
	cracheur.apply_steering(cracheur.arrive(cracheur.home + bob), delta)

	var player := cracheur.get_player()
	if player and not player.is_dead \
			and absf(player.global_position.x - cracheur.global_position.x) < cracheur.activation_distance:
		cracheur.chasing = true
		Transitioned.emit(self, "Approach")
		return
