extends Node3D

var maps := [null] + Main.MAPS
var index := 0

@onready var label: Label3D = %Label


func _on_next_map_interacted() -> void:
	index = (index + 1) % maps.size()
	var label_text = str(index)
	
	if index == 0:
		label_text = "random"
		Main.select_map(null)
	else:
		Main.select_map(Main.MAPS[index-1])
	
	label.text = label_text
