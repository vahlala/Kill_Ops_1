class_name PlayerFall
extends PlayerState
## En l'air, en descente (ou après avoir quitté un rebord).


func enter() -> void:
	player.play_animation("Fall")


func physics_update(delta: float) -> void:
	move_with_input(delta)

	if player.is_on_floor():
		go_to_ground_state()
		return
	# Vrai seulement pendant le coyote time : pas de double saut possible.
	if player.wants_to_jump() and player.can_jump():
		Transitioned.emit(self, "Jump")
		return
