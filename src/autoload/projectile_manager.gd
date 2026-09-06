extends Node

var _projectiles : Node3D = Node3D.new()

func _ready() -> void:
	_projectiles.name = "Projectiles"
	add_child(_projectiles)

### server
@rpc("authority", "call_local", "reliable")
func _create_projectile(player: String, projectile_scene_path: String, projectile_transform: Transform3D) -> void:
	var projectile_scene: PackedScene = load(projectile_scene_path)
	var projectile: Projectile = projectile_scene.instantiate()
	_projectiles.add_child(projectile)
	projectile.global_transform = projectile_transform
	projectile.initialize(player)
	
### client
@rpc("any_peer", "call_local", "unreliable")
func _request_create_projectile(player: String, projectile_scene_path: String, projectile_transform: Transform3D) -> void:
	if !multiplayer.is_server():
		return
	_create_projectile.rpc(player, projectile_scene_path, projectile_transform)
