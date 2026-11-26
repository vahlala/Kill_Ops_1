class_name CracheurFlee
extends CracheurState
## Joueur trop près : flee, jusqu'à être de nouveau à distance de sécurité.


func physics_update(delta: float) -> void:
	var player := cracheur.get_player()
	if player == null or player.is_dead:
		Transitioned.emit(self, "Idle")
		return
	cracheur.apply_steering(cracheur.flee(cracheur.player_chest(player)), delta)

	if cracheur.distance_to_player(player) > cracheur.safe_distance:
		Transitioned.emit(self, "Position")
		return
