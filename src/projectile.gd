class_name Projectile
extends Node3D

@export var speed: float = 1.0
@export var step_distance: float = 0.25
@export var drop: float = 0.0
@export var damage: float = 35.0
var _player: String = ""

@export_flags_3d_physics
var COLLISION_MASK := 1 << 1 | 2 << 1

var _ray_pos: Vector3

var stopped: bool = false
var _initialized: bool = false
	
func initialize(player: String) -> void:
	_player = player
	_ray_pos = global_position
	_initialized = true

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if stopped:
		return
	if !_initialized:
		return
		
	var direction := -global_transform.basis.z * speed
	direction.y -= drop * delta
	var from := _ray_pos
	var to := from + direction * delta

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		_ray_pos = result["position"]
		hit(result)
		stopped = true
		return

	_ray_pos = to

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		global_position = global_position.move_toward(_ray_pos, speed * delta)
		sync_transform.rpc(_ray_pos, global_transform)

func hit(result: Dictionary) -> void:
	if !multiplayer.is_server():
		return
	var collider : Node3D = result.get("collider")
	if collider != null and collider is Player and collider.name != _player:
		collider.hit.rpc(damage)

@rpc("authority", "unreliable", "call_remote")
func sync_transform(ray_pos: Vector3, new_transform: Transform3D) -> void:
	if multiplayer.is_server():
		return
	
	_ray_pos = ray_pos
	global_transform = new_transform
