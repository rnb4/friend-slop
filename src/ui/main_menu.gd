extends Control


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_host_steam_button_pressed() -> void:
	NetworkManager.host_steam_lobby()


func _on_host_local_button_pressed() -> void:
	var err: Error = NetworkManager.host_enet_lobby()
	if err != OK:
		return


func _on_connect_local_button_pressed() -> void:
	var err: Error = NetworkManager.join_enet_lobby()
	if err != OK:
		return
