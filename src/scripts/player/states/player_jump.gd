class_name PlayerJump
extends PlayerState
## Phase montante du saut. Seul état qui appelle player.jump().


func enter() -> void:
	player.jump()
	Audio.play_sfx("saut")
	player.play_animation("Jump")


func physics_update(delta: float) -> void:
	player.handle_jump_cut()
	move_with_input(delta)

	# Sommet atteint, ou tête contre un plafond.
	if player.velocity.y >= 0.0:
		Transitioned.emit(self, "Fall")
		return
