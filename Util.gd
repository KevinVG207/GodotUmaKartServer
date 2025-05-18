extends Node

func add_player_to_room(player: DomainPlayer.Player, room_id: String) -> void:
	if player.room_id:
		return
	player.room_id = room_id
	Global.rooms[room_id].players.append(player)
	print("Added player ", player.peer_id, " to room ", room_id)
