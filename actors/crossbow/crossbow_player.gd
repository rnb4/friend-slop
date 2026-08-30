extends Node3D

@onready var crossbow = %crossbow1
@onready var bolt = %bolt
@onready var _bolt_spawn_point = %BoltSpawnPoint

var _animating: bool = false

signal animation_finished

@rpc("any_peer", "call_local", "unreliable")
func shoot() -> void:
	if _animating:
		return
	_animating = true
	var time:float = crossbow.shoot()
	await get_tree().create_timer(time).timeout
	bolt.visible = false
	_animating = false
	animation_finished.emit()
	
	
@rpc("any_peer", "call_local", "unreliable")
func reload() -> void:
	if _animating:
		return
	_animating = true
	bolt.visible = true
	var time:float = crossbow.reload()
	await get_tree().create_timer(time).timeout
	_animating = false
	animation_finished.emit()

func get_projectile_spawn_location() -> Vector3:
	return _bolt_spawn_point.global_position
