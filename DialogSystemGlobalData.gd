class_name DialogSystemGlobalData extends Node
static var data : Dictionary = {"%a":false,"%b":10}
static var characterDataDict : Dictionary
static var currentDialogSystem : DialogSystem
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
		"=","is","same":
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
		"prefix":
			data[target] = value + data[target]
		"suffix":
			data[target] = data[target] + value 
		"prefix_":
			data[target] = value +" "+ data[target]
		"suffix_":
			data[target] + data[target] +" "+ value 
