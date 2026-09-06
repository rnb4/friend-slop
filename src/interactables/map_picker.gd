extends Node3D

var index := 0

@onready var label: Label3D = %Label


func _on_next_map_interacted() -> void:
	var maps := GameManager.MAIN_MAPS_RESOURCE.maps
	if maps.is_empty():
		return
	index = (index + 1) % (maps.size() + 1)
	var label_text := "random"
	
	if index == 0:
		GameManager.select_map.rpc(-1)
	else:
		label_text = maps[index - 1].name
		GameManager.select_map.rpc(index - 1)
	
	label.text = label_text
