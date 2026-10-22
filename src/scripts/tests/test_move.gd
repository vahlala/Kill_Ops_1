extends BaseState
## État de test : se déplace. Revient à Idle quand on relâche.

func enter() -> void:
	character.modulate = Color(0.6, 1.0, 0.6)   # vert pâle pour voir le changement


func physics_update(delta: float) -> void:
	var direction := Input.get_axis("Left", "Right")
	character.apply_gravity(delta)
	character.velocity.x = direction * character.move_speed
	character.set_facing(direction)
	character.move_and_slide()

	if direction == 0:
		Transitioned.emit(self, "idle")
