class_name CommandListener extends Node
var gdata : 
	get: return GlobalData.data
var conditionWithTypeRegex = RegEx.new()
var conditionPrefixRegex = RegEx.new()
var statementWithTypeRegex = RegEx.new()
var jumpRegex = RegEx.new()

#enum OBJ_TYPE{ #(objectType & OBJ_TYPE.EXIST) != OBJ_TYPE.EXIST #example 1001 and 0001 = 0001
	#NULL = 0,
	#EXIST = 1,
	#DAT = 2,
	#INT = 4,
	#BOOL = 8,
	#STR = 16
#}
#var subjectDatExist = GlobalData.data.has(subjectInMatch)
#var finalSubject = GlobalData.data[subjectInMatch] if subjectDatExist else null
#var operation = inRegexMatch.get_string(KEY.OPERATION)
#var objectExist : bool
#var finalObject = null

#"DatObj","IntObj","BoolObj","StrObj"
#Subject, Op, Dat ,Int, Bool, Str


var	debugConsole : LineEdit
var debugConsoleLbl : RichTextLabel
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
		Command.new("print:","","",func(_in : String):print("success")),
		]
	conditionPrefixRegex.compile(r'^(if:|elif:|else:)')
	conditionWithTypeRegex.compile(r'(?<Condition>(?:%(?<Subject>\w+))\s+(?<Op>==|!=|<|<=|>|>=)\s+(?:(?:%(?<DatObj>\w+))|(?<IntObj>\d+)|(?<BoolObj>true|false)|(?:"(?<StrObj>.*?)")))(?:\s+(?<hasKW>and|or))?(?(hasKW)(?<ConditionB>\s+(?&Condition)))')
	statementWithTypeRegex.compile(r'then:\s*(?:%(?<Subject>\w+))\s+(?<Op>=|!=|\+=|-=|\*=|\/=|prefix|suffix|prefix_|_suffix)\s*(?:%(?<DatObj>\w+)|(?<IntObj>\d+)|(?<BoolObj>true|false)|(?:"(?<StrObj>.*?)"))')
	jumpRegex.compile(r'jump:\s*(?<Flag>\w+\s*?)')
	
	var createDebugConsole = func():
		debugConsole = LineEdit.new()
		debugConsole.top_level = true
		debugConsole.set_anchor(SIDE_RIGHT, 1)
		debugConsole.offset_left = 15
		debugConsole.offset_top = 15
		debugConsole.offset_right = -15
		#label stuff
		debugConsoleLbl = RichTextLabel.new()
		debugConsoleLbl.set_anchor(SIDE_RIGHT, 1)
		debugConsoleLbl.offset_left = 15
		debugConsoleLbl.offset_top = 32
		debugConsoleLbl.offset_right = -15
		debugConsoleLbl.offset_bottom = 200
		debugConsoleLbl.bbcode_enabled = true
		add_child(debugConsole)
		debugConsole.add_child(debugConsoleLbl)
		debugConsole.visible = false
	createDebugConsole.call()
	debugConsole.text_submitted.connect(enter_text_input)
	#Command_Listener.handle_input("if: a is true ? then: b is false; else: then: b is true")
	#handle_input("print:")
#func printS(input : String):
	#print("success")
func _input(event: InputEvent) -> void:
	if event.is_action_released("OpenDebugConsole"):
		debugConsole.visible = not debugConsole.visible
		debugConsole.grab_focus()

func enter_text_input(input:String):
	if input.begins_with("/"):
			handle_input(input.trim_prefix("/"))
	debug_log(input)
	debugConsole.clear()

func debug_error(input:String):
	var err = "[color=red]"+"ERROR: "+input+"[/color]"
	debugConsoleLbl.append_text(err)
	debugConsoleLbl.newline()
	
func debug_log(input : String):
	debugConsoleLbl.add_text(input)
	debugConsoleLbl.newline()
		
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
class CmdExpressionResult: #change to struct if it's available
	var subjectExist : bool
	var subject
	var subjectKey : String
	var operation : String
	var objectExist : bool
	var object
	func _init(subExist:bool, subKey:String ,sub, op:String, objExist:bool, obj) -> void:
		self.subjectExist = subExist
		self.subject = sub
		self.subjectKey = subKey
		self.operation = op 
		self.objectExist = objExist
		self.object = obj
