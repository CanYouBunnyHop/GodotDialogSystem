class_name CommandListener extends Node
#This is a Autoload singleton called CMDListener
var conditionWithTypeRegex = RegEx.new()
var conditionPrefixRegex = RegEx.new() #TODO Use const dict instead
var statementWithTypeRegex = RegEx.new()
var jumpRegex = RegEx.new()
var commandList : Array[Command]
func command_helper(input:String):
	var splits:PackedStringArray = input.split(" ", false, 2)
	if splits.size() == 1:
		var cmdIDs : PackedStringArray=commandList.map(func(c:Command):return c.ID)
		Console.debug_log(" ".join(cmdIDs))
		Console.debug_log(r'See more info by adding command to help. eg: "/help: help:"')
	else: #when larger than 1
		var cmdArg = splits[1]
		for c in commandList:
			if cmdArg == c.ID:
				Console.debug_log("command: {0}\ndescription: {1}\nformat:{2}".format([c.ID, c.description, c.format]))
				return
		Console.debug_error("Invalid help command argument")
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
		Command.new("jump:", "jump to a flag in the conversation", "jump: ID=<dsid> FLAG=<flag>", validate_command_chain),
		#Command.new("emotion:", "change current portrait to specified portrait","emotion: <name> <emotion>", 
		#validate_command_chain),
		Command.new("end:", "hide active dialog system and set focused dialog system to null", 
		"end:", func(_nan):DSManager.sig_interact_blocker.connect(func():DSManager.end_conversation(), CONNECT_ONE_SHOT)),
		Command.new("print:","","",func(_in : String):print("success")),
		]
	conditionPrefixRegex.compile(r'^(if:|elif:|else:)') #TODO use const dict
	conditionWithTypeRegex.compile(r'(?<Condition>(?:%(?<Subject>\w+))\s+(?<Op>==|!=|<|<=|>|>=)\s+(?:(?:%(?<DatObj>\w+))|(?<IntObj>\d+)|(?<BoolObj>true|false)|(?:"(?<StrObj>.*?)")))(?:\s+(?<hasKW>and|or))?(?(hasKW)(?<ConditionB>\s+(?&Condition)))')
	statementWithTypeRegex.compile(r'then:\s*(?:%(?<Subject>\w+))\s+(?<Op>[^= ]*=)\s*(?:%(?<DatObj>\w+)|(?<IntObj>\d+)|(?<BoolObj>true|false)|(?:"(?<StrObj>.*?)"))')
	jumpRegex.compile(r'jump:\s*(ID=\s*(?<DSID>\w+))?\s*(FLAG=\s*(?<Flag>\w+))?')
func handle_input(_inputFull : String):
	var commandInputs = _inputFull.split(",", false)
	for input in commandInputs:
		for i in range(0, commandList.size()):
			var c = commandList[i]
			if input.strip_edges().begins_with(c.ID):
				c.execute(input)
				break
			elif i == (commandList.size()-1):
				Console.debug_error("Invalid Command ID")
class CmdExpressionResult: #NOTE TODO change to struct if it's available
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
	var subjectDatExist = DSManager.data.has(subjectInMatch)
	var finalSubject = DSManager.data[subjectInMatch] if subjectDatExist else null
	var operation = inRegexMatch.get_string(KEY.OPERATION)
	var objectExist : bool
	var finalObject = null
	for key in [KEY.OBJ_DAT, KEY.OBJ_INT, KEY.OBJ_BOOL, KEY.OBJ_STR]:
		if inRegexMatch.names.has(key):
			objInMatch = inRegexMatch.get_string(key)
			match key:
				KEY.OBJ_DAT:
					if DSManager.data.has(objInMatch):
						objectType = OBJ_TYPE.DAT
						finalObject = DSManager.data[objInMatch]
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
	var subConditionA = conditionWithTypeRegex.search(step)
	if subConditionA == null:
		Console.debug_error("CONDITION NOT FOUND: "+step)
		return false
	var finalResults : Array = []
	var subConditionResult = func(condition : RegExMatch) -> bool:
		if condition == null: #probably not needed, but just in case
			Console.debug_error("CONDITION NOT FOUND, CHECK FOR SYNTAX ERROR")
			return false
		#will return the real typing for those variables
		var comCmdExResult : CmdExpressionResult = get_expression_regex_returns(condition)
		#if either of them dont exist, return false
		if not comCmdExResult.objectExist or not comCmdExResult.subjectExist: return false
		var subject = comCmdExResult.subject
		var object = comCmdExResult.object
		var comparator = comCmdExResult.operation
		var comparison := Expression.new()
		comparison.parse("{0}{1}{2}".format([subject,comparator,object]))
		var comparisonResult = comparison.execute()
		#return false if types dont match or invalid operator
		if comparison.has_execute_failed(): 
			var err = comparison.get_error_text()
			Console.debug_error(err+" "+condition.get_string())
			return false
		else: return comparisonResult
	finalResults.append(subConditionResult.call(subConditionA))
	match subConditionA.get_string("Keyword"):
		"and":
			var subConditionB = conditionWithTypeRegex.search(subConditionA.get_string("ConditionB"))
			finalResults.append(subConditionResult.call(subConditionB))
			if finalResults[0] == true and finalResults[1] == true:
				var commandChain = step.trim_prefix(subConditionA.get_string()).strip_edges()
				handle_input(commandChain)
				return true
			else: return false
		"or":
			var subConditionB = conditionWithTypeRegex.search(subConditionA.get_string("ConditionB")+"?")
			finalResults.append(subConditionResult.call(subConditionB))
			if finalResults[0] == true or finalResults[1] == true:
				var commandChain = step.trim_prefix(subConditionA.get_string()).strip_edges()
				handle_input(commandChain)
				return true
			else: return false
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
			else: continue
		elif prefix == "else:":
			CmdListener.handle_input(step)
			break
		else: Console.debug_error("Invalid Condition Container")
#TBD MIGHT REMOVE COMMAND CHAINING ? 
#THIS WILL BE HARD TO MAINTAIN WHEN MORE COMMANDS ARE AVAILABLE
func validate_command_chain(input:String):
	var thenCommands : Array[RegExMatch] = statementWithTypeRegex.search_all(input)
	var jumpCommand : RegExMatch = jumpRegex.search(input)
	#split out then: and jump: command
	for tcmd in thenCommands:
		assignment_command(tcmd)
	if jumpCommand == null: return
	DSManager.sig_interact_blocker.connect(func():jump_command(jumpCommand), CONNECT_ONE_SHOT)
func assignment_command(tcmd : RegExMatch):
	var assgnmntCmdExResult : CmdExpressionResult = get_expression_regex_returns(tcmd)
	var targetKey = assgnmntCmdExResult.subjectKey
	var value = assgnmntCmdExResult.object
	var operator = assgnmntCmdExResult.operation
	DSManager.set_data(targetKey, value, operator)
func jump_command(jcmd : RegExMatch):
	if jcmd.names.has("DSID"):
		DSManager.set_focus(jcmd.get_string("DSID"))
	if jcmd.names.has("Flag"):
		DSManager.focusedSystem.play_next_dialog(jcmd.get_string("Flag"))
	else: DSManager.focusedSystem.play_next_dialog()
