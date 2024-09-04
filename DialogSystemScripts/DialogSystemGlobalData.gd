class_name DialogSystemGlobalData extends Node
var data : Dictionary = {"a":false,"b":10,"name":"Nick"}
var characterDataDict : Dictionary
var dialogSystemDict : Dictionary

var currentDialogSystem : DialogSystem
#for avoiding typos, when adding a custom operator,
#spaces aren't allowed, and suffix it with "="
#BUG auto-complete when defining dictionary is not working
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
var timer : SceneTreeTimer
var interactReady : bool = true
#NOTE not using expression due to it 
#not supporting assignment and too restrictive
var assignmentCallableDict : Dictionary = {
	op.EQUALS : func(_target, value): return value,
	op.NOT_EQUAL : func(_target, value): return !value,
	op.PLUS : func(target, value): return target + value,
	op.MINUS : func(target, value): return target - value,
	op.MULT : func(target, value): return target * value,
	op.DIV : func(target, value): 
		if value != 0: return target / value
		else: Console.debug_warn("tried to divide/ by 0"),
	op.REMAINDER : func(target, value): 
		if value != 0: return target % 0
		else: Console.debug_warn("tried to divide% by 0"),
	op.PREFIX : func(target, value): return value + target,
	op.SUFFIX : func(target, value): return target + value,
	op.PREFFIX_ : func(target, value): return value+" "+target,
	op._SUFFIX : func(target, value): return target+" "+value,
}
func set_current_dialog_system(ID:String):
	DialogSystem.signal_all_set_active.emit(false)
	if dialogSystemDict.has(ID):
		var activeDS:DialogSystem = dialogSystemDict[ID]
		activeDS.isActive = true
		currentDialogSystem = activeDS 
		#currentDialogSystem.visible = false
		#currentDialogSystem = dialogSystemDict[ID]
		#currentDialogSystem.visible = true
		#currentDialogSystem.interacted()
	else: Console.debug_error("Invalid dialog system ID: %s"%[ID])

#NOTE moved back to dialogSystem, 
#maybe you want to have multiple active system?

#func _unhandled_input(_event: InputEvent) -> void:
	#var startCoolDown = func(duration : float):
		#interactReady = false
		#timer = get_tree().create_timer(duration, true, false, true)
		#timer.timeout.connect(func(): interactReady = true)
	#if Input.is_action_just_pressed("Interact") and interactReady:
		#if currentDialogSystem == null: return #return if no dialog system is active
		#currentDialogSystem.interacted()
		##cooldown prevent accidental skipping when spamming Interact
		#startCoolDown.call(0.1)

#func _ready() -> void:
	#var allDS:Array = dialogSystemDict.values()
	#for ds in allDS: ds.visible = false
	#currentDialogSystem.visible = true
	
#TBD may want to move this into set_data()
func get_data(key : String, type: Variant.Type):
	#var validTypes = validTypesDict.keys()
	#will override and create new var if type dont match
	#if dont have key, or has key but type differs
	if !data.has(key) or typeof(data[key]) != type: 
		data[key] = validTypeDefault[type]
		var msg = "data[{0}] = {1} Type:{2}, has either been created or overriden"
		Console.debug_warn(msg.format([key, data[key], validTypesDict[type]]))
	return data[key]
func set_data(targetKey : String, value, operator:String):
	var validTypes = validTypesDict.keys()
	var valType = typeof(value)
	#if value type is not an accepted type
	if not validTypes.any(func(t): return valType==t):
		var vts:= PackedStringArray(validTypesDict.values())
		var msg:String = "CANNOT SET DATA TO AN INVALID TYPE. VALID TYPES: " + ", ".join(vts)
		Console.debug_error(msg)
		return
	#if operator is not an accepted type
	if not validOpDict[valType].any(func(assOp): return operator==assOp):
		var ops:= PackedStringArray(validOpDict[valType])
		var msg="SET DATA FAILED, INVALID OPERATOR: %s /n %s operators are"%[operator,", ".join(ops)]
		Console.debug_error(msg)
		return	
	#get data makes sure target/subject exist,
	#by creating a default value based on type, then assinging to key
	var target = get_data(targetKey, valType)
	var assignmentCallable : Callable = assignmentCallableDict[operator]
	var finalValue = assignmentCallable.call(target, value)
	data[targetKey] = finalValue
