extends Control

#signal sigtest
func _ready() -> void:
	var f = "Hi, {name} v{version}!".format(["Godette","3.0"])
	print(f)
	
#func _unhandled_input(event: InputEvent) -> void:
	#if event == mouse_entered:
		#self.disabled = true
	#sigtest.connect(func(): print_something("ass"))
	#sigtest.emit()
#func print_something(s : String = "Some"):
	#print(s)
