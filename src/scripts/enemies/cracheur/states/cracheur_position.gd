class_name CracheurPosition
extends CracheurState
## Bonne distance : arrive sur le point de tir (s'y arrête en douceur) et crache.


func physics_update(delta: float) -> void:
	var player := cracheur.get_player()
	if player == null or player.is_dead:
		Transitioned.emit(self, "Idle")
		return
	cracheur.apply_steering(cracheur.arrive(cracheur.firing_point(player)), delta)
	if cracheur.can_spit(player):
		cracheur.spit(player)

	var d := cracheur.distance_to_player(player)
	if d < cracheur.flee_distance:
		Transitioned.emit(self, "Flee")
		return
	if d > cracheur.approach_distance + 40.0:      # marge : évite d'alterner sans arrêt
		Transitioned.emit(self, "Approach")
		return