func get_expression_regex_returns(inRegexMatch : RegExMatch)-> CmdExpressionResult:
	const OBJ_TYPE = {
		NULL = 0,
		DAT = 1,#0b0001, # 1
		INT = 2,#0b0011, # 3
		BOOL = 3,#0b0101, # 9
		STRING = 4,#0b1001 # 17
	}
	const KEY = {
		SUBJECT = "Subject", OPERATION = "Op", 
		OBJ_DAT = "DatObj", OBJ_INT = "IntObj", 
		OBJ_BOOL = "BoolObj", OBJ_STR = "StrObj",
		}
	const SEARCH_KEY_OBJ_TYPE = [KEY.OBJ_DAT, KEY.OBJ_INT, KEY.OBJ_BOOL, KEY.OBJ_STR]
	var objInMatch : String
	var objectType = OBJ_TYPE.NULL
	#things to return
	var subjectInMatch : String = inRegexMatch.get_string(KEY.SUBJECT)
	var subjectDatExist = GlobalData.data.has(subjectInMatch)
	var finalSubject = GlobalData.data[subjectInMatch] if subjectDatExist else null
	var operation = inRegexMatch.get_string(KEY.OPERATION)
	var objectExist : bool
	var finalObject = null
	for key in SEARCH_KEY_OBJ_TYPE:
		if inRegexMatch.names.has(key):
			objInMatch = inRegexMatch.get_string(key)
			match key:
				KEY.OBJ_DAT:
					if GlobalData.data.has(objInMatch):
						objectType = OBJ_TYPE.DAT
						finalObject = GlobalData.data[objInMatch]
				KEY.OBJ_INT:
					objectType = OBJ_TYPE.INT
					finalObject = int(objInMatch)
				KEY.OBJ_BOOL:
					objectType = OBJ_TYPE.BOOL
					if objInMatch == "true": finalObject = true
					elif objInMatch == "false": finalObject = false
				KEY.OBJ_STR:
					objectType = OBJ_TYPE.STR
					finalObject = objInMatch
			objectExist = objectType != OBJ_TYPE.NULL
			break
	return CmdExpressionResult.new(subjectDatExist, subjectInMatch, finalSubject, operation, objectExist, finalObject)
	
func read_condition(step:String)-> bool:
	var subConditionA = conditionWithTypeRegex.search(step)#conditionRegex.search(step)
	if subConditionA == null:
		push_error("INVALID CONDITION: "+step)
		debug_error("INVALID CONDITION: "+step)
		return false
	var finalResults : Array = []
	var subConditionResult = func(condition : RegExMatch) -> bool:
		if condition == null:
			push_error("CONDITION NOT FOUND, CHECK FOR SYNTAX ERROR")
			debug_error("CONDITION NOT FOUND, CHECK FOR SYNTAX ERROR")
			return false
		var comCmdExResult : CmdExpressionResult = get_expression_regex_returns(condition)
		#too complicated, of either of them dont exist, return false
		if not comCmdExResult.objectExist or not comCmdExResult.subjectExist: return false
		var subject = comCmdExResult.subject
		var object = comCmdExResult.object
		var subjectType = 	typeof(subject)
		var comparator = comCmdExResult.operation
		#return if types dont match
		if typeof(object) != subjectType:
			push_error("OBJECT TYPE DOES NOT MATCH SUBJECT TYPE")
			debug_error("OBJECT TYPE DOES NOT MATCH SUBJECT TYPE")
			return false
		if subjectType == TYPE_INT:
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
					push_error("ERROR: Invalid command comparator")
					debug_error("ERROR: Invalid command comparator")
					return false
		else: #not an interger
			match comparator:
				"==": #int, bool, string
					return subject == object
				"!=": #int, bool, string
					return subject != object
				_:
					push_error("ERROR: Invalid command comparator")
					debug_error("ERROR: Invalid command comparator")
					return false
	finalResults.append(subConditionResult.call(subConditionA)) #return result if keyword dont exist
	var keyWord = subConditionA.get_string("Keyword")
	match keyWord:
		"and":
			var subConditionB = conditionWithTypeRegex.search(subConditionA.get_string("ConditionB"))
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
			debug_error("Invalid Condition Container")
func validate_command_chain(input:String):
	var thenCommands : Array[RegExMatch] = statementWithTypeRegex.search_all(input)
	var jumpCommand : RegExMatch = jumpRegex.search(input)
	#split out then: and jump: command
	for tcmd in thenCommands:
		var assgnmntCmdExResult : CmdExpressionResult = get_expression_regex_returns(tcmd)
		var targetKey = assgnmntCmdExResult.subjectKey
		var value = assgnmntCmdExResult.object
		var operator = assgnmntCmdExResult.operation
		GlobalData.set_data(targetKey, value, operator)#if data doesn't previously exist, it will create a new one
	if jumpCommand == null: return
	jump_statement(jumpCommand.get_string("Flag"))
func jump_statement(_flag : String = ""):
	GlobalData.currentDialogSystem.signal_play_next.emit(_flag)
