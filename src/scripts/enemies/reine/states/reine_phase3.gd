class_name ReinePhase3
extends ReineState
## Phase 3 (enragée, teintée de rouge) : alterne 2,5 s de vol avec salves de
## 5 gouttes, puis un piqué sur la position du joueur, puis remonte.

enum Step { HOVER, DIVE, CLIMB }

var _step: Step = Step.HOVER
var _timer: float = 0.0
var _spit_timer: float = 0.0
var _dive_target: Vector2


func enter() -> void:
	reine.phase = 3
	reine.phase_changed.emit(3)
	reine.sprite.self_modulate = Color(1.0, 0.6, 0.6)
	_start(Step.HOVER, 2.5)
	_spit_timer = 0.8


func _start(step: Step, duration: float) -> void:
	_step = step
	_timer = duration


func physics_update(delta: float) -> void:
	_timer -= delta
	match _step:
		Step.HOVER:
			reine.fly_to(reine.hover_point(170.0, 1.1), delta, 1.3)
			_spit_timer -= delta
			if _spit_timer <= 0.0:
				_spit_timer = 1.4
				reine.spit_volley(5, 15.0)
			if _timer <= 0.0:
				var player := reine.get_player()
				if player and not player.is_dead:
					_dive_target = player.global_position + Vector2(0, -6)
					_start(Step.DIVE, 1.0)
				else:
					_start(Step.HOVER, 2.5)
		Step.DIVE:
			reine.fly_to(_dive_target, delta, 2.8)
			if _timer <= 0.0 or reine.global_position.distance_to(_dive_target) < 10.0:
				_start(Step.CLIMB, 1.2)
		Step.CLIMB:
			reine.fly_to(reine.hover_point(170.0, 1.1), delta, 1.6)
			if _timer <= 0.0:
				_start(Step.HOVER, 2.5)
