class_name PlayerCrouch
extends PlayerState
## Accroupi : hitbox réduite, avance lentement, ne peut pas sauter.


func enter() -> void:
	player.set_crouching(true)
	player.play_animation("Crouch")


func exit() -> void:
	player.set_crouching(false)


func physics_update(delta: float) -> void:
	move_with_input(delta, player.crouch_speed_factor)

	if not player.is_on_floor():
		Transitioned.emit(self, "Fall")
		return
	# On se relève seulement si la touche est relâchée ET qu'il y a de la place.
	if not player.wants_to_crouch() and player.can_stand_up():
		go_to_ground_state()
		return
