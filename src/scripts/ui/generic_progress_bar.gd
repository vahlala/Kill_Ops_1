class_name GenericProgressBar
extends ProgressBar
## Barre de progression réutilisable (cours c09b) : on lui donne une valeur
## et un maximum, elle se met à jour et change de couleur selon le niveau.

@export var color_high: Color = Color(0.3, 0.85, 0.3)     # plus de la moitié
@export var color_mid: Color = Color(0.95, 0.8, 0.2)      # entre le quart et la moitié
@export var color_low: Color = Color(0.9, 0.2, 0.15)      # moins d'un quart

var _fill: StyleBoxFlat


func _ready() -> void:
	show_percentage = false
	# Un ProgressBar garde une hauteur minimale calculée d'après sa police,
	# même sans pourcentage : une police minuscule permet une barre fine.
	add_theme_font_size_override("font_size", 1)
	_fill = StyleBoxFlat.new()
	add_theme_stylebox_override("fill", _fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	background.border_color = Color.BLACK
	background.set_border_width_all(1)
	add_theme_stylebox_override("background", background)
	_update_color()


func update_value(new_value: float, new_max: float) -> void:
	max_value = new_max
	value = new_value
	_update_color()


func _update_color() -> void:
	if _fill == null:
		return
	var ratio := value / max_value if max_value > 0.0 else 0.0
	if ratio > 0.5:
		_fill.bg_color = color_high
	elif ratio > 0.25:
		_fill.bg_color = color_mid
	else:
		_fill.bg_color = color_low
