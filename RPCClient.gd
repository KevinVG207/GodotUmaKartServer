extends Node

@rpc("reliable")
func error(code: int) -> void:
	return

@rpc("reliable")
func initialize_player(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func get_rooms(input: Array[Array]) -> void:
	return

@rpc("reliable")
func join_lobby_room(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func join_race_room(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func player_joined_room(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func player_left_room(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func update_lobby(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func receive_final_lobby(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func receive_ping(tick: int) -> void:
	return
