class_name CracheurDead
extends CracheurState
## Mort : tombe en tournoyant puis disparaît. État final.


func enter() -> void:
	cracheur.set_deferred("collision_layer", 0)
	cracheur.set_deferred("collision_mask", 0)
	cracheur.hitbox.set_deferred("monitoring", false)
	cracheur.velocity = Vector2(cracheur.velocity.x * 0.3, -60.0)
	var tween := cracheur.create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(cracheur, "modulate:a", 0.0, 0.3)
	tween.tween_callback(cracheur.queue_free)


func physics_update(delta: float) -> void:
	cracheur.velocity.y += 600.0 * delta
	cracheur.position += cracheur.velocity * delta
	cracheur.rotation += 10.0 * delta
