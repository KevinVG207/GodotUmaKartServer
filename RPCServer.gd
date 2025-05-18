extends Node

@rpc("any_peer", "reliable")
func initialize_player(data: PackedByteArray) -> void:
	var player_data := DomainPlayer.PlayerInitializeData.serialize(data)
	var id := multiplayer.get_remote_sender_id()
	
	var player := Global.initializing_players[id]
	player.username = player_data.username
	
	Global.connected_players[id] = player
	Global.initializing_players.erase(id)
	Util.add_player_to_room(player, Global.rooms.keys()[0])
	print("Initialized player with ID ", id)
	RPCClient.initialize_player.rpc_id(id, player.deserialize())

@rpc("any_peer", "reliable")
func get_rooms() -> void:
	var out: Array[PackedByteArray] = []
	
	for room: DomainRoom.Room in Global.rooms.values():
		out.append(room.deserialize())
	
	var bytes := var_to_bytes(out)
	RPCClient.get_rooms.rpc_id(multiplayer.get_remote_sender_id(), bytes)
