extends Node3D


signal map_selected(map: PackedScene)


const MAP_01 = preload("uid://bxhv2hlijj6ke")
const MAP_02 = preload("uid://bom2gj1j7jwyi")
const MAP_03 = preload("uid://bla46881n647c")
const maps = [null, MAP_01, MAP_02, MAP_03]

var index = 0

@onready var label: Label3D = %Label


func _on_next_map_interacted() -> void:
	index = (index + 1) % maps.size()
	var label_text := str(index)
	if maps[index] == null:
		label_text = "random"
	label.text = label_text
	map_selected.emit(maps[index])
