extends Node

@rpc("reliable")
func error(code: int) -> void:
	return

@rpc("reliable")
func initialize_player(data: PackedByteArray) -> void:
	return

@rpc("reliable")
func get_rooms(data: PackedByteArray) -> void:
	return

@rpc("reliable")
func join_random_room(data: PackedByteArray) -> void:
	return
