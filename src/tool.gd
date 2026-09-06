class_name Tool
extends Node3D


@export var tool_entry: ToolEntry

var _player: Player
var _camera: Camera3D

func initialize(player: Player, camera: Camera3D) -> void:
	_player = player
	_camera = camera
	
func use() -> void:
	assert(false, "missing implementation")
	
func reload() -> void:
	assert(false, "missing implementation")
	
func equip() -> void:
	assert(false, "missing implementation")
	
func unequip() -> void:
	assert(false, "missing implementation")
