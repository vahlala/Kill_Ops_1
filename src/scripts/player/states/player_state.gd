class_name PlayerState
extends BaseState
## Base commune des états du soldat : accès typé au joueur + aiguillages partagés.

var player: Player:
	get:
		return character as Player


## Choisit l'état « au sol » qui correspond aux touches enfoncées.
## Toujours suivi d'un return dans l'appelant.
func go_to_ground_state() -> void:
	if player.wants_to_crouch():
		Transitioned.emit(self, "Crouch")
	elif player.get_input_direction() != 0.0:
		Transitioned.emit(self, "Run")
	else:
		Transitioned.emit(self, "Idle")


## Mouvement standard (sol ou air) : gravité, contrôle horizontal, orientation.
func move_with_input(delta: float, speed_factor: float = 1.0) -> void:
	var direction := player.get_input_direction()
	player.apply_gravity(delta)
	player.apply_horizontal_movement(direction, delta, speed_factor)
	player.set_facing(direction)
	player.move_and_slide()
