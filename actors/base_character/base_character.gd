class_name BaseCharacter
extends Node3D

@onready var _animation_tree: BaseCharacterAnimationTree = %AnimationTree
@onready var _head: MeshInstance3D = %Head
@onready var _skeleton: Skeleton3D = %GeneralSkeleton

@export
var running: bool = false:
	set(value):
		running = value
		if _animation_tree:
			_animation_tree.running = value

func _ready() -> void:
	_skeleton.show_rest_only = false
	if is_multiplayer_authority():
		_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
