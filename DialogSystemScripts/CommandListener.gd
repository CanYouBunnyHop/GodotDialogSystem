class_name CommandListener extends Node
var globaldata : 
	get: return GlobalData.data
var curSystem:
	get: return	GlobalData.currentDialogSystem
#static var currentDialogSystem : DialogSystem
#static var conditionRegex = RegEx.new()
static var conditionRegex = RegEx.new()
var conditionPrefixRegex = RegEx.new()
#var statementRegex = RegEx.new()
var statementRegex = RegEx.new()
var jumpRegex = RegEx.new()
var formatRegex = RegEx.new()

static var commandList : Array[Command]
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
		Command.new("print:","","",func():print("success")),
		]
	conditionPrefixRegex.compile(r'^(if:|elif:|else:)')
	#conditionRegex.compile(r'(?<Condition>(?<Subject>[a-zA-Z]+)\s+(?:(?<IntCom>==|!=|<|<=|>|>=)\s+(?<IntObj>\d+|)|(?<BoolCom>is|is_not)\s+(?<BoolObj>true|false|[a-zA-Z]+)))(?:\s+(?<Keyword>and|or)|)(?(Keyword)(?<ConditionB>\s+(?&Condition)))\s*\?')
	conditionRegex.compile(r'(?<Condition>(?<Subject>%[a-zA-Z]+)\s+(?:(?<IntCom>==|!=|<|<=|>|>=)\s+(?<IntObj>\d+|%[a-zA-Z]+)|(?<BoolCom>is|is_not)\s+(?<BoolObj>true|false|%[a-zA-Z]+)|(?<StrCom>same|diff)\s+(?<StrObj>"[]*"|%[a-zA-Z]+)))(?:\s+(?<Keyword>and|or)|)(?(Keyword)(?<ConditionB>\s+(?&Condition)))\s*\?')
	#statementRegex.compile(r'(?:then:\s*(?<Target>[a-zA-z]+)\s+(?:(?<IntOp>=|\+=|-=|\*=|\/=)\s*(?<IntVal>\d+|[a-zA-z]+)|(?<BoolOp>is|is_not)\s+(?<BoolVal>true|false|[a-zA-z]+)))')
	statementRegex.compile(r'(?:then:\s*(?<Target>%[a-zA-z]+)\s+(?:(?<IntOp>=|\+=|-=|\*=|\/=)\s*(?<IntVal>\d+|%[a-zA-z]+)|(?<BoolOp>is|is_not)\s+(?<BoolVal>true|false|%[a-zA-z]+)|(?<StrOp>same|prefix|suffix|prefix_|suffix_)\s+(?<StrVal>".*?"|%[a-zA-Z]+)))')
	jumpRegex.compile(r'(?:jump:(?:\s*)(?<Flag>\w+\s*?))')
	#Command_Listener.handle_input("if: a is true ? then: b is false; else: then: b is true")

static func handle_input(_inputFull : String):
	var commandInputs = _inputFull.split(",", false)
	for input in commandInputs:
		for i in range(0, commandList.size()):
			var c = commandList[i]
			if input.strip_edges().begins_with(c.ID):
				c.execute(input)
				break
			elif i == (commandList.size()-1):
				push_error("Invalid Command ID")
