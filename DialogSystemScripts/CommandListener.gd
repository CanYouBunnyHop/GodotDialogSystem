class_name Command_Listener extends Node


var n : 
	get: return Global_Data.data

#var conditionStatementRegex = RegEx.new()
var conditionPrefixRegex = RegEx.new()
static var conditionRegex = RegEx.new()
var statementRegex = RegEx.new()
var jumpRegex = RegEx.new()

static var commandList : Array[Command]
func _ready():
	commandList = [
		Command.new("ps", "prints string", "PS <something>", print_something),
		Command.new("if:", "Checks Condition, if true, then do action", 
		"<if:|elif:|else:> <subject> <comparator> <object> <and|or> <second condition> <?> <command> <;>",
		condition_statement),
		Command.new("then:", "Updates variable or creates a new one if it doesn't exist", 
		"then: <target> <operator> <value>", validate_command_chain)
		]
	conditionPrefixRegex.compile(r'^(if:|elif:|else:)')
	conditionRegex.compile(r'(?<Condition>(?<Subject>[a-zA-Z]+)\s+(?:(?<IntCom>==|!=|<|<=|>|>=)\s+(?<IntObj>\d+|)|(?<BoolCom>is|is_not)\s+(?<BoolObj>true|false|[a-zA-Z]+)))(?:\s+(?<Keyword>and|or)|)(?(Keyword)(?<ConditionB>\s+(?&Condition)))\s*\?')
	statementRegex.compile(r'(?<Statement>then:\s*(?<Target>[a-zA-z]+)\s+(?:(?<IntOp>=|\+=|-=|\*=|\/=)\s*(?<IntVal>\d+|[a-zA-z]+)|(?<BoolOp>is|is_not)\s+(?<BoolVal>true|false|[a-zA-z]+)))')
	#jumpRegex.compile(r'')
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
func print_something(_arg:String): #for testing
	print(_arg)
##Steps are seperated by ";" split b4 parsing
static func read_condition(step:String)-> bool:
	var conditionA = conditionRegex.search(step)
	var finalResults : Array = []
	var result = func condition_result(condition : RegExMatch) -> bool:
		var subject
		var comparator
		var object
		var type
		subject = condition.get_string("Subject")
		if !condition.get_string("IntCom").is_empty():
			comparator = condition.get_string("IntCom")
			object = condition.get_string("IntObj")
			type = TYPE_INT
		elif !condition.get_string("BoolCom").is_empty():
			comparator = condition.get_string("BoolCom")
			object = condition.get_string("BoolObj")
			type = TYPE_BOOL
		var sub = Global_Data.get_data(subject, type)
		var obj
		if type == TYPE_INT:
			if int(object) != 0 or object == "0":
				obj = int(object)
			else:
				push_warning("Warning: Invalid object: 
					\"{object}\" of type: \"{type}\"".format({"object":object, "type":type}))
				obj = Global_Data.get_data(object, type)
		elif type == TYPE_BOOL:
			match object:
				"true":
					obj = true
				"false":
					obj = false
				_:
					push_warning("Warning: Invalid object: 
						\"{object}\" of type: \"{type}\"".format({"object":object, "type":type}))
					obj = Global_Data.get_data(object, type)
		else:
			obj = Global_Data.get_data(object, type)
		match comparator:
				"==","is":
					return sub == obj
				"!=","is_not":
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
	
	finalResults.append(result.call(conditionA))
	var keyWord = conditionA.get_string("Keyword") if !conditionA.get_string("Keyword").is_empty() else ""
	match keyWord:
		"and":
			var conditionB = conditionRegex.search(conditionA.get_string("ConditionB")+"?")
			finalResults.append(result.call(conditionB))
			if finalResults[0] == true and finalResults[1] == true:
				var s = step.trim_prefix(conditionA.get_string()).strip_edges()
				handle_input(s)
				return true
			else:
				return false
		"or":
			var conditionB = conditionRegex.search(conditionA.get_string("ConditionB")+"?")
			finalResults.append(result.call(conditionB))
			if finalResults[0] == true or finalResults[1] == true:
				var s = step.trim_prefix(conditionA.get_string()).strip_edges()
				handle_input(s)
				return true
			else:
				return false
		_:
			return finalResults[0]
	
func condition_statement(_arg:String):
	var allSteps = _arg.split(";",false)
	for step in allSteps:
		step = step.strip_edges()
		var prefix = conditionPrefixRegex.search(step).get_string() #find prefix
		step = step.trim_prefix(prefix).strip_edges() #trim if: elif: or else:
		if prefix == "if:" or prefix == "elif:":
			var result = Command_Listener.read_condition(step)
			var condition = conditionRegex.search(step)
			if result == true:
				var s = step.trim_prefix(condition.get_string()).strip_edges()
				Command_Listener.handle_input(s)
				break
			else:
				continue
		elif prefix == "else:": #prefix is else
			Command_Listener.handle_input(step)
			break
		else:
			push_error("Invalid Condition_Statement")
func validate_command_chain(input:String):
	var statements : Array[RegExMatch] = statementRegex.search_all(input)
	#var jumpInstruct : RegExMatch # split out then: and jump: command, command chain should only be called when using if command
	#var jump command
	for s in statements:
		var target = s.get_string("Target")
		var operator
		var value
		var type2
		if !s.get_string("IntOp").is_empty():
			operator = s.get_string("IntOp")
			value = s.get_string("IntVal")
			type2 = TYPE_INT
		elif !s.get_string("BoolOp").is_empty():
			operator = s.get_string("BoolOp")
			value = s.get_string("BoolVal")
			type2 = TYPE_BOOL
		do_statement(target, operator, value, type2)
func do_statement(target:String, operator:String, value:String, type:Variant.Type):
	var val
	if type == TYPE_INT:
		if int(value) != 0 or value == "0":
			val = int(value)
		else:
			push_warning("Warning: Invalid value: 
				\"{value}\" of type: \"{type}\"".format({"value":value, "type":type}))
			val = Global_Data.get_data(value, type)
	elif type == TYPE_BOOL:
		match value:
			"true":
				val = true
			"false":
				val = false
			_:
				push_warning("Warning: Invalid value: 
					\"{value}\" of type: \"{type}\"".format({"value":value, "type":type}))
				val = Global_Data.get_data(value, type)
	Global_Data.set_data(target, val, operator)
	
	
