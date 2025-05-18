extends Node

func add_player_to_room(player: DomainPlayer.Player, room_id: String) -> void:
	if player.room_id:
		return
	player.room_id = room_id
	Global.rooms[room_id].players.append(player)
	print("Added player ", player.peer_id, " to room ", room_id)

func disconnect_peer_with_error(id: int, code: int) -> void:
	RPCClient.error.rpc_id(id, code)

func disconnect_peer(id: int) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(id, true)
