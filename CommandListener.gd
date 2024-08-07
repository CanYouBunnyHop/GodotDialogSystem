class_name Command_Listener extends Node


var n : 
	get: return Global_Data.data

#var conditionStatementRegex = RegEx.new()
var conditionKeywordRegex = RegEx.new()
var conditionRegex = RegEx.new()
var statementRegex = RegEx.new()
var globalVarRegex = RegEx.new()

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
	conditionKeywordRegex.compile(r'^(if:|elif:|else:)')
	conditionRegex.compile(r'(?<Condition>(?<Subject>[a-zA-Z]+)\s+(?:(?<IntCom>==|!=|<|<=|>|>=)\s+(?<IntObj>\d+|)|(?<BoolCom>is|is_not)\s+(?<BoolObj>true|false|[a-zA-Z]+)))(?:\s+(?<Keyword>and|or)|)(?(Keyword)(?<ConditionB>\s+(?&Condition)))\s*\?')
	statementRegex.compile(r'(?<Statement>then:\s*(?<Target>[a-zA-z]+)\s+(?:(?<IntOp>=|\+=|-=|\*=|\/=)\s*(?<IntVal>\d+|[a-zA-z]+)|(?<BoolOp>is|is_not)\s+(?<BoolVal>true|false|[a-zA-z]+)))')
	handle_input("if: a is true ? then: b is false; else: b is true")
	
static func handle_input(_inputFull : String):
	var commandInputs = _inputFull.split(",", false)
	for input in commandInputs:
		for c in commandList:
			if input.strip_edges().begins_with(c.ID):
				c.execute(input)
func print_something(_arg:String): #for testing
	print(_arg)
func condition_statement(_arg:String):
	var allSteps = _arg.split(";",false)
	for step in allSteps:
		step = step.strip_edges()
		var stepID = conditionKeywordRegex.search(step) #find step ID
		var prefix = stepID.get_string()
		step = step.trim_prefix(prefix).strip_edges() #trim if: elif: or else:
		var condition = conditionRegex.search(step)
		
		match prefix:
			"if:","elif:":
				var subject
				var comparator
				var obj
				var type
				var conditionResults : Array[bool] = []
				#ConA
				subject = condition.get_string("Subject")
				if !condition.get_string("IntCom").is_empty():
					comparator = condition.get_string("IntCom")
					obj = condition.get_string("IntObj")
					type = TYPE_INT
				elif !condition.get_string("BoolCom").is_empty():
					comparator = condition.get_string("BoolCom")
					obj = condition.get_string("BoolObj")
					type = TYPE_BOOL
				conditionResults.append(condition_result(subject,comparator,obj,type))
				
				#if the conditional check end, after the first one, continue
				if condition.get_string("Keyword").is_empty():
					#if true break, else continue
					if conditionResults[0] == true:
						var s = step.trim_prefix(condition.get_string()).strip_edges()
						handle_input(s)
						break
					continue
				#ConB?
				var conditionB = conditionRegex.search(condition.get_string("ConditionB")+"?")
				subject = conditionB.get_string("Subject")
				if !conditionB.get_string("IntCom").is_empty():
					comparator = conditionB.get_string("IntCom")
					obj = conditionB.get_string("IntObj")
					type = TYPE_INT
				elif !conditionB.get_string("BoolCom").is_empty():
					comparator = conditionB.get_string("BoolCom")
					obj = conditionB.get_string("BoolObj")
					type = TYPE_BOOL
				conditionResults.append(condition_result(subject,comparator,obj,type))
				
				var keyWord = condition.get_string("Keyword")
				match keyWord:
					"and":
						if conditionResults[0] == true and conditionResults[1] == true:
							var s = step.trim_prefix(condition.get_string()).strip_edges()
							handle_input(s)
							break
						continue
					"or":
						if conditionResults[0] == true or conditionResults[1] == true:
							var s = step.trim_prefix(condition.get_string()).strip_edges()
							handle_input(s)
							break
						continue
			"else:":
				var s = step.trim_prefix(condition.get_string()).strip_edges()
				handle_input(s)
func condition_result(subject:String, comparator:String, object:String, type:Variant.Type) -> bool:
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
func validate_command_chain(input:String):
	var statements : Array[RegExMatch] = statementRegex.search_all(input)
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
	
	
