class_name LineCapture #TBD TODO convert to struct if available
var isChoice : bool
var boxA : String #command box a
var boxB : String #command box b
var boxACon : bool
var full : String #this is name + dialog + bbtag
var name : String
var dialog : String
var bbtag : String

const EXBOXCMD : String = r'[^\(\)]*'
static var commandCaptureRegex:RegEx = RegEx.new():
	get:
		if not commandCaptureRegex.is_valid(): commandCaptureRegex.compile(r'^(?<Button>>\s*)?(?:\((?<BoxA>{c})\))?(?<Line>.*?)\s*(?:\((?!.*\()(?<BoxB>{c})\))?$'.format({"c":EXBOXCMD}))
		return commandCaptureRegex
static var dialogCaptureRegex:RegEx = RegEx.new():
	get:
		if not dialogCaptureRegex.is_valid(): dialogCaptureRegex.compile(r'(?:^(?:(?<Name>.*):|)(?:(?<Dialog>.*?)))(\[(?!.*\[)(?<BBTag>.*)\]|)$')
		return dialogCaptureRegex
const INSTRUCT = {BUTTON_HIDE = "hide:", BUTTON_DISABLE = "disable:"}
const BUTTON_INSTRUCTIONS = [INSTRUCT.BUTTON_HIDE, INSTRUCT.BUTTON_DISABLE]

func _init(_line:String) -> void:
	var no_group_return_empty= func(rmatch:RegExMatch, group:String)->String:
		if rmatch.names.has(group): return rmatch.get_string(group)
		else: return ""
	var cmdMatch = commandCaptureRegex.search(_line)
	isChoice = !no_group_return_empty.call(cmdMatch,"Button").is_empty()
	boxA = no_group_return_empty.call(cmdMatch, "BoxA").strip_edges()
	boxB = no_group_return_empty.call(cmdMatch, "BoxB").strip_edges()
	boxACon = (func():
		if boxA.is_empty(): return true
		#NOTE instructions are used when condition are false
		#we return here so command listener won't debug errors 
		if BUTTON_INSTRUCTIONS.any(func(i): return i == boxA): return false 
		var condition = CmdListener.read_condition(boxA)
		return condition).call()
	var line = no_group_return_empty.call(cmdMatch,"Line") #line is in-between cmdbox
	var	dialogLine = dialogCaptureRegex.search(line)
	full = dialogLine.get_string()
	name = no_group_return_empty.call(dialogLine,"Name")
	dialog = no_group_return_empty.call(dialogLine,"Dialog")
	bbtag =  no_group_return_empty.call(dialogLine,"BBTag")
	
func is_displayable()->bool:
	if boxACon == false or isChoice or full.is_empty(): return false
	else: return true
