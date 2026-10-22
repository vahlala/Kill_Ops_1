class_name GenericCharacter
extends CharacterBody2D

signal health_changed(hp: int, max_hp: int)
signal died

@export var max_hp: int = 100
@export var move_speed: float = 120.0
@export var max_fall_speed: float = 600.0

var hp: int
var facing: int = 1          
var is_dead: bool = false

var anim_player: AnimationPlayer
var animated_sprite: AnimatedSprite2D
var sprite: Sprite2D


func _ready() -> void:
	hp = max_hp
	anim_player = get_node_or_null("AnimationPlayer")
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	sprite = get_node_or_null("Sprite2D")


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity.y = minf(velocity.y, max_fall_speed)


func set_facing(direction: float) -> void:
	if direction > 0:
		facing = 1
	elif direction < 0:
		facing = -1
	else:
		return
	if animated_sprite:
		animated_sprite.flip_h = facing < 0
	if sprite:
		sprite.flip_h = facing < 0


## Joue une animation, que le personnage utilise AnimatedSprite2D ou AnimationPlayer.
func play_animation(anim_name: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames \
			and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)
	elif anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)


## Inflige des dégâts avec un recul optionnel.
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	hp = max(hp - amount, 0)
	velocity += knockback
	health_changed.emit(hp, max_hp)
	if hp == 0:
		is_dead = true
		died.emit()
