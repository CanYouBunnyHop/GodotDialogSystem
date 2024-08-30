class_name DialogSystemGlobalData extends Node
var data : Dictionary = {"a":false,"b":10,"name":"Nick"}
var characterDataDict : Dictionary
var dialogSystemCollection : Dictionary
var currentDialogSystem : DialogSystem
#for avoiding typos, when adding a custom operator, 
#spaces aren't allowed, and suffix it with "="
const op = {
	EQUALS = "=",
	NOT_EQUAL = "!=",
	PLUS = "+=",
	MINUS = "-=",
	MULT = "*=",
	DIV = "/=",
	REMAINDER = "%=",
	PREFIX = "prefix=",
	SUFFIX = "suffix=",
	PREFFIX_= "prefix_=",
	_SUFFIX= "_suffix=",
}
#this, along side with condition and statement regex 
#will be used for allowing data to hold certain data types
#assign a string for used for debugging
const validTypesDict = {
	TYPE_INT : "INT", 
	TYPE_BOOL : "BOOL", 
	TYPE_STRING : "STRING",
}
const validTypeDefault = {
	TYPE_INT : 0, 
	TYPE_BOOL : false, 
	TYPE_STRING : "",
}
const validOpDict = {
	TYPE_INT : ["=", "+=", "-=", "*=", "/=", "%="],
	TYPE_BOOL : ["=", "!="],
	TYPE_STRING : ["=","+=", op.PREFIX, op.SUFFIX, op.PREFFIX_, op._SUFFIX],
}
#not using expression due to it not supporting assignment, 
#also may have too many potential unique cases to really be clean
var assignmentCallableDict : Dictionary = {
	op.EQUALS : func(target, value): return value,
	op.NOT_EQUAL : func(target, value): return !value,
	op.PLUS : func(target, value): return target + value,
	op.MINUS : func(target, value): return target - value,
	op.MULT : func(target, value): return target * value,
	op.DIV : func(target, value): 
		if value != 0: return target / value
		else: CmdListener.debug_warn("tried to divide/ by 0"),
	op.REMAINDER : func(target, value): 
		if value != 0: return target % 0
		else: CmdListener.debug_warn("tried to divide% by 0"),
	op.PREFIX : func(target, value): return value + target,
	op.SUFFIX : func(target, value): return target + value,
	op.PREFFIX_ : func(target, value): return value+" "+target,
	op._SUFFIX : func(target, value): return target+" "+value,
}

func _ready():
	pass
func get_data(key : String, type: Variant.Type = TYPE_INT):
	var validTypes = validTypesDict.keys()
	#if type is not an accepted type
	if not validTypes.any(func(t): return type==t):
		var vts:= PackedStringArray(validTypesDict.values())
		var msg:String = "CANNOT GET INVALID TYPE. VALID TYPES: " + ", ".join(vts)
		CmdListener.debug_error(msg)
		return
	#will override and create new var if type dont match
	#if dont have key, or has key but type differs
	if !data.has(key) or typeof(data[key]) != type: 
		#match type:
			#TYPE_BOOL:
				#data[key] = false
			#TYPE_INT:
				#data[key] = 0
			#TYPE_STRING:
				#data[key] = ""
		data[key] = validTypeDefault[type]
		var msg = "data[{0}] = {1} Type:{2}, has either been created or overriden"
		CmdListener.debug_warn(msg.format([key, data[key], validTypesDict[type]]))
	return data[key]
func set_data(targetKey : String, value, operator:String):
	var validTypes = validTypesDict.keys()
	var valType = typeof(value)
	#if value type is not an accepted type
	if not validTypes.any(func(t): return valType==t):
		var vts:= PackedStringArray(validTypesDict.values())
		var msg:String = "CANNOT SET DATA TO AN INVALID TYPE. VALID TYPES: " + ", ".join(vts)
		CmdListener.debug_error(msg)
		return
	#if operator is not an accepted type
	if not validOpDict[valType].any(func(op): return operator==op):
		var ops:= PackedStringArray(validOpDict[valType])
		var msg="SET DATA FAILED, INVALID OPERATOR: %s /n %s operators are"%[operator,", ".join(ops)]
		CmdListener.debug_error(msg)
		return	
	# get data makes sure target/subject exist,
	# by creating a default value based on type, then assinging to key
	var target = get_data(targetKey, valType)
	var assignmentCallable : Callable = assignmentCallableDict[operator]
	var finalValue = assignmentCallable.call(target, value)
	data[targetKey] = finalValue
	#match operator:
		#"=":
			#data[targetKey] = value
		#"!=":
			#data[targetKey] != value
		#"+=":
			#data[targetKey] += value
		#"-=":
			#data[targetKey] -= value
		#"*=":
			#data[targetKey] *= value
		#"/=":
			#if value != 0: #cannot divide by zero
				#data[targetKey] /= value 
			#else:
				#push_warning("WARNING: tried to divide/ by 0")
		#"%=":
			#if value != 0: #cannot divide by zero
				#data[targetKey] %= value
			#else:
				#push_warning("WARNING: tried to divide% by 0")
		#"prefix=":
			#data[targetKey] = value + data[targetKey]
		#"suffix=":
			#data[targetKey] = data[targetKey] + value 
		#"prefix_=":
			#data[targetKey] = value +" "+ data[targetKey]
		#"_suffix=":
			#data[targetKey] = data[targetKey] +" "+ value 
	#op.EQUALS : func(target, value): target = value,
	#op.NOT_EQUAL : func(target, value): target != value,
	#op.PLUS : func(target, value): target += value,
	#op.MINUS : func(target, value): target -= value,
	#op.MULT : func(target, value): target *= value,
	#op.DIV : func(target, value): 
	#if value != 0: target /= 0
	#else: 	push_warning("WARNING: tried to divide/ by 0"),
	#op.REMAINDER : func(target, value): 
	#if value != 0: target /= 0
	#else: 	push_warning("WARNING: tried to divide% by 0"),
	
	
	
	
	
	
	
	#var type = typeof(value)
	#get_data(targetKey, type) #makes sure target/subject exist
	#var setDataEx = Expression.new()
	
	#if valType == TYPE_INT:
		##setDataEx.parse("sub {0} value".format([operator]))
		#match operator:
			#"=":
				#data[targetKey] = value
			#"+=":
				#data[targetKey] += value
			#"-=":
				#data[targetKey] -= value
			#"*=":
				#data[targetKey] *= value
			#"/=":
				#if value != 0: #cannot divide by zero
					#data[targetKey] /= value 
				#else:
					#push_warning("WARNING: tried to divide/ by 0")
			#"%=":
				#if value != 0: #cannot divide by zero
					#data[targetKey] %= value
				#else:
					#push_warning("WARNING: tried to divide% by 0")
	#elif valType == TYPE_BOOL:
		#match operator:
			#"=":
				#data[targetKey] = value
			#"!=":
				#data[targetKey] != value
	#elif valType == TYPE_STRING:
		#match operator:
			#"=":
				#data[targetKey] = value
			#"+=":
				#data[targetKey] += value
			#"prefix=":
				#data[targetKey] = value + data[targetKey]
			#"suffix=":
				#data[targetKey] = data[targetKey] + value 
			#"prefix_=":
				#data[targetKey] = value +" "+ data[targetKey]
			#"_suffix=":
				#data[targetKey] = data[targetKey] +" "+ value 
