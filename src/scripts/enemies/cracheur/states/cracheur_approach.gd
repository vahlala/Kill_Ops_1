class_name CracheurApproach
extends CracheurState
## Joueur loin : seek vers le point de tir.


func physics_update(delta: float) -> void:
	var player := cracheur.get_player()
	if player == null or player.is_dead:
		Transitioned.emit(self, "Idle")
		return
	cracheur.apply_steering(cracheur.seek(cracheur.firing_point(player)), delta)

	var d := cracheur.distance_to_player(player)
	if d < cracheur.flee_distance:
		Transitioned.emit(self, "Flee")
		return
	if d < cracheur.approach_distance:
		Transitioned.emit(self, "Position")
		return
