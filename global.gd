extends Node

const PORT = 31500
const MAX_CLIENTS = 4095

var initializing_players: Dictionary[int, DomainPlayer.Player] = {}
var connected_players: Dictionary[int, DomainPlayer.Player] = {}
var rooms: Dictionary[String, DomainRoom.Room] = {}

func _physics_process(_delta: float) -> void:
	for room in rooms.values():
		match room.type:
			DomainRoom.RoomType.LOBBY:
				var lobby := room as DomainRoom.Lobby
				lobby.process()
				return
			DomainRoom.RoomType.RACE:
				var race := room as DomainRoom.Race
				race.process()
				return
