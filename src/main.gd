extends Node3D


const PLAYER_SCENE := preload("uid://cmxmrf243e57g")
const MAP_01 := preload("uid://bxhv2hlijj6ke")
const MAP_02 := preload("uid://bom2gj1j7jwyi")
const MAP_03 := preload("uid://bla46881n647c")
const MAPS := [MAP_01, MAP_02, MAP_03]


var map: Node3D = null


@onready var main_menu: Control = %MainMenu
@onready var players: Node3D = %Players


func _ready() -> void:
	NetworkManager.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _on_host_created() -> void:
	_spawn_map()
	_spawn_player(multiplayer.get_unique_id())
	_enter_game()


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(id)


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	
	var to_remove := players.get_node_or_null(str(id))
	if to_remove:
		to_remove.queue_free()


func _on_connected_to_server() -> void:
	_enter_game()


func _enter_game() -> void:
	main_menu.hide()


func _spawn_map() -> void:
	if map != null:
		map.queue_free()
		map = null
	map = MAPS.pick_random().instantiate() as Node3D
	add_child(map)


func _spawn_player(id: int) -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	# TODO: implement spawn positions
	player.position = Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))
	player.network_position = player.position
	player.name = str(id)
	players.add_child(player, true)
