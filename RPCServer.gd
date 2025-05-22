extends Node

@rpc("any_peer", "reliable")
func initialize_player(data: PackedByteArray) -> void:
	var player_data := DomainPlayer.PlayerInitializeData.serialize(bytes_to_var(data))
	var id := multiplayer.get_remote_sender_id()
	
	var player := Global.initializing_players[id]
	player.username = player_data.username
	
	Global.connected_players[id] = player
	Global.initializing_players.erase(id)
	print("Initialized player with ID ", id)
	RPCClient.initialize_player.rpc_id(id, var_to_bytes(player.deserialize()))

@rpc("any_peer", "reliable")
func get_rooms() -> void:
	var out: Array[Array] = []
	
	for room: DomainRoom.Room in Global.rooms.values():
		out.append(room.deserialize())
	
	RPCClient.get_rooms.rpc_id(multiplayer.get_remote_sender_id(), var_to_bytes(out))

@rpc("any_peer", "reliable")
func join_random_room() -> void:
	var room = Matchmaking.join_or_create_random_room(multiplayer.get_remote_sender_id())
	RPCClient.join_random_room.rpc_id(multiplayer.get_remote_sender_id(), var_to_bytes(room.deserialize()))
