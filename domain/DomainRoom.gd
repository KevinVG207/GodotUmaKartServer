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
	var joinable: bool = true
	var players: Dictionary[int, DomainPlayer.Player] = {}
	var tick: int = 0
	static var tick_rate: int = 10
	
	# Server only
	class PingData:
		static var max_pings: int = 10
		var last_pings: Array[int] = []
		var ongoing_pings: Array[int] = []
	var ping_data: Dictionary[int, PingData] = {}
	var timeout: int = 5 * 60 * tick_rate
	var version: String
	
	func _init() -> void:
		self.id = UUID.v4()
	
	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(id)
		list.append(type)
		list.append(max_players)
		list.append(joinable)
		var players_dict: Dictionary[int, Array] = {}
		for pid in players:
			players_dict[pid] = players[pid].serialize()
		list.append(players_dict)
		list.append(tick)
		list.append(tick_rate)
		return list
	
	static func deserialize(list: Array[Variant]) -> Room:
		var o := Room.new()
		generic_deserialize_room(o, list)
		return o
	
	static func generic_deserialize_room(room: DomainRoom.Room, list: Array[Variant]) -> void:
		room.id = list.pop_front()
		room.type = list.pop_front()
		room.max_players = list.pop_front()
		room.joinable = list.pop_front()
		var players_dict: Dictionary[int, Array] = list.pop_front()
		for pid in players_dict:
			room.players[pid] = DomainPlayer.Player.deserialize(players_dict[pid])
		room.tick = list.pop_front()
		room.tick_rate = list.pop_front()
	
	func _on_player_join_room(player: DomainPlayer.Player) -> void:
		ping_data[player.peer_id] = PingData.new()
		return
	
	func _on_player_leave_room(player: DomainPlayer.Player) -> void:
		ping_data.erase(player.peer_id)
		return
	
	func _update_joinable() -> void:
		if players.size() >= max_players:
			joinable = false;
		else:
			joinable = true;

	func process() -> void:
		tick += 1
		ping_players()

		if tick >= timeout:
			for pid in players:
				Util.disconnect_peer_with_error(pid, DomainError.ROOM_TIMEOUT)
			Matchmaking.delete_room(self)
		return
	
	func ping_players() -> void:
		if tick % floori(tick_rate / 2.0) != 0:
			return
		for pid: int in players:
			var cur_tick := Time.get_ticks_msec()
			ping_data[pid].ongoing_pings.append(cur_tick)
			RPCClient.receive_ping.rpc_id(pid, cur_tick, players[pid].ping)
	
	func handle_ping(pid: int, org_tick: int) -> void:
		if not pid in players:
			return
		if not org_tick in ping_data[pid].ongoing_pings:
			return
		var cur_tick := Time.get_ticks_msec()
		var one_way := roundi((cur_tick - org_tick) / 2.0)
		ping_data[pid].ongoing_pings.erase(org_tick)
		ping_data[pid].last_pings.append(one_way)
		while ping_data[pid].last_pings.size() > PingData.max_pings:
			ping_data[pid].last_pings.pop_front()
		var avg_ping := 0.0
		for ping in ping_data[pid].last_pings:
			avg_ping += ping
		avg_ping /= ping_data[pid].last_pings.size()
		players[pid].ping = round(avg_ping)

