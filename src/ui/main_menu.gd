class_name MainMenu
extends Control

func _ready() -> void:
	NetworkManager.server_left.connect(_on_server_leave)

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_host_steam_button_pressed() -> void:
	NetworkManager.host_steam_lobby()
	hide()


func _on_host_local_button_pressed() -> void:
	var err: Error = NetworkManager.host_enet_lobby()
	if err != OK:
		return
	hide()

func _on_connect_local_button_pressed() -> void:
	var err: Error = NetworkManager.join_enet_lobby()
	if err != OK:
		return
	hide()

func _on_server_leave() -> void:
	show()
