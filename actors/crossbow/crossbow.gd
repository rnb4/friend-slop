extends Node3D

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func shoot() -> float:
	animation_player.play("Shoot")
	return animation_player.get_animation("Shoot").length

func reload() -> float:
	animation_player.play("Reload")
	return animation_player.get_animation("Reload").length
	
func reset() -> void:
	animation_player.play("RESET")
