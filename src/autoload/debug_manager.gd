extends Node

func _ready() -> void:
	if !OS.is_debug_build():
		process_mode = Node.PROCESS_MODE_DISABLED
		set_process_unhandled_input(false)
		set_physics_process(false)
		set_process_input(false)

func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_F1:
		GameManager._load_lobby()
