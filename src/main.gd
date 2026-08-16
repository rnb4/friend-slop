class_name Main extends Node3D


const PLAYER_SCENE := preload("uid://cmxmrf243e57g")
const LOBBY_SCENE = preload("uid://bxi02m0xvioha")
const MAP_01 = preload("uid://bxhv2hlijj6ke")
const MAP_02 = preload("uid://bom2gj1j7jwyi")
const MAP_03 = preload("uid://bla46881n647c")
const MAPS = [MAP_01, MAP_02, MAP_03]

static var instance: Main

@export var selected_map: PackedScene = null

@onready var main_menu: Control = %MainMenu
@onready var players: Node3D = %Players
@onready var current_map: Node3D = %Lobby



func _ready() -> void:
	instance = self
	NetworkManager.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_F1:
		selected_map = LOBBY_SCENE
		_swap_map()
		selected_map = null


static func select_map(selection: PackedScene) -> void:
	instance.selected_map = selection


static func start_game() -> void:
	instance._swap_map()


func _on_host_created() -> void:
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


func _spawn_player(id: int) -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	# TODO: implement spawn positions
	player.position = Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))
	player.network_position = player.position
	player.name = str(id)
	players.add_child(player, true)


func _place_players_at_spawn_points() -> void:
	for node in players.get_children():
		var player = node as Player
		player.position = Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))


func _swap_map() -> void:
	current_map.queue_free()
	if selected_map == null:
		selected_map = MAPS.pick_random()
	var map := selected_map.instantiate() as Node3D
	add_child(map, true)
	current_map = map
	_place_players_at_spawn_points()


func _on_start_game_interacted() -> void:
	_swap_map()
