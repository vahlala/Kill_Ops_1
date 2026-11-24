class_name FourmiDead
extends FourmiState
## Morte : se retourne sur le dos, saute un peu, puis s'efface et disparaît.
## État final.


func enter() -> void:
	fourmi.play_animation("Dead")
	# On est souvent ici pendant un signal de collision (la balle) :
	# les changements de collision doivent attendre la fin de la frame.
	fourmi.set_deferred("collision_layer", 0)
	fourmi.hitbox.set_deferred("monitoring", false)
	fourmi.velocity = Vector2(-fourmi.facing * 40.0, -90.0)
	var tween := fourmi.create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(fourmi, "modulate:a", 0.0, 0.4)
	tween.tween_callback(fourmi.queue_free)


func physics_update(delta: float) -> void:
	fourmi.apply_gravity(delta)
	if fourmi.is_on_floor():
		fourmi.velocity.x = move_toward(fourmi.velocity.x, 0.0, 200.0 * delta)
	fourmi.move_and_slide()
