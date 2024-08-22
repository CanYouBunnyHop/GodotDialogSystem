extends Control

var reg = RegEx.new()
func _ready() -> void:
	#CmdListener.handle_input(r'if: %a == false then: %name = "ass" ; else: then: %name = "butt"')
	var a = {"0"=false, "1"="st", "2"="2nd"}
	var o = "this is the {0} {1} {no}string, next up is {2}"
	var n = o.format(a)
	print(n)
	pass
