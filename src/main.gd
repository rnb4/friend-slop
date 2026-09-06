class_name Main extends Node3D


@onready var players: Node3D = %Players
@onready var map_container: Node3D = %Maps



func _ready() -> void:
	GameManager.register_player_container(players)
	GameManager.register_map_container(map_container)
