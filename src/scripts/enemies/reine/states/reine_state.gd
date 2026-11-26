class_name ReineState
extends BaseState
## Base des états de la Reine : accès typé au boss.

var reine: Reine:
	get:
		return character as Reine
