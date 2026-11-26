class_name CracheurState
extends BaseState
## Base des états du cracheur : accès typé à l'agent.

var cracheur: Cracheur:
	get:
		return character as Cracheur
