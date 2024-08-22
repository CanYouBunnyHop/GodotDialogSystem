class_name CommandListener extends Node
var globaldata : 
	get: return GlobalData.data
var curSystem:
	get: return	GlobalData.currentDialogSystem
#static var currentDialogSystem : DialogSystem
var conditionWithTypeRegex = RegEx.new()
#static var conditionRegex = RegEx.new()
var conditionPrefixRegex = RegEx.new()
var statementWithTypeRegex = RegEx.new()
#var statementRegex = RegEx.new()
var jumpRegex = RegEx.new()
var formatRegex = RegEx.new()

enum {
	OBJ_EXIST = 1,
	OBJ_DAT = 2,
	OBJ_INT = 4,
	OBJ_BOOL = 8,
	OBJ_STR = 16
}
var commandList : Array[Command]
func _ready():
	commandList = [
		Command.new("if:", "Checks Condition, if true, then do action",
		"<if:|elif:|else:> <subject> <comparator> <object> <and|or> <second condition> <?> <command> <;>",
		read_condition_container),
		Command.new("then:", "Updates variable or creates a new one if it doesn't exist", 
		"then: <target> <operator> <value>", validate_command_chain),
		Command.new("jump:", "jump to a flag in the conversation", "jump: <flag>", validate_command_chain),
		Command.new("emotion:", "change current portrait to specified portrait","emotion: <name> <emotion>", 
		validate_command_chain),
		Command.new("format:", "format string, swapping out placeholders", r'format: <"a" "b" "c">', validate_command_chain),
		Command.new("print:","","",func(_input : String):print("_input")),
		]
	conditionPrefixRegex.compile(r'^(if:|elif:|else:)')
	conditionWithTypeRegex.compile(r'(?<Condition>(?:%(?<Subject>\w+))\s+(?<Com>==|!=|<|<=|>|>=)\s+(?:(?:%(?<DatObj>\w+))|(?<IntObj>\d+)|(?<BoolObj>true|false)|(?:"(?<StrObj>.*?)")))(?:\s+(?<Keyword>(?<hasKW>and|or)|))(?(hasKW)(?<ConditionB>\s+(?&Condition)))')
	#statementRegex.compile(r'(?:then:\s*(?<Target>[a-zA-z]+)\s+(?:(?<IntOp>=|\+=|-=|\*=|\/=)\s*(?<IntVal>\d+|[a-zA-z]+)|(?<BoolOp>is|is_not)\s+(?<BoolVal>true|false|[a-zA-z]+)))')
	#conditionRegex.compile(r'(?<Condition>(?<Subject>(?<=%)\w+)\s+(?:(?<IntCom>==|!=|<|<=|>|>=)\s+(?<IntObj>\d+|%\w+)|(?<BoolCom>is|is_not)\s+(?<BoolObj>true|false|%\w+)|(?<StrCom>same|diff)\s+(?<StrObj>".*"|%\w+)))(?:\s+(?<Keyword>and|or)|)(?(Keyword)(?<ConditionB>\s+(?&Condition)))\s*\?(?!.*\?)')
	statementWithTypeRegex.compile(r'then:\s*(?:%(?<Target>\w+))\s+(?<Op>=|!=|\+=|-=|\*=|\/=|prefix|suffix|prefix_|_suffix)\s*(?:%(?<DatVal>\w+)|(?<IntVal>\d+)|(?<BoolVal>true|false)|(?:"(?<StrVal>.*?)"))')
	#statementRegex.compile(r'(?:then:\s*(?<Target>%\w+)\s+(?:(?<IntOp>=|\+=|-=|\*=|\/=)\s*(?<IntVal>\d+|%\w+)|(?<BoolOp>is|is_not)\s+(?<BoolVal>true|false|%\w+)|(?<StrOp>same|prefix|suffix|prefix_|suffix_)\s+(?<StrVal>".*?"|%\w+)))')
	jumpRegex.compile(r'jump:\s*(?<Flag>\w+\s*?)')
	formatRegex.compile(r'"(?<Str>.*?)"')
	#Command_Listener.handle_input("if: a is true ? then: b is false; else: then: b is true")
	#handle_input("print:")
