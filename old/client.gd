extends Control

const PORT := 31500
const IP_ADDRESS := "185.252.235.108"
var user_id: int

func _ready() -> void:
	print("Client ready")
	DisplayServer.window_set_title("Client")
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	RPC.received_vehicle_state.connect(print_received_id)


func _on_connect_button_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	print("Client: attempting to connect")


func _on_disconnect_button_pressed() -> void:
	multiplayer.multiplayer_peer = null
	print("Client: disconnecting (immediate)")

func _on_connected_to_server() -> void:
	user_id = multiplayer.get_unique_id()
	print("Client: connected to server ", user_id)

func _on_connection_failed() -> void:
	print("Client: connection failed")

func _on_server_disconnected() -> void:
	print("Client: server disconnected")


func print_received_id(id: int) -> void:
	print(id)


func _on_rpc_button_1_pressed() -> void:
	RPC.send_vehicle_state(user_id)
