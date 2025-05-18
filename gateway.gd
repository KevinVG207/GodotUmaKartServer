extends Node

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(Global.PORT, Global.MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	print("Server: created")
	var r1 := DomainRoom.Lobby.new()
	var r2 := DomainRoom.Race.new()
	Global.rooms[r1.id] = r1
	Global.rooms[r2.id] = r2
	#var r1_data := r1.deserialize()
	#var r1_copy = DomainRoom.Room.serialize(r1_data)

func _on_peer_connected(id: int) -> void:
	print("Server: peer connected ", id)
	if id in Global.connected_players:
		print("ERR: Cannot connect same ID peer")
		disconnect_peer(id)
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
		Global.rooms[player.room_id].players.erase(player)
	
	print("Server: peer disconnected ", id)

func disconnect_peer(id: int) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(id, true)
	
func _exit_tree() -> void:
	for id in Global.initializing_players:
		disconnect_peer(id)
	for id in Global.connected_players:
		disconnect_peer(id)
