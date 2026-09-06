extends Tool

@export var projectile_spawn_distance: float = 2.0

@onready var crossbow = %crossbow1
@onready var bolt = %bolt
@onready var _bolt_spawn_point = %BoltSpawnPoint

@export_file("*.tscn") var bolt_launched_scene_path: String = "uid://b8bnl0mxst53s"

var _animating: bool = false
var _ammo: int = 1
var _max_ammo: int = 1
var _reloading: bool = false

signal animation_finished

func use() -> void:
	if _player == null or _player.player_type != Enums.PlayerType.Hunter:
		return
	if _ammo <= 0 or _reloading or _animating:
		return

	_ammo -= 1
	_shoot_anim.rpc()
	await animation_finished

	var camera := get_parent() as Camera3D
	var projectile_transform := global_transform.looking_at(
		camera.global_position - camera.global_transform.basis.z * projectile_spawn_distance * 100
	)
	projectile_transform.origin = get_projectile_spawn_location()
	GameManager._request_create_projectile.rpc_id(1, _player.name, bolt_launched_scene_path, projectile_transform)

func reload() -> void:
	if _player == null or _player.player_type != Enums.PlayerType.Hunter:
		return

	if _reloading or _animating:
		return

	_reloading = true
	_reload_anim.rpc()
	await animation_finished
	_reloading = false
	_ammo = _max_ammo

func equip() -> void:
	pass

func unequip() -> void:
	pass

@rpc("any_peer", "call_local", "unreliable")
func _shoot_anim() -> void:
	if _animating:
		return
	_animating = true
	var time:float = crossbow.shoot()
	await get_tree().create_timer(time).timeout
	bolt.visible = false
	_animating = false
	animation_finished.emit()
	
@rpc("any_peer", "call_local", "unreliable")
func _reload_anim() -> void:
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
