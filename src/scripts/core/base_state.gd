class_name BaseState
extends Node
## Classe de base de tous les états (patron State).
## Chaque état a UNE responsabilité : son comportement et ses transitions.

## Émis pour demander un changement d'état : Transitioned.emit(self, "nom_etat")
signal Transitioned(state: BaseState, new_state_name: String)

## Personnage contrôlé par cet état (assigné automatiquement par la StateMachine).
var character: GenericCharacter


## Appelée quand on entre dans l'état.
func enter() -> void:
	pass


## Appelée quand on quitte l'état.
func exit() -> void:
	pass


## Appelée à chaque image (_process).
func update(_delta: float) -> void:
	pass


## Appelée à chaque image physique (_physics_process) : mouvement et collisions.
func physics_update(_delta: float) -> void:
	pass


## Appelée pour chaque événement d'entrée non traité.
func handle_input(_event: InputEvent) -> void:
	pass
