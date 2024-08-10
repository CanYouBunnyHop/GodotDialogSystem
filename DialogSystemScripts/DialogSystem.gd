extends Node

var currentLine :int = 0
var currentScene : Dictionary #dictionary that stores conversations
var currentConversation : Array[String]
var sceneDict : Dictionary = {}
@export var characterNames : Dictionary = {} #for determining color names
@export_file var file
@export var buttonContainer : Node
@export var dialogBox : RichTextLabel

#var nameRegex = RegEx.new() #"/^\w+:" look for name at the start
#var toneRegex = RegEx.new() #"\s\/\w+$" look for tone end of line
#var ignoreRegex = RegEx.new() #"^\s*#" ignores comments
#var choicesRegex = RegEx.new() #"^\s*>"
#var commandBoxRegex = RegEx.new() #\(.*\)$ brackets after a line, but only check behind choices
var lineCaptureRegex = RegEx.new()
var buttonInstructRegex = RegEx.new() #(?<Instruction>disable:)
var sceneRegex = RegEx.new() #^--(?<SceneName>.+)--$

var varDict = {}
var lockScene : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#nameRegex.compile(r'^\w+:')
	#toneRegex.compile(r'\s\/\w+$')
	#ignoreRegex.compile(r'^\s*#')
	#choicesRegex.compile(r'^\s*>')
	#commandBoxRegex.compile(r'(?:^(?<BoxA>\(.*?\))|)(?<Dialogline>.*(?=\()|.*)(?<BoxB>(?&BoxA)$|)')
	lineCaptureRegex.compile(r'^(?:(?<Button>>\s*)|)(?:(?<BoxA>\(.*?\))|)(?:(?<Line>(?:(?<Name>\w+:)|)(?:(?<Dialog>.*(?=\/)|.*))(?:(?<Tone>\/\w+)|))(?=\()|(?&Line))(?<BoxB>(?&BoxA)$|)')
	buttonInstructRegex.compile(r'(?<Instruction>\bdisable:|\bhide:)')
	sceneRegex.compile(r'--(?<SceneName>.+)--$')
	
	read_conversationFile(file)
	print("Array size = {size}".format({"size": currentConversation.size()}))
	start_conversation()
func start_conversation():
	currentLine = 0
	#read_dialog(currentConversation[currentLine])
func _process(_delta):
	if Input.is_action_just_pressed("Interact") and !lockScene:
		play_next_dialog()
func read_conversationFile(filename : String):
	var f = FileAccess.open(filename, FileAccess.READ)
	if f.file_exists(filename):
		while !f.eof_reached():
			var line = (f.get_line() + "\n").strip_edges(true, false) #strips white spaces from left
			var isComment = line.begins_with("#");
			var sceneName = sceneRegex.search(line)
			if line.is_empty() or isComment:
				continue
			currentConversation.append(line)
	else:
		push_error("ERROR: txt file is NOT FOUND")
func get_line(_n = 0)->String:
	var nline = currentLine + _n
	if nline >= currentConversation.size(): #if index is over total dialogline array size
		#end conversation
		print("end conversation g")
		return ""
	else :
		var line = currentConversation[nline]
		return line.strip_edges()
#func strip_command_box(line:String)->String:
	#var lineMatch = commandBoxRegex.search(line)
	#return lineMatch.get_string("Dialogline")
func play_next_dialog():
	if currentLine >= currentConversation.size()-1: #if the conversation is over, returns
		print("end conversation")
		return
	#currentLine += 1
	#print("cur: "+get_line())
	#var lineCaptures = func(_line:String = get_line())-> Dictionary:
		#var line = lineCaptureRegex.search(_line)
		#var isChoice = !line.get_string("Button").is_empty()
		#var boxA = line.get_string("BoxA")
		#var boxB = line.get_string("BoxB")
		#var name_ = line.get_string("Name")
		#var tone = line.get_string("Tone")
		#var dialogLine = line.get_string("Dialog")
		#return {
		#"isChoice":isChoice,
		#"boxA":boxA, 
		#"boxB":boxB, 
		#"name": name_, 
		#"tone":tone, 
		#"dialogLine" : dialogLine}
		
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
	#var tone = toneRegex.search(dialogLine)
	#var name_ = nameRegex.search(dialogLine)
	#if name_ != null:
		#name_ = name_.strings[0]
		#var split = dialogLine.split(":", true, 2)
		#var col = characterNames[split[0]] if characterNames.has(split[0]) else Color.WHITE
		#dialogLine = "[color={c}][b]{name}[/b][/color]: {dialog}".format(
			#{"c": col.to_html(), "name" : split[0], "dialog" : split[1]})
	#if tone != null:
		#tone = tone.strings[0]
		#dialogLine = dialogLine.left(-tone.length())
	dialogBox.text = _name + dialogLine
	print(str(currentLine) + ":" + get_line())
func end_conversation():
	pass
