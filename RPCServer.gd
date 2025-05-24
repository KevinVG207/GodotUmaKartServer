extends Node

@rpc("any_peer", "reliable")
func initialize_player(list: Array[Variant]) -> void:
	var player_data := DomainPlayer.PlayerInitializeData.deserialize(list)
	var id := multiplayer.get_remote_sender_id()
	
	var player := Global.initializing_players[id]
	if not player:
		player = Global.connected_players[id]
	player.peer_id = id
	player.username = player_data.username
	
	Global.connected_players[id] = player
	Global.initializing_players.erase(id)
	print("Initialized player ", id, ": ", player.username)
	RPCClient.initialize_player.rpc_id(id, player.serialize())

@rpc("any_peer", "reliable")
func get_rooms() -> void:
	var out: Array[Array] = []
	
	for room: DomainRoom.Room in Global.rooms.values():
		out.append(room.serialize())
	
	RPCClient.get_rooms.rpc_id(multiplayer.get_remote_sender_id(), out)

@rpc("any_peer", "reliable")
func join_random_room() -> void:
	var room = Matchmaking.join_or_create_random_room(multiplayer.get_remote_sender_id())
	
	match room.type:
		DomainRoom.RoomType.LOBBY:
			var lobby = room as DomainRoom.Lobby
			RPCClient.join_lobby_room.rpc_id(multiplayer.get_remote_sender_id(), lobby.serialize())
		DomainRoom.RoomType.RACE:
			var race = room as DomainRoom.Race
			RPCClient.join_race_room.rpc_id(multiplayer.get_remote_sender_id(), race.serialize())

@rpc("any_peer", "reliable")
func send_vote(list: Array[Variant]) -> void:
	var id := multiplayer.get_remote_sender_id()
	var data := DomainRoom.VoteData.deserialize(list)
	var room_id := Global.connected_players[id].room_id
	if not room_id:
		return
	var lobby = Global.rooms[room_id] as DomainRoom.Lobby
	lobby._on_vote_data(id, data)

@rpc("any_peer", "reliable")
func send_ping(tick: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	var player := Global.connected_players[id]
	if not player.room_id or not player.room_id in Global.rooms:
		return
	var room := Global.rooms[player.room_id]
	room.handle_ping(id, tick)

@rpc("any_peer", "reliable")
func race_send_ready() -> void:
	var id := multiplayer.get_remote_sender_id()
	Global.connected_players[id].ready = true
	print("READY RECEIVED FROM ", id)

@rpc("any_peer", "unreliable_ordered")
func race_vehicle_state(state: Dictionary) -> void:
	var id := multiplayer.get_remote_sender_id()
	var player := Global.connected_players[id]
	if not player.room_id or not player.room_id in Global.rooms:
		return
	var room := Global.rooms[player.room_id] as DomainRoom.Race
	room.vehicle_states[id] = state
	var wrapper := DomainRace.VehicleDataWrapper.new()
	wrapper.player = player
	wrapper.vehicle_state = state
	for pid in room.players:
		if pid == id:
			continue
		RPCClient.race_vehicle_state.rpc_id(pid, wrapper.serialize())
