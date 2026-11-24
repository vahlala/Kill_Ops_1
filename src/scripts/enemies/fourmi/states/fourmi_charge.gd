class_name FourmiCharge
extends FourmiState
## Fonce vers le joueur. S'arrête au bord du vide (ne tombe jamais).
## Abandonne si le joueur est mort ou trop loin.


func enter() -> void:
	fourmi.play_animation("Charge")


func physics_update(delta: float) -> void:
	var player := fourmi.get_player()
	if player == null or player.is_dead \
			or fourmi.global_position.distance_to(player.global_position) > fourmi.give_up_distance:
		Transitioned.emit(self, "Patrol")
		return

	# Se tourne vers le joueur, même s'il a sauté par-dessus.
	fourmi.set_facing(signf(player.global_position.x - fourmi.global_position.x))

	var speed := fourmi.charge_speed
	if fourmi.at_edge() or fourmi.at_wall():
		speed = 0.0                 # attend au bord plutôt que de tomber
	fourmi.move(speed, delta)
