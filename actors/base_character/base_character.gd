class_name BaseCharacter
extends Node3D

@onready var _animation_tree: BaseCharacterAnimationTree = %AnimationTree
@onready var _head: MeshInstance3D = %Head
var running: bool = false:
	set(value):
		running = value
		_animation_tree.running = value

func _ready() -> void:
	if is_multiplayer_authority():
		_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
