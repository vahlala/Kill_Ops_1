class_name FourmiPatrol
extends FourmiState
## Marche lentement, fait demi-tour au bord du vide ou devant un mur.


func enter() -> void:
	fourmi.play_animation("Walk")


func physics_update(delta: float) -> void:
	if fourmi.at_edge() or fourmi.at_wall():
		fourmi.turn_around()
	fourmi.move(fourmi.patrol_speed, delta)

	if fourmi.sees_player():
		Transitioned.emit(self, "Charge")
		return
