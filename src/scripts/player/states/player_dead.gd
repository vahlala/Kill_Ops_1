class_name PlayerDead
extends PlayerState
## Mort : plus aucun contrôle, le corps retombe et glisse jusqu'à l'arrêt.


func enter() -> void:
	player.play_animation("Dead")
	player.set_collision_layer_value(2, false)   # les ennemis ne le touchent plus


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if player.is_on_floor():
		player.apply_horizontal_movement(0.0, delta)
	player.move_and_slide()
