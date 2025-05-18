extends Node

const PORT = 31500
const MAX_CLIENTS = 32


func _ready() -> void:
	print("Server ready")
	DisplayServer.window_set_title("Server")
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	print("Server: created")

func _on_peer_connected(id: int) -> void:
	print("Server: peer connected ", id)

func _on_peer_disconnected(id: int) -> void:
	print("Server: peer disconnected ", id)
