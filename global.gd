extends Node

const PORT = 31500
const MAX_CLIENTS = 4095

var initializing_players: Dictionary[int, DomainPlayer.Player] = {}
var connected_players: Dictionary[int, DomainPlayer.Player] = {}
var rooms: Dictionary[String, DomainRoom.Room] = {}
