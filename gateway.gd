extends Node

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(Global.PORT, Global.MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	print("Server: started")

func _on_peer_connected(id: int) -> void:
	print("Server: peer connected ", id)
	if id in Global.connected_players:
		Util.disconnect_peer_with_error(id, DomainError.GENERIC_ERROR)
		return
	
	var new_player = DomainPlayer.Player.new()
	new_player.peer_id = id
	new_player.username = ""
	Global.initializing_players[id] = new_player;

func _on_peer_disconnected(id: int) -> void:
	var player: DomainPlayer.Player = null
	if id in Global.initializing_players:
		player = Global.initializing_players[id]
		Global.initializing_players.erase(id)
	if id in Global.connected_players:
		player = Global.connected_players[id]
		Global.connected_players.erase(id)
	
	if player and player.room_id:
		Matchmaking.leave_room(player)
	
	print("Server: peer disconnected ", id)

func on_shutdown() -> void:
	for id in multiplayer.get_peers():
		Util.disconnect_peer_with_error(id, DomainError.SERVER_SHUTDOWN)
	var seconds := 0
	while multiplayer.get_peers() and seconds < 5:
		print(multiplayer.get_peers())
		await get_tree().create_timer(1).timeout
		seconds += 1

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		on_shutdown()
		get_tree().quit()