class Lobby extends Room:
	static var INITIAL_VOTING_TIMEOUT: int = 30 * tick_rate
	static var INITIAL_JOINING_TIMEOUT: int = 15 * tick_rate
	static var NEXT_VOTING_TIMEOUT: int = 60 * tick_rate
	static var NEXT_JOINING_TIMEOUT: int = 45 * tick_rate
	
	var votes: Dictionary[int, VoteData]
	var voting_timeout: int = INITIAL_VOTING_TIMEOUT
	var joining_timeout: int = INITIAL_JOINING_TIMEOUT
	var winning_vote: int = 0
	
	# Server only
	var initial_voting_timeout: int = 30 * tick_rate
	var initial_joining_timeout: int = 15 * tick_rate
	var voting_complete := false
	
	func _init() -> void:
		super()
		self.type = RoomType.LOBBY
	
	func serialize() -> Array[Variant]:
		var list := super()
		var tmp_votes: Dictionary[int, Array] = {}
		for vote_id in votes:
			tmp_votes[vote_id] = votes[vote_id].serialize()
		list.append(tmp_votes)
		list.append(voting_timeout)
		list.append(joining_timeout)
		list.append(winning_vote)
		return list
	
	static func deserialize(list: Array[Variant]) -> Lobby:
		var lobby := Lobby.new()
		generic_deserialize_room(lobby, list)
		var tmp_votes := list.pop_front() as Dictionary[int, Array]
		for vote_id in tmp_votes:
			lobby.votes[vote_id] = VoteData.deserialize(tmp_votes[vote_id])
		lobby.voting_timeout = list.pop_front()
		lobby.joining_timeout = list.pop_front()
		lobby.winning_vote = list.pop_front()
		return lobby
	
	func process() -> void:
		super()
		if tick % tick_rate == 0 and not winning_vote:
			for pid in players:
				RPCClient.update_lobby.rpc_id(pid, self.serialize())
		
		if players.size() == 1:
			voting_timeout = tick + initial_voting_timeout
			joining_timeout = tick + initial_joining_timeout
			timeout = voting_timeout + tick_rate * 60
		
		determine_winning_vote()
	
	func determine_winning_vote() -> void:
		if winning_vote:
			return
		
		if tick < joining_timeout:
			return
		
		if players.size() < 1:
			return
		
		for pid in players:
			if pid not in votes:
				return
		
		voting_complete = true
		winning_vote = votes.keys().pick_random()
		for pid in players:
			RPCClient.receive_final_lobby.rpc_id(pid, self.serialize())
		var race := Race.new()
		race.version = version
		race.course_name = votes[winning_vote].course_name
		var pids := players.keys()
		pids.shuffle()
		race.starting_order = pids
		Matchmaking.register_new_room(race)
		for pid: int in players.keys().duplicate():
			Matchmaking.transfer_player(players[pid], race)
	
	func _on_vote_data(pid: int, data: VoteData) -> void:
		if pid not in players:
			return
		votes[pid] = data
		print("Player voted: ", pid, " ", data.course_name)
		for player in players:
			RPCClient.update_lobby.rpc_id(player, self.serialize())
	
	func _update_joinable() -> void:
		if players.size() >= max_players:
			joinable = false;
		elif voting_complete:
			joinable = false
		elif tick >= joining_timeout:
			joinable = false;
		else:
			joinable = true;

