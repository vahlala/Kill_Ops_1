extends BaseState
## État de test : immobile. Passe à Move si on appuie sur gauche/droite.

func enter() -> void:
	character.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	character.apply_gravity(delta)
	character.velocity.x = move_toward(character.velocity.x, 0, character.move_speed)
	character.move_and_slide()

	if Input.get_axis("Left", "Right") != 0:
		Transitioned.emit(self, "move")
