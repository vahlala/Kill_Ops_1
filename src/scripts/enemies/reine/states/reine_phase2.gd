class_name ReinePhase2
extends ReineState
## Phase 2 : invoque une nuée de 5 criquets toutes les 7 s (au plus 2 nuées
## en même temps) et crache une goutte de temps en temps.

var _summon_timer: float = 0.0
var _spit_timer: float = 0.0


func enter() -> void:
	reine.phase = 2
	reine.phase_changed.emit(2)
	_summon_timer = 0.5
	_spit_timer = 2.0


func physics_update(delta: float) -> void:
	reine.fly_to(reine.hover_point(170.0, 0.9), delta, 1.15)
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = 7.0
		if reine.get_tree().get_nodes_in_group("Essaim").size() < 2:
			reine.summon_swarm(5)
	_spit_timer -= delta
	if _spit_timer <= 0.0:
		_spit_timer = 2.5
		reine.spit_volley(1, 0.0)
