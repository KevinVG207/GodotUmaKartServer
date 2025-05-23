extends Node

class_name DomainRoom

enum RoomType {
	LOBBY,
	RACE
}

class Room:
	var id: String
	var type: RoomType
	var max_players: int = 12
	var joinable: bool = false
	var players: Dictionary[int, DomainPlayer.Player] = {}
	var tick: int = 0
	var tick_rate: int = 10
	
	func _init() -> void:
		self.id = UUID.v4()
	
	func deserialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(id)
		list.append(type)
		list.append(max_players)
		list.append(joinable)
		var players_dict: Dictionary[int, Array] = {}
		for id in players:
			players_dict[id] = players[id].deserialize()
		list.append(players_dict)
		list.append(tick)
		list.append(tick_rate)
		return list
	
	static func serialize(list: Array[Variant]) -> Room:
		var o := Room.new()
		generic_serialize_room(o, list)
		return o
	
	static func generic_serialize_room(room: DomainRoom.Room, list: Array[Variant]) -> void:
		room.id = list.pop_front()
		room.type = list.pop_front()
		room.max_players = list.pop_front()
		room.joinable = list.pop_front()
		var players_dict: Dictionary[int, Array] = list.pop_front()
		for id in players_dict:
			room.players[id] = DomainPlayer.Player.serialize(players_dict[id])
		room.tick = list.pop_front()
		room.tick_rate = list.pop_front()
	
	func _on_player_join_room(player: DomainPlayer.Player) -> void:
		_update_joinable()
		return
	
	func _on_player_leave_room(player: DomainPlayer.Player) -> void:
		_update_joinable()
		return
	
	func _update_joinable() -> void:
		if players.size() >= max_players:
			joinable = false;
		else:
			joinable = true;

	func process() -> void:
		tick += 1
		return

class Lobby extends Room:
	var votes: Dictionary[int, VoteData]
	
	# Server only
	var voting_complete = false
	
	func _init() -> void:
		super()
		self.type = RoomType.LOBBY
	
	func deserialize() -> Array[Variant]:
		var list := super()
		var tmp_votes: Dictionary[int, Array] = {}
		for vote_id in votes:
			tmp_votes[vote_id] = votes[vote_id].deserialize()
		list.append(tmp_votes)
		return list
	
	static func serialize(list: Array[Variant]) -> Lobby:
		var lobby := Lobby.new()
		generic_serialize_room(lobby, list)
		var tmp_votes = list.pop_front() as Dictionary[int, Array]
		for vote_id in tmp_votes:
			lobby.votes[vote_id] = VoteData.serialize(tmp_votes[vote_id])
		return lobby
	
	func process() -> void:
		super()
	
	func _on_vote_data(id: int, data: VoteData) -> void:
		if id not in players:
			return
		votes[id] = data
		print("Player voted: ", id, " ", data.course_name)
		for player in players:
			RPCClient.update_lobby.rpc_id(player, self.deserialize())

class Race extends Room:
	var course_name: String = ""
	
	func _init() -> void:
		super()
		self.type = RoomType.RACE
	
	func deserialize() -> Array[Variant]:
		var list := super()
		return list
	
	static func serialize(list: Array[Variant]) -> Race:
		var race := Race.new()
		generic_serialize_room(race, list)
		race.course_name = list.pop_front()
		return race

	func process() -> void:
		super()

class VoteData:
	var course_name: String = ""
	var character_id: int = 0
	var vehicle_id: int = 0
	
	func deserialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(course_name)
		list.append(character_id)
		list.append(vehicle_id)
		return list

	static func serialize(list: Array[Variant]) -> VoteData:
		var o := VoteData.new()
		o.course_name = list.pop_front()
		o.character_id = list.pop_front()
		o.vehicle_id = list.pop_front()
		return o