#func printS(input : String):
	#print("success")
func handle_input(_inputFull : String):
	var commandInputs = _inputFull.split(",", false)
	for input in commandInputs:
		for i in range(0, commandList.size()):
			var c = commandList[i]
			if input.strip_edges().begins_with(c.ID):
				c.execute(input)
				break
			elif i == (commandList.size()-1):
				push_error("Invalid Command ID")
func read_condition(step:String)-> bool:
	var subConditionA = conditionWithTypeRegex.search(step)#conditionRegex.search(step)
	if subConditionA == null:
		push_error("INVALID CONDITION: "+step) 
		return false
	var finalResults : Array = []
	var subConditionResult = func(condition : RegExMatch) -> bool:
		if condition == null:
			push_error("CONDITION NOT FOUND, CHECK FOR SYNTAX ERROR")
			return false
		var comparator : String = condition.get_string("Com")
		var subjStr = condition.get_string("Subject")
		var objStr
		#find which one exist
		var subDatExist : bool = false
		var objType : int = 0
		var object
		if GlobalData.data.has(subjStr): subDatExist = true
		var searchObjKey : Array[String] = ["DatObj","IntObj","BoolObj","StrObj"]
		for k in searchObjKey:
			if condition.names.has(k):
				objStr = condition.get_string(k) # get string of one of the obj match
				match k:
					"DatObj":
						objType |= OBJ_DAT
						if GlobalData.data.has(objStr):
							objType |= OBJ_EXIST
							object = GlobalData.data[objStr]
					"IntObj":
						objType |= OBJ_INT | OBJ_EXIST
						object = int(objStr)
					"BoolObj":
						objType |= OBJ_BOOL | OBJ_EXIST
						if objStr == "true": object = true
						elif objStr == "false": object = false
					"StrObj":
						objType |= OBJ_STR | OBJ_EXIST
						object = objStr
				break
		#if both don't exist, return false
		if !subDatExist and (objType & OBJ_EXIST) != OBJ_EXIST: return false
		var subject
		if subDatExist: # if subject data exist
			subject = GlobalData.data[subjStr]
			if objType == OBJ_DAT: 
				object = GlobalData.get_data(objStr, typeof(subject))
		else: #subject data dont exist
			subject = GlobalData.get_data(subjStr, typeof(object))
			
		var type = 	typeof(subject)
		#return if types dont match
		if typeof(object) != type:
			push_error("OBJECT TYPE DOES NOT MATCH SUBJECT TYPE")
			return false
		if type == TYPE_INT:
			match comparator:
				"==": #int, bool, string
					return subject == object
				"!=": #int, bool, string
					return subject != object
				"<":
					return subject < object
				"<=":
					return subject <= object
				">":
					return subject > object
				">=":
					return subject >= object
				_:
					push_error("ERROR: Invalid command comparator: 
						\"{c}\"".format({"c":comparator}))
					return false
		else: #not an interger
			match comparator:
				"==": #int, bool, string
					return subject == object
				"!=": #int, bool, string
					return subject != object
				_:
					push_error("ERROR: Invalid command comparator: 
						\"{c}\"".format({"c":comparator}))
					return false
		#var obj
		#match key:
			#"IntObj":
				#obj = int(objStr)
			#"BoolObj":
				#if objStr == "true": obj = true
				#elif objStr == "false": obj = false
			#"StrObj":
				#obj = objStr
			#"DatObj": #if object is a search key in globaldata
				#if GlobalData.data.has(objStr): #if object exist in Global data
					#objExist = true
					#obj = GlobalData.data[objStr] # get existing data
				#else: #if object does not exist 
					#if GlobalData.data.has(subjStr):
						#var subtype = typeof(GlobalData.data[subjStr])
						#obj = GlobalData.get_data(objStr, subtype)
					#else:
						#push_error("CONDITION OBJECT AND SUBJECT NOT FOUND, CONDITION WILL RETURN FALSE")
						#return false
					#type = typeof(GlobalData.data[objStr])
					
		#if !condition.get_string("IntCom").is_empty():
			#comparator = condition.get_string("IntCom")
			#object = condition.get_string("IntObj")
			#type = TYPE_INT
		#elif !condition.get_string("BoolCom").is_empty():
			#comparator = condition.get_string("BoolCom")
			#object = condition.get_string("BoolObj")
			#type = TYPE_BOOL
		#elif !condition.get_string("StrCom").is_empty():
			#comparator = condition.get_string("StrCom")
			#object = condition.get_string("StrObj").trim_prefix("\"").trim_suffix("\"")
			#type = TYPE_STRING
			
		#var type = typeof(obj)
		#so when creating new data entry, type will match
		#var sub = GlobalData.get_data(subjStr) 
		#var obj
		#if object.begins_with("%"):
			#obj = GlobalData.get_data(object, type)
		#else:
			#match type:
				#TYPE_INT:
					#if int(object) != 0 or object == "0":
						#obj = int(object)
					#else:
						#push_warning("Warning: Invalid object: 
							#\"{object}\" of type: \"{type}\"".format({"object":object, "type":type}))
						#obj = 0
				#TYPE_BOOL:
					#match object:
						#"true":
							#obj = true
						#"false":
							#obj = false
						#_:
							#push_warning("Warning: Invalid object: 
								#\"{object}\" of type: \"{type}\"".format({"object":object, "type":type}))
							#obj = false
				#TYPE_STRING:
					#obj = object.trim_prefix("\"").trim_suffix("\"")
	finalResults.append(subConditionResult.call(subConditionA)) #return result if keyword dont exist	
	var keyWord = subConditionA.get_string("Keyword") #if !subConditionA.get_string("Keyword").is_empty() else ""
	match keyWord:
		"and":
			var subConditionB = conditionWithTypeRegex.search(subConditionA.get_string("ConditionB")+"?")
			finalResults.append(subConditionResult.call(subConditionB))
			if finalResults[0] == true and finalResults[1] == true:
				var commandChain = step.trim_prefix(subConditionA.get_string()).strip_edges()
				handle_input(commandChain)
				return true
			else:
				return false
		"or":
			var subConditionB = conditionWithTypeRegex.search(subConditionA.get_string("ConditionB")+"?")
			finalResults.append(subConditionResult.call(subConditionB))
			if finalResults[0] == true or finalResults[1] == true:
				var commandChain = step.trim_prefix(subConditionA.get_string()).strip_edges()
				handle_input(commandChain)
				return true
			else:
				return false
		_:
			return finalResults[0]
