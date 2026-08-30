extends Node

var bolt_launched_scene: PackedScene = preload("uid://b8bnl0mxst53s")
var projectiles : Node3D = Node3D.new()

func _ready() -> void:
	projectiles.name = "Projectiles"
	add_child(projectiles)

### server
@rpc("authority", "call_local", "reliable")
func _create_projectile(player: String, projectile_transform: Transform3D) -> void:
	var bolt: Projectile = bolt_launched_scene.instantiate()
	projectiles.add_child(bolt)
	bolt.global_transform = projectile_transform
	bolt.initialize(player)
	
### client
@rpc("any_peer", "call_local", "unreliable")
func _request_create_projectile(player: String, projectile_transform: Transform3D) -> void:
	if !multiplayer.is_server():
		return
	_create_projectile.rpc(player, projectile_transform)
