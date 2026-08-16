extends Node3D


const PLAYER_SCENE := preload("uid://cmxmrf243e57g")
const LOBBY_SCENE = preload("uid://bxi02m0xvioha")


@export var selected_map: PackedScene = null

@onready var main_menu: Control = %MainMenu
@onready var players: Node3D = %Players
@onready var lobby: Node3D = %Lobby
@onready var current_map: Node3D = lobby


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
	if current_map != null:
		current_map.queue_free()
		current_map = null
	current_map = LOBBY_SCENE.instantiate() as Node3D
	add_child(current_map)


func _spawn_player(id: int) -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	# TODO: implement spawn positions
	player.position = Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))
	player.network_position = player.position
	player.name = str(id)
	players.add_child(player, true)


func _on_map_picker_map_selected(selection: PackedScene) -> void:
	selected_map = selection
