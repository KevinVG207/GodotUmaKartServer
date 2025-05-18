extends Node

# This would only exist on the client side
func send_vehicle_state(data: int) -> void:
	print(multiplayer.is_server(), ": send_vehicle_state")
	_server_receives_vehicle_state.rpc_id(1, data)

# Only the server should have content
@rpc("any_peer", "unreliable_ordered")
func _server_receives_vehicle_state(data: int) -> void:
	print(multiplayer.is_server(), ": _server_receives_vehicle_state")
	_client_receives_vehicle_state.rpc(data)

# This would only have content on the client side
signal received_vehicle_state(data: int)
@rpc("unreliable")
func _client_receives_vehicle_state(data: int) -> void:
	print(multiplayer.is_server(), ": _client_receives_vehicle_state")
	received_vehicle_state.emit(data)
