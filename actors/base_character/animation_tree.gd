class_name BaseCharacterAnimationTree
extends AnimationTree

@export
var running = false:
	set(value):
		_tween_blend_param("RunBlend", float(value), .25)


var _tween_dict: Dictionary[String, Tween] = {}

func _tween_blend_param(paramid: String, to: float, duration: float) -> void:
	if _tween_dict.has(paramid) and _tween_dict[paramid] != null:
		_tween_dict[paramid].kill()
		_tween_dict.erase(paramid)
	var tween = create_tween()
	tween.tween_property(self, "parameters/%s/blend_amount" % paramid, to, duration)
	tween.tween_callback(func() -> void:
		_tween_dict.erase(paramid)
		tween.kill()
	)
	_tween_dict.set(paramid, tween)
