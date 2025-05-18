extends Node

signal initialize_player_result(player: DomainPlayer.Player)
@rpc("reliable")
func initialize_player(data: PackedByteArray) -> void:
	return

signal get_rooms_result(rooms: Array[DomainRoom.Room])
@rpc("reliable")
func get_rooms(data: PackedByteArray) -> void:
	return
