class_name ReineDead
extends ReineState
## Vaincue : clignote, tombe lentement en tournoyant, puis disparaît.
## L'arène se rouvre ; le niveau écoute le signal `died` pour la suite.


func enter() -> void:
	reine.set_deferred("collision_layer", 0)
	reine.hitbox.set_deferred("monitoring", false)
	reine.remove_arena_wall()
	reine.velocity = Vector2(0, -30)
	var tween := reine.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(reine, "modulate:a", 0.0, 0.8)
	tween.tween_callback(reine.queue_free)


func physics_update(delta: float) -> void:
	reine.set_flash(int(reine.time * 12.0) % 2 == 0)
	reine.velocity.y += 150.0 * delta
	reine.position += reine.velocity * delta
	reine.rotation += 2.0 * delta
