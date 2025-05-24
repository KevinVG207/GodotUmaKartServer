extends Node

func register_new_room(room: DomainRoom.Room) -> DomainRoom.Room:
	print("Registering new ", DomainRoom.RoomType.find_key(room.type), " room: ", room.id)
	Global.rooms[room.id] = room
	return room

func delete_room(room: DomainRoom.Room) -> void:
	print("Closing room ", room.id)
	Global.rooms.erase(room.id)

func add_player_to_room(player: DomainPlayer.Player, room: DomainRoom.Room) -> void:
	if player.room_id:
		return
	
	if !room.joinable or room.players.size() > room.max_players:
		Util.disconnect_peer_with_error(player.peer_id, DomainError.ROOM_IS_UNJOINABLE)
		return
	
	player.room_id = room.id
	room.players[player.peer_id] = player
	room._on_player_join_room(player)
	print("Added player ", player.peer_id, " to room ", room.id)
	for room_player: DomainPlayer.Player in room.players.values():
		if room_player.peer_id == player.peer_id:
			continue
		print("Signalling new player joined")
		RPCClient.player_joined_room.rpc_id(room_player.peer_id, player.serialize())

func leave_room_by_id(id: int) -> void:
	if id not in Global.connected_players:
		return
	var player := Global.connected_players[id]
	leave_room(player)

func leave_room(player: DomainPlayer.Player) -> void:
	if not player.room_id:
		return
	var room := Global.rooms[player.room_id]
	room.players.erase(player.peer_id)
	room._on_player_leave_room(player)
	player.room_id = ""
	print("Removed player ", player.peer_id, " from room ", room.id)
	
	for room_player: DomainPlayer.Player in room.players.values():
		RPCClient.player_left_room.rpc_id(room_player.peer_id, player.serialize())

func transfer_player(player: DomainPlayer.Player, new_room: DomainRoom.Room) -> void:
	leave_room(player)
	player.ready = false
	add_player_to_room(player, new_room)
	
	match new_room.type:
		DomainRoom.RoomType.LOBBY:
			var lobby = new_room as DomainRoom.Lobby
			RPCClient.join_lobby_room.rpc_id(player.peer_id, lobby.serialize())
		DomainRoom.RoomType.RACE:
			var race = new_room as DomainRoom.Race
			RPCClient.join_race_room.rpc_id(player.peer_id, race.serialize())

func get_joinable_rooms() -> Array[DomainRoom.Room]:
	var out: Array[DomainRoom.Room] = []
	
	for room: DomainRoom.Room in Global.rooms.values():
		if room.joinable:
			out.append(room)
	return out

func join_or_create_random_room(id: int) -> DomainRoom.Room:
	var room: DomainRoom.Room = null
	
	if not id in Global.connected_players:
		return room
	
	var player := Global.connected_players[id]
	
	if player.room_id:
		Util.disconnect_peer_with_error(id, DomainError.DUPLICATE_USER)
		return room
	
	var rooms := get_joinable_rooms()
	if !rooms.is_empty():
		room = rooms.pick_random()
	else:
		room = register_new_room(DomainRoom.Lobby.new())
		room.joinable = true
	add_player_to_room(player, room)
	
	return room
