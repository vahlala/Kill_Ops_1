class_name BaseState
extends Node

signal Transitioned(state: BaseState, new_state_name: String)

var character: GenericCharacter

func enter() -> void:
	pass

func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
