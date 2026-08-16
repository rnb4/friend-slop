class_name Interactable extends Area3D


signal interacted()


@export var prompt: String = "interact"


func interact(_interactor_id: int) -> void:
	interacted.emit()


func try_interact() -> void:
	_interact_request.rpc_id(get_multiplayer_authority())


@rpc("any_peer", "call_local", "reliable")
func _interact_request() -> void:
	if is_multiplayer_authority():
		interact(multiplayer.get_remote_sender_id())
