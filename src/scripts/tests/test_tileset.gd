extends "res://scripts/tests/test_player.gd"
## Terrain d'essai du TileSet jungle (mêmes touches de test que test_player).
## La caméra est limitée à la zone peinte du TileMapLayer « Sol ».

@onready var sol: TileMapLayer = $Sol


func _ready() -> void:
	super()
	var cell := sol.tile_set.tile_size
	var used := sol.get_used_rect()
	var area := Rect2i(used.position * cell, used.size * cell)
	area = area.grow_side(SIDE_TOP, 160)      # un peu de ciel au-dessus du plus haut mur
	area = area.grow_side(SIDE_BOTTOM, -16)   # cache la rangée d'herbe du dessous du sol
	player.set_camera_limits(area)