static func read_condition(step:String)-> bool:
	var subConditionA = conditionRegex.search(step)
	var finalResults : Array = []
	var subConditionResult = func subCondition_result(condition : RegExMatch) -> bool:
		var comparator : String
		var object : String
		var type
		var subject = condition.get_string("Subject") 
		if !condition.get_string("IntCom").is_empty():
			comparator = condition.get_string("IntCom")
			object = condition.get_string("IntObj")
			type = TYPE_INT
		elif !condition.get_string("BoolCom").is_empty():
			comparator = condition.get_string("BoolCom")
			object = condition.get_string("BoolObj")
			type = TYPE_BOOL
		elif !condition.get_string("StrCom").is_empty():
			comparator = condition.get_string("StrCom")
			object = condition.get_string("StrObj")
			type = TYPE_STRING
		var sub = GlobalData.get_data(subject, type)
		var obj
		if object.begins_with("%"):
			obj = GlobalData.get_data(object, type)
		else:
			match type:
				TYPE_INT:
					if int(object) != 0 or object == "0":
						obj = int(object)
					else:
						push_warning("Warning: Invalid object: 
							\"{object}\" of type: \"{type}\"".format({"object":object, "type":type}))
						obj = 0
				TYPE_BOOL:
					match object:
						"true":
							obj = true
						"false":
							obj = false
						_:
							push_warning("Warning: Invalid object: 
								\"{object}\" of type: \"{type}\"".format({"object":object, "type":type}))
							obj = false
				TYPE_STRING:
					obj = object.trim_prefix("\"").trim_suffix("\"")
		match comparator:
				"==","is","same":
					return sub == obj
				"!=","is_not","diff":
					return sub != obj
				"<":
					return sub < obj
				"<=":
					return sub <= obj
				">":
					return sub > obj
				">=":
					return sub >= obj
				_:
					push_error("ERROR: Invalid command comparator: 
						\"{c}\"".format({"c":comparator}))
					return false
	finalResults.append(subConditionResult.call(subConditionA))
	var keyWord = subConditionA.get_string("Keyword") if !subConditionA.get_string("Keyword").is_empty() else ""
	match keyWord:
		"and":
			var subConditionB = conditionRegex.search(subConditionA.get_string("ConditionB")+"?")
			finalResults.append(subConditionResult.call(subConditionB))
			if finalResults[0] == true and finalResults[1] == true:
				var commandChain = step.trim_prefix(subConditionA.get_string()).strip_edges()
				handle_input(commandChain)
				return true
			else:
				return false
		"or":
			var subConditionB = conditionRegex.search(subConditionA.get_string("ConditionB")+"?")
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
			var condition = conditionRegex.search(step)
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
	var thenCommands : Array[RegExMatch] = statementRegex.search_all(input)
	var jumpCommand : RegExMatch = jumpRegex.search(input) # split out then: and jump: command, command chain should only be called when using if command
	#var jump command
	for tcmd in thenCommands:
		var target = tcmd.get_string("Target")
		var operator
		var value
		var type
		if !tcmd.get_string("IntOp").is_empty():
			operator = tcmd.get_string("IntOp")
			value = tcmd.get_string("IntVal")
			type = TYPE_INT
		elif !tcmd.get_string("BoolOp").is_empty():
			operator = tcmd.get_string("BoolOp")
			value = tcmd.get_string("BoolVal")
			type = TYPE_BOOL
		elif !tcmd.get_string("StrOp").is_empty():
			operator = tcmd.get_string("StrOp")
			value = tcmd.get_string("StrVal")
			type = TYPE_STRING
		do_statement(target, operator, value, type)
	var x = jumpCommand.get_string("Flag")
	print(x)
	jump_statement(jumpCommand.get_string("Flag"))
func do_statement(target:String, operator:String, value:String, type:Variant.Type):	
	var val
	if value.begins_with("%"): #if it is getting dictionary
		val = GlobalData.get_data(value, type)
		GlobalData.set_data(target, val, operator)
		return
	match type:
		TYPE_INT:
			if int(value) != 0 or value == "0":
				val = int(value)
			else:
				push_warning("Warning: Invalid value: \"{value}\" of type: \"{type}\"".format({"value":value, "type":type}))
				val = 0
		TYPE_BOOL:
			match value:
				"true":
					val = true
				"false":
					val = false
				_:
					push_warning("Warning: Invalid value: \"{value}\" of type: \"{type}\"".format({"value":value, "type":type}))
					val = false
		TYPE_STRING:
			val = value.trim_prefix("\"").trim_suffix("\"")
	GlobalData.set_data(target, val, operator)
func jump_statement(_flag : String = ""):
	GlobalData.currentDialogSystem.signal_play_next.emit(_flag)
