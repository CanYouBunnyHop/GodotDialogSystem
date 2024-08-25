class_name DialogSystemGlobalData extends Node
var data : Dictionary = {"a":false,"b":10,"name":"Nick"}
var characterDataDict : Dictionary
var currentDialogSystem : DialogSystem
func _ready():
	pass
	#print("ass"+"\n"+"ass2")
func get_data(key : String, type: Variant.Type = TYPE_INT):
	#will override and create new var if type dont match
	#if dont have key, or has key but type differs 
	if !data.has(key) or typeof(data[key]) != type: 
		match type:
			TYPE_BOOL:
				data[key] = false
			TYPE_INT:
				data[key] = 0
			TYPE_STRING:
				data[key] = ""
		print("This key, "+key+"=", data[key],", has either been created or overriden")
	return data[key]
func set_data(target : String, value, operator:String):
	var type = typeof(value)
	var _tar = get_data(target, type) #makes sure target exist
	if type == TYPE_INT:
		match operator:
			"=":
				data[target] = value
			"+=":
				data[target] += value
			"-=":
				data[target] -= value
			"*=":
				data[target] *= value
			"/=":
				if value != 0: #cannot divide by zero
					data[target] /= value 
				else:
					push_warning("WARNING: tried to divide by 0")
	elif type == TYPE_BOOL:
		match operator:
			"=":
				data[target] = value
			"!=":
				data[target] != value
	elif type == TYPE_STRING:
		match operator:
			"=":
				data[target] = value
			"+=":
				data[target] += value
			"prefix":
				data[target] = value + data[target]
			"suffix":
				data[target] = data[target] + value 
			"prefix_":
				data[target] = value +" "+ data[target]
			"_suffix":
				data[target] = data[target] +" "+ value 
