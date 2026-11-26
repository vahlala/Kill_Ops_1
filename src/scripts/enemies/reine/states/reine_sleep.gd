class_name ReineSleep
extends ReineState
## Avant le combat : flotte au fond de l'arène (invincible) jusqu'à ce que
## le joueur y entre.

var _home: Vector2


func enter() -> void:
	_home = reine.global_position


func physics_update(delta: float) -> void:
	reine.fly_to(_home + Vector2(0, sin(reine.time * 2.0) * 6.0), delta, 0.5)
	var player := reine.get_player()
	if player and not player.is_dead and player.global_position.x > reine.arena.position.x + 64.0:
		reine.wake()
		Transitioned.emit(self, "Phase1")
		return
