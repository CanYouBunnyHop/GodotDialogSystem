class_name Dialog_System extends Node

var currentLine :int = -1
var flagDict : Dictionary = {}
var currentConversation : Array[String] = []

#@export var characterNames : Dictionary = {} #for determining color names
@export_file("*.txt") var file
@export var buttonContainer : Node
@export var dialogBox : RichTextLabel

var lineCaptureRegex = RegEx.new()
var buttonInstructRegex = RegEx.new() #(?<Instruction>disable:)
var flagRegex = RegEx.new() #^--(?<Flag>\s*\w+\s*)--
var lockScene : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	lineCaptureRegex.compile(r'^(?:(?<Button>>\s*)|)(?:(?<BoxA>\(.*?\))|)(?:(?<Line>(?:(?<Name>\w+):|)(?:(?<Dialog>.*(?=\/)|.*))(?:(?<Tone>\/\w+)|))(?=\()|(?&Line))(?<BoxB>(?&BoxA)$|)')
	buttonInstructRegex.compile(r'(?<Instruction>\bdisable:|\bhide:)')
	flagRegex.compile(r'^--(?<Flag>\s*\w+\s*)--')
	read_conversationFile(file)
	print("Array size = {size}".format({"size": currentConversation.size()}))
	
	#for testing
	Command_Listener.currentDialogSystem = self
	
	#var temp = "dude ass dude"
	#var col = Color.AQUA.to_html()
	#var beforeFormat = "%s"+temp+"%s"
	#var afterFormat = beforeFormat%["[color={c}]","[/color]"]
	#var applyColor = afterFormat.format({"c":col})
	#dialogBox.text = applyColor
	#var redData = Global_Data.characterDataDict["Red"]
	#print(redData.has("color"))
	
	#start_from_beginning()
func start_from_beginning():
	currentLine = -1
	play_next_dialog()
func _process(_delta):
	if Input.is_action_just_pressed("Interact") and !lockScene:
		play_next_dialog()
func read_conversationFile(filename : String):
	var flagName = "start"
	var f = FileAccess.open(filename, FileAccess.READ)
	if f.file_exists(filename):
		while !f.eof_reached():
			var line = f.get_line().strip_edges(true, false) #strips white spaces from left
			var isComment = line.begins_with("#")
			if line.is_empty() or isComment:
				continue
			var flag = flagRegex.search(line)
			if flag != null: 
				flagName = flag.get_string("Flag").strip_edges()
				flagDict[flagName] = currentConversation.size()-1
				continue
			currentConversation.append(line)
	else:
		push_error("ERROR: txt file is NOT FOUND")
func get_line(_n = 0)->String:
	var nline = currentLine + _n
	if nline >= currentConversation.size(): #if index is over total dialogline array size
		return ""
	else :
		var line = currentConversation[nline]
		return line.strip_edges()

func play_next_dialog(_flagName : String = ""):
	if _flagName != "":
		currentLine = flagDict[_flagName] - 1
	if currentLine >= currentConversation.size()-1: #if the conversation is over, returns
		print("end conversation")
		return
		
	while true:
		currentLine += 1
		var snapshot : Dictionary = capture_line(get_line())
		var isChoice = snapshot["isChoice"]
		var boxA = snapshot["boxA"]
		if isChoice or read_boxA_condition(boxA) == true:
			break
	var currentCaptures : Dictionary = capture_line(get_line())
	if read_boxA_condition(currentCaptures["boxA"]) and not currentCaptures["isChoice"]:
		display_dialogLine(currentCaptures["dialogLine"], currentCaptures["name"])
	#display buttons
	while capture_line(get_line())["isChoice"]:#lineCaptureRegex.search(get_line()).get_string("Button").is_empty(): # while currentline is a choice, loops
		create_choice_button(get_line()) #ceate button
		var nextline = get_line(1)
		if not capture_line(nextline)["isChoice"]: #if next line is not a choice, break the loop
			break
		currentLine += 1
		
func read_boxA_condition(boxA:String)-> bool:
	if boxA.is_empty(): return true
	var content = boxA.trim_prefix("(").trim_suffix(")")
	if content.strip_edges().is_empty(): return true
	var condition = Command_Listener.read_condition(content)
	return condition
	
func capture_line(_line:String = get_line())-> Dictionary:
	var line = lineCaptureRegex.search(_line)
	var isChoice = !line.get_string("Button").is_empty()
	var boxA = line.get_string("BoxA")
	var boxB = line.get_string("BoxB")
	var name_ = line.get_string("Name")
	var tone = line.get_string("Tone")
	var dialogLine = line.get_string("Dialog")
	return {
	"isChoice":isChoice,
	"boxA":boxA, 
	"boxB":boxB, 
	"name": name_, 
	"tone":tone, 
	"dialogLine" : dialogLine}
	
func create_choice_button(_line):
	#if the first cmd box exist and condition is false, return
	var captures = capture_line(_line) #commandBoxRegex won't return null
	var boxA = captures["boxA"]
	var boxAcondition = read_boxA_condition(boxA)
	var boxB = captures["boxB"]
	var choiceText = ">"+captures["dialogLine"]
	
	var getInstruction = func()->String:
		if boxA.is_empty(): return ""
		if buttonInstructRegex.search(boxA) == null: return ""
		var construct = buttonInstructRegex.search(boxA)
		var Instruction = construct.get_string("Instruction")
		return Instruction
	var buttonCommands = func():
		if !boxB.is_empty():
			var boxBcontent = boxB.trim_prefix("(").trim_suffix(")")#get the content of the box
			Command_Listener.handle_input(boxBcontent) #connect cmds to button
		for b in buttonContainer.get_children():
			b.queue_free()
			lockScene = false
		dialogBox.text = choiceText
	lockScene = true
	var constructInstruction = getInstruction.call()
	#boxa == false, ins == hide > return
	#boxa == false, ins == disable or default > disable
	#boxa == true, always create button normally
	var isDisabled = false
	if boxAcondition == false:
		match constructInstruction:
			"hide:":
				return
			"disable:",_:
				isDisabled = true
	var choiceButt : Button = Button.new()
	choiceButt.text = choiceText
	buttonContainer.add_child(choiceButt)
	choiceButt.disabled = isDisabled
	choiceButt.pressed.connect(func(): buttonCommands.call())
	
func display_dialogLine(dialogLine: String, _name:String = "", _tone:String = ""):
	var applyColor = func(_text:String, _color:String)->String:
		var beforeFormat = "%s"+_text+"%s"
		var afterFormat = beforeFormat%["[color={c}]","[/color]"]
		var result = afterFormat.format({"c":_color})
		return result
	var col = Color.WHITE.to_html()
	if Global_Data.characterDataDict.has(_name):
		var curCharacterData = Global_Data.characterDataDict[_name]
		if curCharacterData.has("color"):
			col = curCharacterData["color"]
	var BBName = applyColor.call(_name, col)
	var BoldBBName = apply_bbcode(BBName+":","b")
	dialogBox.text = BoldBBName + dialogLine
	print(str(currentLine) + ":" + get_line())
func apply_bbcode(_text: String, _BBTag:String, _override: String = "")->String:
	var result = "[{0}{1}]{2}[/{0}]".format([_BBTag, _override, _text])
	return result
func end_conversation():
	pass
