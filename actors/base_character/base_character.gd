class_name BaseCharacter
extends Node3D

@onready var _animation_tree: BaseCharacterAnimationTree = %AnimationTree
@onready var _head: MeshInstance3D = %Head
@onready var _skeleton: Skeleton3D = %GeneralSkeleton

var _character_material: StandardMaterial3D

@export
var running: bool = false:
	set(value):
		running = value
		if _animation_tree:
			_animation_tree.running = value

func _ready() -> void:
	_skeleton.show_rest_only = false
	_character_material = StandardMaterial3D.new()
	if is_multiplayer_authority():
		_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	for child in _skeleton.get_children():
		if child is MeshInstance3D:
			var surfaces : int = child.get_surface_override_material_count()
			for i in range(surfaces):
				child.set_surface_override_material(i, _character_material)

func hit_anim() -> void:
	var tween := create_tween()
	tween.tween_property(_character_material, "albedo_color", Color.RED, .25)
	tween.tween_property(_character_material, "albedo_color", Color.WHITE, .25)
