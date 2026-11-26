class_name ReinePhase1
extends ReineState
## Phase 1 : balaie l'arène et crache une salve de 3 gouttes toutes les 1,8 s.

var _spit_timer: float = 0.0


func enter() -> void:
	reine.phase = 1
	reine.phase_changed.emit(1)
	_spit_timer = 1.0


func physics_update(delta: float) -> void:
	reine.fly_to(reine.hover_point(150.0, 0.7), delta)
	_spit_timer -= delta
	if _spit_timer <= 0.0:
		_spit_timer = 1.8
		reine.spit_volley(3, 18.0)
