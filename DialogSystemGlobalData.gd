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
func set_data(targetKey : String, value, operator:String):
	var type = typeof(value)
	var _tar = get_data(targetKey, type) #makes sure target exist
	if type == TYPE_INT:
		match operator:
			"=":
				data[targetKey] = value
			"+=":
				data[targetKey] += value
			"-=":
				data[targetKey] -= value
			"*=":
				data[targetKey] *= value
			"/=":
				if value != 0: #cannot divide by zero
					data[targetKey] /= value 
				else:
					push_warning("WARNING: tried to divide by 0")
	elif type == TYPE_BOOL:
		match operator:
			"=":
				data[targetKey] = value
			"!=":
				data[targetKey] != value
	elif type == TYPE_STRING:
		match operator:
			"=":
				data[targetKey] = value
			"+=":
				data[targetKey] += value
			"prefix":
				data[targetKey] = value + data[targetKey]
			"suffix":
				data[targetKey] = data[targetKey] + value 
			"prefix_":
				data[targetKey] = value +" "+ data[targetKey]
			"_suffix":
				data[targetKey] = data[targetKey] +" "+ value 
