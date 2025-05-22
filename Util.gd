extends Node

func disconnect_peer_with_error(id: int, code: int) -> void:
	Matchmaking.leave_room_by_id(id)
	RPCClient.error.rpc_id(id, code)

func disconnect_peer(id: int) -> void:
	Matchmaking.leave_room_by_id(id)
	multiplayer.multiplayer_peer.disconnect_peer(id, true)
