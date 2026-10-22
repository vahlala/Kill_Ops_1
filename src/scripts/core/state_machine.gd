class_name StateMachine
extends Node
## Gère les états enfants : un seul est actif à la fois.
## Les états s'ajoutent simplement comme nœuds enfants de la StateMachine.

signal state_changed(old_state_name: String, new_state_name: String)

## État de départ (si vide : le premier enfant).
@export var initial_state: BaseState
## Affiche les changements d'état dans la console.
@export var debug: bool = false

var current_state: BaseState
var states: Dictionary = {}


func _ready() -> void:
	# Les enfants sont prêts AVANT leur parent : on attend que le personnage le soit.
	var parent := get_parent()
	if not parent.is_node_ready():
		await parent.ready

	for child in get_children():
		if child is BaseState:
			states[child.name.to_lower()] = child
			child.character = parent as GenericCharacter
			child.Transitioned.connect(_on_child_transition)
		else:
			push_warning("StateMachine : %s n'est pas un BaseState" % child.name)

	if initial_state == null and not states.is_empty():
		initial_state = states.values()[0]

	if initial_state:
		current_state = initial_state
		current_state.enter()
		if debug:
			print("[%s] État initial : %s" % [parent.name, current_state.name])


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func _on_child_transition(state: BaseState, new_state_name: String) -> void:
	# Seul l'état actif peut demander une transition.
	if state != current_state:
		return

	var new_state: BaseState = states.get(new_state_name.to_lower())
	if new_state == null:
		push_warning("StateMachine : état introuvable « %s »" % new_state_name)
		return
	if new_state == current_state:
		return

	var old_name := current_state.name
	current_state.exit()
	current_state = new_state
	current_state.enter()

	if debug:
		print("[%s] %s -> %s" % [get_parent().name, old_name, new_state.name])
	state_changed.emit(old_name, new_state.name)


## Nom de l'état actif (utile pour le debug et le HUD).
func get_current_state_name() -> String:
	return current_state.name if current_state else ""
