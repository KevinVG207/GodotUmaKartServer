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
func player_left_room(list: Array[Variant], is_transfer: bool) -> void:
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

@rpc("reliable")
func race_start(ticks_to_start: int, tick_rate: int, ping: int) -> void:
	return

@rpc("unreliable_ordered")
func race_vehicle_state(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func race_spawn_item(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func race_destroy_item(key: String) -> void:
	return

@rpc("unreliable")
func race_item_state(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func race_finished(list: Array[Variant]) -> void:
	return

@rpc("reliable")
func race_item_transfer_owner(key: String, new_owner_id: int) -> void:
	return
