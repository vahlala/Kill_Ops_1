class_name PlayerHit
extends PlayerState
## Touché : le recul s'applique, aucun contrôle pendant hit_stun_time.

var _timer: float = 0.0


func enter() -> void:
	_timer = player.hit_stun_time
	player.play_animation("Hit")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if player.is_on_floor():
		player.apply_horizontal_movement(0.0, delta)   # la friction freine le recul
	player.move_and_slide()

	_timer -= delta
	if _timer > 0.0:
		return
	if player.is_on_floor():
		go_to_ground_state()
	else:
		Transitioned.emit(self, "Fall")
