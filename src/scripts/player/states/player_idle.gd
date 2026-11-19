class_name PlayerIdle
extends PlayerState
## Debout, immobile.


func enter() -> void:
	player.play_animation("Idle")


func physics_update(delta: float) -> void:
	move_with_input(delta)

	if not player.is_on_floor():
		Transitioned.emit(self, "Fall")
		return
	if player.wants_to_jump() and player.can_jump():
		Transitioned.emit(self, "Jump")
		return
	if player.wants_to_crouch():
		Transitioned.emit(self, "Crouch")
		return
	if player.get_input_direction() != 0.0:
		Transitioned.emit(self, "Run")
		return
