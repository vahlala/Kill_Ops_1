class_name PlayerRun
extends PlayerState
## Course au sol.


func enter() -> void:
	player.play_animation("Run")


func physics_update(delta: float) -> void:
	move_with_input(delta)

	if not player.is_on_floor():
		Transitioned.emit(self, "Fall")     # le coyote time permet encore de sauter
		return
	if player.wants_to_jump() and player.can_jump():
		Transitioned.emit(self, "Jump")
		return
	if player.wants_to_crouch():
		Transitioned.emit(self, "Crouch")
		return
	if player.get_input_direction() == 0.0:
		Transitioned.emit(self, "Idle")     # la friction finit l'arrêt dans Idle
		return
