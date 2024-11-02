extends Node

var client_peer: ENetMultiplayerPeer
var player_by_peer = {} # maps peers to players
const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 1705
const MAX_CLIENTS = 3 # 4 players
signal connected_as_server
signal connected_as_client
signal player_by_peer_changed
signal any_disconnected


func restart():
	if multiplayer.multiplayer_peer == null:
		return
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	player_by_peer = {}
	any_disconnected.emit()

	# can't reset and disconnect without this
	NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.NETWORK_OFF)
	await get_tree().process_frame
	NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY_MANUALCHANGE)


# the % thing doesn't seem to work for me
@onready var NetworkGateway = get_node("/root/Main/MainLayer/NetworkGateway")

func host_or_join_game(asserver):
	if asserver:
		print("hosting game")
		NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_SERVER)
	else:
		print("joining game")
		NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_CLIENT)
	# calls-back to _on_network_gateway_webrtc_multiplayerpeer_set(asserver)

func _on_network_gateway_webrtc_multiplayerpeer_set(asserver):
	if asserver:
		if not multiplayer.peer_connected.is_connected(_on_peer_connected):
			multiplayer.peer_connected.connect(_on_peer_connected)
		if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
			multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		if Game.my_player == null:
			Game.my_player = Game.Players.TeamAP1
		player_by_peer[multiplayer.get_unique_id()] = Game.my_player
		player_by_peer_changed.emit()
		connected_as_server.emit()

	else:
		if not multiplayer.peer_connected.is_connected(_on_peer_connected):
			multiplayer.peer_connected.connect(_on_peer_connected)
		if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
			multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
			multiplayer.connected_to_server.connect(_on_connected_to_server)
		if not multiplayer.connection_failed.is_connected(_on_connection_failed):
			multiplayer.connection_failed.connect(_on_connection_failed)
		if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
			multiplayer.server_disconnected.connect(_on_server_disconnected)


@rpc("authority", "call_local", "reliable")
func _update_client_players(_player_by_peer):
	prints("update players in", multiplayer.get_unique_id())
	player_by_peer = _player_by_peer
	Game.set_my_player(player_by_peer[multiplayer.get_unique_id()])
	player_by_peer_changed.emit()


@rpc("any_peer", "call_local", "reliable")
func request_player_change(player):
	var sender_id = multiplayer.get_remote_sender_id()
	if player in player_by_peer.values():
		return
	player_by_peer.erase(sender_id)
	player_by_peer[sender_id] = player
	player_by_peer_changed.emit()
	_update_client_players.rpc(player_by_peer)
	prints("peer", sender_id, "now plays as", Game.Players.keys()[player])


func _on_peer_connected(id):
	if multiplayer.is_server():
		prints("peer", id, "joined the game")
		var player: Game.Players
		for p in Game.Players.values():
			if p not in player_by_peer.values():
				player = p
				break
		player_by_peer[id] = player
		player_by_peer_changed.emit()
		_update_client_players.rpc(player_by_peer)
	elif id != 1:
		prints(multiplayer.get_unique_id(), ": another player joined")


func _on_peer_disconnected(id):
	if multiplayer.is_server():
		prints("peer", id, "left the game")
		player_by_peer.erase(id)
		player_by_peer_changed.emit()
		_update_client_players.rpc(player_by_peer)
		# FIXME if playing the game, go back to the lobby
	elif id != 1:
		prints(multiplayer.get_unique_id(), ": another player left")


func _on_connected_to_server():
	if Game.my_player != null:
		request_player_change.rpc_id(1, Game.my_player)
	connected_as_client.emit()

func _on_connection_failed():
	print("Connection failed, go back to lobby")
	# FIXME go_to_lobby()

func _on_server_disconnected():
	print("Server disconnected, rejoin")
	multiplayer.multiplayer_peer = null
	player_by_peer = {}
	# bring back the enter object
	any_disconnected.emit()

	# can't reset and disconnect without this
	NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.NETWORK_OFF)
	await get_tree().process_frame
	NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY_MANUALCHANGE)
