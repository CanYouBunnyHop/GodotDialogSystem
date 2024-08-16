class_name Global_Data extends Node
static var data : Dictionary = {"a":false,"b":10}
static var characterDataDict : Dictionary
#static var placeHolderDict : Dictionary = {"name": "Red", "ass" : "butt"}
#static var keyRegex = RegEx.new()
#g2 is int, g3 is bool , g4 is name
#static var valueRegex = RegEx.new() #((\d+)|(true|false)|([a-zA-Z]+))
func _ready():
	pass
	#print("ass"+"\n"+"ass2")
static func get_data(key : String, type: Variant.Type):
	if !data.has(key) or typeof(data[key]) != type: #will override and create new var if type dont match
		match type:
			TYPE_BOOL:
				data[key] = false
			TYPE_INT:
				data[key] = 0
			TYPE_STRING:
				data[key] = ""
	return data[key]
static func set_data(target : String, value, operator:String):
	var _tar = get_data(target, typeof(value))
	match operator:
		"=","is":
			data[target] = value
		"is_not":
			data[target] != value
		"+=":
			data[target] += value
		"-=":
			data[target] -= value
		"*=":
			data[target] *= value
		"/=":
			if data[target] / value != 0:
				data[target] /= value 
			else:
				push_warning("WARNING: tried to divide by 0")			
