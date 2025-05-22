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
	room.players.append(player)
	room._on_player_join_room(player)
	print("Added player ", player.peer_id, " to room ", room.id)

func leave_room_by_id(id: int) -> void:
	if id not in Global.connected_players:
		return
	var player = Global.connected_players[id]
	leave_room(player)

func leave_room(player: DomainPlayer.Player) -> void:
	if not player.room_id:
		return
	var room = Global.rooms[player.room_id]
	room.players.erase(player)
	room._on_player_leave_room(player)
	player.room_id = ""
	print("Removed player ", player.peer_id, " from room ", room.id)
	if room.players.size() <= 0:
		delete_room(room)

func get_joinable_rooms() -> Array[DomainRoom.Room]:
	var out: Array[DomainRoom.Room] = []
	
	for room in Global.rooms.values():
		if room.joinable:
			out.append(room)
	return out

func join_or_create_random_room(id: int) -> DomainRoom.Room:
	var room: DomainRoom.Room = null
	
	if not id in Global.connected_players:
		return room
	
	var player = Global.connected_players[id]
	
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
