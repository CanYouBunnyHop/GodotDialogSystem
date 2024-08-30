class_name CommandListener extends Node
var gdata : 
	get: return GlobalData.data
var conditionWithTypeRegex = RegEx.new()
var conditionPrefixRegex = RegEx.new()
var statementWithTypeRegex = RegEx.new()
var jumpRegex = RegEx.new()

var	debugConsoleEdit : LineEdit
var debugConsoleLbl : RichTextLabel
var commandList : Array[Command]
func command_helper(input:String):
	var splits:PackedStringArray = input.split(" ", false, 2)
	if splits.size() == 1:
		var cmdIDs : PackedStringArray=commandList.map(func(c:Command):return c.ID)
		debug_log(" ".join(cmdIDs))
		debug_log(r'See more info by adding command to help. eg: "/help: help:"')
	else: #when larger than 1
		var cmdArg = splits[1]
		for c in commandList:
			if cmdArg == c.ID:
				debug_log("command: {0}\ndescription: {1}\nformat:{2}".format([c.ID, c.description, c.format]))
				return
		debug_error("Invalid help command argument")
func _ready():
	#a command callable has to take in a string parameter
	commandList = [
		Command.new("help:", "See command list or more infor about a certain command", "help: <CommandID>",
		command_helper),
		Command.new("if:", "Checks Condition, if true, then do action",
		"<if:|elif:|else:> <subject> <comparator> <object> <and|or> <second condition> <;>",
		read_condition_container),
		Command.new("then:", "Updates variable or creates a new one if it doesn't exist", 
		"then: <target> <operator> <value>", validate_command_chain),
		Command.new("jump:", "jump to a flag in the conversation", "jump: <flag>", validate_command_chain),
		#Command.new("emotion:", "change current portrait to specified portrait","emotion: <name> <emotion>", 
		#validate_command_chain),
		Command.new("print:","","",func(_in : String):print("success")),
		]
	conditionPrefixRegex.compile(r'^(if:|elif:|else:)')
	conditionWithTypeRegex.compile(r'(?<Condition>(?:%(?<Subject>\w+))\s+(?<Op>==|!=|<|<=|>|>=)\s+(?:(?:%(?<DatObj>\w+))|(?<IntObj>\d+)|(?<BoolObj>true|false)|(?:"(?<StrObj>.*?)")))(?:\s+(?<hasKW>and|or))?(?(hasKW)(?<ConditionB>\s+(?&Condition)))')
	statementWithTypeRegex.compile(r'then:\s*(?:%(?<Subject>\w+))\s+(?<Op>[^= ]*=)\s*(?:%(?<DatObj>\w+)|(?<IntObj>\d+)|(?<BoolObj>true|false)|(?:"(?<StrObj>.*?)"))')
	jumpRegex.compile(r'jump:\s*(?<Flag>\w+\s*?)')
	var createDebugConsole = func():
		debugConsoleEdit = LineEdit.new()
		debugConsoleEdit.top_level = true
		debugConsoleEdit.set_anchor(SIDE_RIGHT, 1)
		debugConsoleEdit.offset_left = 15
		debugConsoleEdit.offset_top = 15
		debugConsoleEdit.offset_right = -15
		#construct label
		debugConsoleLbl = RichTextLabel.new()
		debugConsoleLbl.top_level = true
		debugConsoleLbl.scroll_active = true
		debugConsoleLbl.scroll_following = true
		debugConsoleLbl.set_anchor(SIDE_RIGHT, 1)
		debugConsoleLbl.offset_left = 15
		debugConsoleLbl.offset_top = 46
		debugConsoleLbl.offset_right = -15
		debugConsoleLbl.offset_bottom = 210
		debugConsoleLbl.bbcode_enabled = true
		add_child(debugConsoleEdit)
		debugConsoleEdit.add_child(debugConsoleLbl)
		debugConsoleEdit.visible = false
	createDebugConsole.call()
	debugConsoleEdit.text_submitted.connect(enter_text_input)
	#Command_Listener.handle_input("if: a is true ? then: b is false; else: then: b is true")
	#handle_input("print:")
#func printS(input : String):
	#print("success")
func _input(event: InputEvent) -> void:
	if event.is_action_released("OpenDebugConsole"):
		debugConsoleEdit.visible = not debugConsoleEdit.visible
		debugConsoleEdit.grab_focus()
func enter_text_input(input:String):
	if input.begins_with("/"): handle_input(input.trim_prefix("/"))
	else: debug_log("User: "+input)
	debugConsoleEdit.clear()
func debug_warn(input:String):
	var warn = "[color=orange]"+"WARNING: "+input+"[/color]"
	push_warning(input)
	print_rich(warn)
	debugConsoleLbl.append_text(warn)
	debugConsoleLbl.newline()
func debug_error(input:String):
	var err = "[color=red]"+"ERROR: "+input+"[/color]"
	push_error(input)
	print_rich(err)
	debugConsoleLbl.append_text(err)
	debugConsoleLbl.newline()
func debug_log(input : String):
	print(input)
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
				debug_error("Invalid Command ID")
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
		NULL = 0, DAT = 1, INT = 2,
		BOOL = 3, STRING = 4,
		}
	const KEY = {
		SUBJECT = "Subject", OPERATION = "Op", 
		OBJ_DAT = "DatObj", OBJ_INT = "IntObj", 
		OBJ_BOOL = "BoolObj", OBJ_STR = "StrObj",
		}
	var objInMatch : String
	var objectType = OBJ_TYPE.NULL
	#things to return
	var subjectInMatch : String = inRegexMatch.get_string(KEY.SUBJECT)
	var subjectDatExist = GlobalData.data.has(subjectInMatch)
	var finalSubject = GlobalData.data[subjectInMatch] if subjectDatExist else null
	var operation = inRegexMatch.get_string(KEY.OPERATION)
	var objectExist : bool
	var finalObject = null
	for key in [KEY.OBJ_DAT, KEY.OBJ_INT, KEY.OBJ_BOOL, KEY.OBJ_STR]:
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
		debug_error("INVALID CONDITION: "+step)
		return false
	var finalResults : Array = []
	var subConditionResult = func(condition : RegExMatch) -> bool:
		if condition == null: #probably not needed, but just in case
			debug_error("CONDITION NOT FOUND, CHECK FOR SYNTAX ERROR")
			return false
		#will return the real typing for those variables
		var comCmdExResult : CmdExpressionResult = get_expression_regex_returns(condition)
		#if either of them dont exist, return false
		if not comCmdExResult.objectExist or not comCmdExResult.subjectExist: return false
		var subject = comCmdExResult.subject
		var object = comCmdExResult.object
		var subjectType = typeof(subject)
		var comparator = comCmdExResult.operation
		
		var comparison := Expression.new()
		comparison.parse("{0}{1}{2}".format([subject,comparator,object]))
		var comparisonResult = comparison.execute()
		#return false if types dont match or invalid operator
		if comparison.has_execute_failed(): 
			var err = comparison.get_error_text()
			debug_error(err+" "+condition.get_string())
			return false
		else:
			return comparisonResult
	finalResults.append(subConditionResult.call(subConditionA)) 
	
	match subConditionA.get_string("Keyword"):
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
		_: #return first result if keyword dont exist
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
		GlobalData.set_data(targetKey, value, operator)
	if jumpCommand == null: return
	jump_statement(jumpCommand.get_string("Flag"))
func jump_statement(_flag : String = ""):
	GlobalData.currentDialogSystem.signal_play_next.emit(_flag)