class Race extends Room:
	var course_name: String = ""
	var starting_order: Array[int] = []
	
	# Server Only
	static var FINISH_TIMEOUT := 30 * tick_rate
	var start_timeout: int = 30 * tick_rate
	var started := false
	var finished := false
	var pings_at_start: Dictionary[int, int] = {}
	var vehicle_states: Dictionary[int, Dictionary] = {}
	var finish_timeout := timeout
	var one_finished := false
	var existing_items: Dictionary[String, DomainRace.ItemSpawnWrapper] = {}
	var deleted_items: Dictionary[String, DomainRace.ItemStateWrapper] = {}
	
	func _init() -> void:
		super()
		self.type = RoomType.RACE
	
	func serialize() -> Array[Variant]:
		var list := super()
		list.append(course_name)
		list.append(starting_order)
		return list
	
	static func deserialize(list: Array[Variant]) -> Race:
		var race := Race.new()
		generic_deserialize_room(race, list)
		race.course_name = list.pop_front()
		race.starting_order = list.pop_front()
		return race

	func _update_joinable() -> void:
		if players.size() >= max_players:
			joinable = false
		elif started:
			joinable = true
		elif one_finished:
			joinable = false
		elif finished:
			joinable = false
		else:
			joinable = false

	func process() -> void:
		super()
		check_for_close()
		check_for_start()
		check_finished()
		handle_finished()
	
	func check_for_close() -> void:
		if !started:
			return
		if players.size() <= 0:
			timeout = tick
	
	func check_for_start() -> void:
		if started:
			return
		
		var all_ready := true
		timeout = 10 * 60 * tick_rate
		finish_timeout = 6 * 60 * tick_rate
		for player in players.values():
			if !player.ready:
				all_ready = false
				break
		
		if !all_ready and tick < start_timeout:
			return
		
		var ping_dict: Dictionary[int, int] = {}
		var highest_ping: int = 0
		var can_start := true
		for player in players.values():
			if ping_data[player.peer_id].last_pings.size() < 5:
				can_start = false
				break
			ping_dict[player.peer_id] = player.ping
			print("PING ", player.peer_id, " ", player.ping)
			if player.ping > highest_ping:
				highest_ping = player.ping
		
		if !can_start:
			return
		
		started = true
		print("STARTING RACE")
		
		var ticks_to_start := ceili(((highest_ping / 1000.0) + 1) * tick_rate)
		pings_at_start = ping_dict
		
		for pid in players:
			RPCClient.race_start.rpc_id(pid, ticks_to_start, tick_rate, ping_dict[pid])

	func check_finished() -> void:
		if not started:
			return
		if finished:
			return
		if not vehicle_states:
			return
		if players.size() <= 1:
			finished = true
			return
		if tick >= finish_timeout:
			finished = true
			return
		
		var cur_one_finished := false
		var unfinished_count := 0
		for pid in vehicle_states:
			if not pid in players:
				continue
			var state := vehicle_states[pid]
			if state.finished:
				cur_one_finished = true
			else:
				unfinished_count += 1
		
		if cur_one_finished != one_finished:
			finish_timeout = tick + FINISH_TIMEOUT
		
		one_finished = cur_one_finished
		
		if unfinished_count < 2 and vehicle_states.size() > 1:
			finished = true

	func handle_finished() -> void:
		if not started:
			return
		if not finished:
			return
		
		var finish_order := determine_finish_order()
		var finish_type := FinishType.NORMAL
		if tick >= finish_timeout:
			finish_type = FinishType.TIMEOUT
		
		var dto := FinishData.new()
		dto.finish_order = finish_order
		dto.type = finish_type
		
		var lobby := Lobby.new()
		lobby.version = version
		lobby.voting_timeout = Lobby.NEXT_VOTING_TIMEOUT
		lobby.joining_timeout = Lobby.NEXT_JOINING_TIMEOUT
		Matchmaking.register_new_room(lobby)
		for player: DomainPlayer.Player in players.values().duplicate(false):
			RPCClient.race_finished.rpc_id(player.peer_id, dto.serialize())
			Matchmaking.transfer_player(player, lobby)
		Matchmaking.delete_room(self)
		
	func determine_finish_order() -> Array[int]:
		var finished_vehicles: Array[int] = []
		var unfinished_vehicles: Array[int] = []
		
		for user_id: int in vehicle_states:
			if not user_id in players:
				continue
			
			if vehicle_states[user_id].finished:
				finished_vehicles.append(user_id)
			else:
				unfinished_vehicles.append(user_id)
		
		finished_vehicles.sort_custom(func(a: int, b: int) -> bool: return vehicle_states[a].finish_time < vehicle_states[b].finish_time)
		unfinished_vehicles.sort_custom(func(a: int, b: int) -> bool: return get_vehicle_progress(vehicle_states[a]) > get_vehicle_progress(vehicle_states[b]))
		
		finished_vehicles += unfinished_vehicles
		return finished_vehicles
	
	static func get_vehicle_progress(state: Dictionary) -> float:
		return 10000 * state.lap + state.check_idx + state.check_progress

enum FinishType {
	NORMAL,
	TIMEOUT
}

class FinishData:
	var finish_order: Array[int]
	var type: FinishType
	
	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(finish_order)
		list.append(type)
		return list
	
	static func deserialize(list: Array[Variant]) -> FinishData:
		var o := FinishData.new()
		o.finish_order = list.pop_front()
		o.type = list.pop_front()
		return o


class VoteData:
	var course_name: String = ""
	var character_id: int = 0
	var vehicle_id: int = 0
	
	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(course_name)
		list.append(character_id)
		list.append(vehicle_id)
		return list

	static func deserialize(list: Array[Variant]) -> VoteData:
		var o := VoteData.new()
		o.course_name = list.pop_front()
		o.character_id = list.pop_front()
		o.vehicle_id = list.pop_front()
		return o
