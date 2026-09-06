extends Node


signal host_created()
signal server_left()


const LOBBY_TYPE := Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY
const MAX_MEMBERS := 8

var connected: bool = false


var peer: MultiplayerPeer


func _ready() -> void:
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)
	Steam.join_requested.connect(_on_join_requested)

	host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.server_disconnected.connect(_on_server_leave)


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func host_enet_lobby(port: int = 4444) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port)
	if err != OK:
		return err
	connected = true
	multiplayer.multiplayer_peer = peer
	host_created.emit()
	return OK


func join_enet_lobby(host: String = "127.0.0.1", port: int = 4444) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(host, port)
	if err != OK:
		return err
	connected = true
	multiplayer.multiplayer_peer = peer
	return OK


func host_steam_lobby() -> void:
	Steam.createLobby(LOBBY_TYPE, MAX_MEMBERS)


func _on_steam_lobby_created(ok: int, _lobby_id: int) -> void:
	if ok != Steam.Result.RESULT_OK:
		return
	connected = true
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_host()
	multiplayer.multiplayer_peer = peer
	host_created.emit()


func _on_steam_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		return
	
	var lobby_owner = Steam.getLobbyOwner(lobby_id)
	if lobby_owner == Steam.getSteamID():
		return
	connected = true
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(lobby_owner)
	multiplayer.multiplayer_peer = peer


func _on_join_requested(lobby_id: int, _steam_id: int) -> void:
	Steam.joinLobby(lobby_id)


func _on_peer_connected(id: int) -> void:
	print("%d: %d connected" % [multiplayer.get_unique_id(), id])


func _on_host_created() -> void:
	print("%d: host created" % multiplayer.get_unique_id())

func _on_server_leave() -> void:
	server_left.emit()
	if peer != null:
		peer.free.call_deferred() # no queue_free on multiplayer peers...?
