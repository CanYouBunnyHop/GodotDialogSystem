extends Node
@export var dialogSystems : Array[DialogSystem]

func _ready() -> void:
	GlobalData.currentDialogSystem = dialogSystems[0]
	GlobalData.set_current_dialog_system("A")
	GlobalData.currentDialogSystem.signal_start_convo.emit()
