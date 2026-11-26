class_name ReineTransition
extends ReineState
## Entre deux phases : s'immobilise, tremble et clignote 1,2 s (invincible),
## puis passe à la phase qui correspond à ses PV.

var _timer: float = 0.0


func enter() -> void:
	_timer = 1.2
	reine.velocity = Vector2.ZERO


func exit() -> void:
	reine.set_flash(false)
	reine.sprite.position = Vector2.ZERO


func physics_update(delta: float) -> void:
	_timer -= delta
	reine.set_flash(int(_timer * 15.0) % 2 == 0)
	reine.sprite.position = Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0))   # tremblement
	if _timer <= 0.0:
		Transitioned.emit(self, "Phase%d" % reine.phase_for_hp())
