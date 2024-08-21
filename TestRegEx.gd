extends Control

var reg = RegEx.new()
func _ready() -> void:
	CmdListener.handle_input(r'if: %a == false then: %name = "ass" ; else: then: %name = "butt"')
	pass
	
