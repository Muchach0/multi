class_name NetworkManager
extends Node


# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, local_player_info)
signal player_disconnected(peer_id)
signal server_disconnected


var url = "wss://multi-server.muchacho.app:443"
const DEFAULT_PORT = 10567

# var client = null

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var local_player_info = {"name": "Toto"}

var server = null
var client = null


func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if "--local" in OS.get_cmdline_args():
		url = "ws://localhost:" + str(DEFAULT_PORT)
	
	if "--server" in OS.get_cmdline_args():
		print("Server starting up detected")
		host_game()
	else: # if is a client
		print("Client starting up detected")
		client_start()


########### 1. SIGNAL HANDLING ###########
# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	print("NetworkManager.gd - _on_player_connected(id) - id: " + str(id))
	_register_player.rpc_id(id, local_player_info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	print("NetworkManager.gd - _register_player(id) - new_player_info: " + str(new_player_info))
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id):
	print("NetworkManager.gd - _on_player_disconnected(id) - id: " + str(id))
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	print("NetworkManager.gd - _on_connected_ok()")
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = local_player_info
	player_connected.emit(peer_id, local_player_info)

func _on_connected_fail():
	print("NetworkManager.gd - _on_connected_fail()")
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	print("NetworkManager.gd - _on_server_disconnected()")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

########### 2. SERVER HANDLING ###########
func host_game():
	print("NetworkManager.gd - host_game() - Server starting listening to port : " + str(DEFAULT_PORT))
	server = WebSocketMultiplayerPeer.new()
	server.create_server(DEFAULT_PORT)

	# server.listen(DEFAULT_PORT, PoolStringArray(), true);
	# server.listen(DEFAULT_PORT)
	multiplayer.multiplayer_peer = server
	# get_tree().set_network_peer(server)
	



########### 3. CLIENT HANDLING ###########
func client_start():
	print("NetworkManager.gd - client_start() - Client connecting to url: " + url)
	client = WebSocketMultiplayerPeer.new()
	client.create_client(url)
	multiplayer.multiplayer_peer = client

########### 4. PROCESS ###########
# func _process(delta):
# 	if server != null:
# 		if server.