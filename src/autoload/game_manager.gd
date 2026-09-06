extends Node

const PLAYER_SCENE: PackedScene = preload("uid://cmxmrf243e57g")
const MAIN_MAPS_RESOURCE: MapsList = preload("uid://bmtgfp3tiiky6")
const PLAYER_SPAWN_RANGE: float = 10

var _players: Node3D
var _map_container: Node3D
var _current_map: Node3D
var _current_map_path: String
var _selected_map_index := -1
var _is_game_in_progress := false

func _ready() -> void:
	NetworkManager.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func register_player_container(players: Node3D) -> void:
	_players = players

func register_map_container(map: Node3D) -> void:
	_map_container = map
	go_to_lobby.rpc()

@rpc("any_peer", "call_local", "reliable")
func select_map(map_index: int) -> void:
	if map_index == -1:
		_selected_map_index = -1
		return
	if map_index < 0 or map_index >= MAIN_MAPS_RESOURCE.maps.size():
		return
	_selected_map_index = map_index

@rpc("any_peer", "call_local", "reliable")
func go_to_lobby() -> void:
	if multiplayer.is_server():
		_load_lobby.rpc()

@rpc("authority", "call_local", "reliable")
func _load_lobby() -> void:
	if _map_container == null:
		push_error("GameManager: map container has not been registered.")
		return
	_replace_current_map(MAIN_MAPS_RESOURCE.lobby)
	_is_game_in_progress = false

@rpc("any_peer", "call_local", "reliable")
func request_start_game() -> void:
	if multiplayer.is_server():
		_swap_map.rpc()

func request_clear_game() -> void:
	if _current_map != null:
		_current_map.queue_free()
	_selected_map_index = -1
	_is_game_in_progress = false
	for player in _players.get_children():
		player.queue_free()

func _on_host_created() -> void:
	_spawn_player(multiplayer.get_unique_id())
	_load_lobby()

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_spawn_player.rpc(id)
		for player in _players.get_children():
			if player.name != str(id):
				_spawn_player.rpc_id(id, player.name.to_int())
		if _is_game_in_progress:
			select_map.rpc_id(id, _selected_map_index)
			_swap_map.rpc_id(id)
		else:
			_load_lobby.rpc_id(id)

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		_remove_player.rpc(id)

func _on_connected_to_server() -> void:
	pass

# TODO: Integrate round management and role assignment here.
@rpc("authority", "call_local", "reliable")
func _spawn_player(id: int) -> void:
	if _players == null:
		push_error("GameManager: player container has not been registered.")
		return
	if _players.has_node(str(id)):
		return
	var player := PLAYER_SCENE.instantiate() as Player
	if player == null:
		push_error("GameManager: player scene must have a Player root node.")
		return
	player.position = Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))
	player.network_position = player.position
	player.name = str(id)
	_players.add_child(player, true)

@rpc("authority", "call_local", "reliable")
func _remove_player(id: int) -> void:
	if _players == null:
		return
	var player := _players.get_node_or_null(str(id))
	if player != null:
		player.queue_free()

@rpc("authority", "call_local", "reliable")
func _swap_map() -> void:
	if _map_container == null:
		push_error("GameManager: map container has not been registered.")
		return
	if MAIN_MAPS_RESOURCE.maps.is_empty():
		push_error("GameManager: no maps are configured.")
		return
	if _selected_map_index < 0 or _selected_map_index >= MAIN_MAPS_RESOURCE.maps.size():
		_selected_map_index = randi_range(0, MAIN_MAPS_RESOURCE.maps.size() - 1)
	if !_replace_current_map(MAIN_MAPS_RESOURCE.maps[_selected_map_index].map_path):
		return
	_is_game_in_progress = true
	_place_players_at_spawn_points()

func _replace_current_map(scene_path: String) -> bool:
	if _current_map_path == scene_path:
		return true
	var scene := load(scene_path)
	var map := scene.instantiate() as Node3D
	if map == null:
		push_error("GameManager: map scenes must have a Node3D root node.")
		return false
	if _current_map != null:
		_current_map.free()
	_map_container.add_child(map)
	_current_map = map
	return true

func _place_players_at_spawn_points() -> void:
	if _current_map == null or _players == null or !multiplayer.is_server():
		return
	var vampire_spawns: Array[Node] = get_tree().get_nodes_in_group("spawn_vampire")
	var hunter_spawns: Array[Node] = get_tree().get_nodes_in_group("spawn_hunter")
	for node in _players.get_children():
		var player := node as Player
		if player == null:
			continue
		var spawn_list: Array[Node] = []
		match player.player_type:
			Enums.PlayerType.Hunter, Enums.PlayerType.Spectator:
				spawn_list = hunter_spawns
			Enums.PlayerType.Vampire:
				spawn_list = vampire_spawns
		var offset := Vector3(_get_spawn_rangef(), 0, _get_spawn_rangef())
		if spawn_list.size() == 0:
			player.global_position = offset
		else:
			var point := spawn_list.pick_random() as Node3D
			player.global_position = point.global_position + offset

func _get_spawn_rangef() -> float:
	return randf_range(-PLAYER_SPAWN_RANGE, PLAYER_SPAWN_RANGE)
