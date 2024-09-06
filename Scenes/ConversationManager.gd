extends Node
@export var dialogSystems : Array[DialogSystem]

func _ready() -> void:
	var d: DialogSystem = DSManager.dialogSystemDict["A"]
	DSManager.focusedSystem = d
	d.sig_focus.emit()
	d.sig_start_convo.emit()
	pass
