extends Interactable


@export var count: int = 0

@onready var label: Label3D = %Label3D


func _process(_delta: float) -> void:
	label.text = str(count)


func interact(_interactor_id: int) -> void:
	count += 1