func read_condition_container(_arg:String):
	var allSteps = _arg.split(";",false)
	for step in allSteps:
		step = step.strip_edges()
		var prefix = conditionPrefixRegex.search(step).get_string() #find prefix
		step = step.trim_prefix(prefix).strip_edges() #trim if: elif: or else:
		if prefix == "if:" or prefix == "elif:":
			var result = CmdListener.read_condition(step)
			var condition = conditionWithTypeRegex.search(step)
			if result == true:
				var commandChain = step.trim_prefix(condition.get_string()).strip_edges()
				CmdListener.handle_input(commandChain)
				break
			else:
				continue
		elif prefix == "else:": #prefix is else
			CmdListener.handle_input(step)
			break
		else:
			push_error("Invalid Condition Container")
func validate_command_chain(input:String):
	var thenCommands : Array[RegExMatch] = statementWithTypeRegex.search_all(input)
	var jumpCommand : RegExMatch = jumpRegex.search(input) # split out then: and jump: command, command chain should only be called when using if command
	#var jump command
	for tcmd in thenCommands:
		var target = tcmd.get_string("Target")#
		var operator = tcmd.get_string("Op")#
		var valStr#
		#var type#
		#var tarDatExist : bool = true if GlobalData.data.has(target) else false	
		var _valType : int = 0#
		var val#
		var searchValType : Array = ["DatVal", "IntVal", "BoolVal", "StrVal"]#
		for k in searchValType:
			if tcmd.names.has(k):
				valStr = tcmd.get_string(k)
				match k:
					"DatVal":
						_valType |= OBJ_DAT
						if GlobalData.data.has(valStr):
							_valType |= OBJ_EXIST
					"IntVal":
						_valType |= OBJ_INT | OBJ_EXIST
						val = int(valStr)
					"BoolVal":
						_valType |= OBJ_BOOL | OBJ_EXIST
						if valStr == "true": val = true
						if valStr == "false": val = false
					"StrVal":
						_valType |= OBJ_STR | OBJ_EXIST
						val = valStr
		#var tar
		#if !tarDatExist and (valType & OBJ_EXIST) != OBJ_EXIST:
			#push_error("INVALID THEN STATEMENT")
			#return
		#if tarDatExist: #target exist
			#tar = GlobalData.data[target]
			#if valType == OBJ_DAT: #if valType = dat and does not exist
				#val = GlobalData.get_data(valStr, typeof(tar))
		#else :#target data don't exist
			#match valType:
				#OBJ_INT | OBJ_EXIST:
					#tar = GlobalData.get_data(target, TYPE_INT)
				#OBJ_BOOL | OBJ_EXIST:
					#tar = GlobalData.get_data(target, TYPE_BOOL)
				#OBJ_STR | OBJ_EXIST:
					#tar = GlobalData.get_data(target, TYPE_STRING)
		GlobalData.set_data(target, val, operator)		
			
			#if valType & OBJ_EXIST != 1:
				
		#if !tcmd.get_string("IntOp").is_empty():
		
			#operator = tcmd.get_string("IntOp")
			#value = tcmd.get_string("IntVal")
			#type = TYPE_INT
		#elif !tcmd.get_string("BoolOp").is_empty():
			#operator = tcmd.get_string("BoolOp")
			#value = tcmd.get_string("BoolVal")
			#type = TYPE_BOOL
		#elif !tcmd.get_string("StrOp").is_empty():
			#operator = tcmd.get_string("StrOp")
			#value = tcmd.get_string("StrVal")
			#type = TYPE_STRING
		#do_statement(subject, operator, value, type, target)
	if jumpCommand == null: return
	var x = jumpCommand.get_string("Flag")
	print(x)
	jump_statement(jumpCommand.get_string("Flag"))
#func do_statement(target:String, operator:String, value, type:Variant.Type, _new_target:String = target):	
	#var val
	#if value.begins_with("%"): #if it is getting dictionary
		#val = GlobalData.get_data(value, type)
		#GlobalData.set_data(target, val, operator)
		#return
	#match type:
		#TYPE_INT:
			#if int(value) != 0 or value == "0":
				#val = int(value)
			#else:
				#push_warning("Warning: Invalid value: \"{value}\" of type: \"{type}\"".format({"value":value, "type":type}))
				#val = 0
		#TYPE_BOOL:
			#match value:
				#"true":
					#val = true
				#"false":
					#val = false
				#_:
					#push_warning("Warning: Invalid value: \"{value}\" of type: \"{type}\"".format({"value":value, "type":type}))
					#val = false
		#TYPE_STRING:
			#val = value.trim_prefix("\"").trim_suffix("\"")
	#GlobalData.set_data(target, val, operator)
func jump_statement(_flag : String = ""):
	GlobalData.currentDialogSystem.signal_play_next.emit(_flag)
