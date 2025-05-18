extends Node

func _ready() -> void:
	var args = Array(OS.get_cmdline_args())
	if args.has("-s"):
		print("Starting server")
		get_tree().call_deferred("change_scene_to_file", "res://Server.tscn")
	else:
		print("Starting client")
		get_tree().call_deferred("change_scene_to_file", "res://Client.tscn")
