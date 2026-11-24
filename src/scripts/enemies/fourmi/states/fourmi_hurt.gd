class_name FourmiHurt
extends FourmiState
## Touchée par une balle : recule un peu et clignote, puis charge.

var _timer: float = 0.0


func enter() -> void:
	_timer = fourmi.hurt_time
	fourmi.play_animation("Hurt")
	fourmi.set_flash(true)
	fourmi.velocity.x = -fourmi.facing * 50.0


func exit() -> void:
	fourmi.set_flash(false)


func physics_update(delta: float) -> void:
	fourmi.velocity.x = move_toward(fourmi.velocity.x, 0.0, 300.0 * delta)
	fourmi.apply_gravity(delta)
	fourmi.move_and_slide()

	_timer -= delta
	if _timer <= 0.0:
		Transitioned.emit(self, "Charge")   # touchée : elle sait où est le joueur
