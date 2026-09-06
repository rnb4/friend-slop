extends Interactable


func interact(_interactor_id: int) -> void:
	GameManager.request_start_game.rpc()
