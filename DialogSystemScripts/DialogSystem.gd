extends Node

var currentLine = 0
var currentScene : Dictionary #dictionary that stores conversations
var currentConversation : Array[String]
var sceneDict : Dictionary = {}
@export var characterNames : Dictionary = {} #for determining color names
@export_file var file
@export var buttonContainer : Node
@export var dialogBox : RichTextLabel

var nameRegex = RegEx.new() #"/^\w+:" look for name at the start
var toneRegex = RegEx.new() #"\s\/\w+$" look for tone end of line
var ignoreRegex = RegEx.new() #"^\s*#" ignores comments
var choicesRegex = RegEx.new() #"^\s*>"
var commandBoxRegex = RegEx.new() #\(.*\)$ brackets after a line, but only check behind choices
var buttonInstructRegex = RegEx.new() #(?<Instruction>disable:)
var sceneRegex = RegEx.new() #^--(?<SceneName>.+)--$

var varDict = {}
var lockScene : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	nameRegex.compile("^\\w+:")
	toneRegex.compile("\\s\\/\\w+$")
	ignoreRegex.compile("^\\s*#")
	choicesRegex.compile("^\\s*>")
	commandBoxRegex.compile(r'(?:^(?<BoxA>\(.*?\))|)(?<Dialogline>.*(?=\()|.*)(?<BoxB>(?&BoxA)$|)')
	buttonInstructRegex.compile(r'(?<Instruction>\bdisable:|\bhide:)')
	sceneRegex.compile(r'--(?<SceneName>.+)--$')
	
	read_conversationFile(file)
	print("Array size = {size}".format({"size": currentConversation.size()}))
	start_conversation()
func start_conversation():
	currentLine = 0
	read_dialog(currentConversation[currentLine])
func _process(_delta):
	if Input.is_action_just_pressed("Interact") and !lockScene:
		play_next_dialog()
func read_conversationFile(filename : String):
	var t = FileAccess.open(filename, FileAccess.READ)
	if t.file_exists(filename) && t.is_file_readable():
		while !t.eof_reached():
			var line = t.get_line() + "\n" 
			var comment = ignoreRegex.search(line);
			#strips white spaces from left or comment has a match
			if line.strip_edges(true, false).is_empty() or comment != null:
				continue
			currentConversation.append(line)
	else:
		push_error("ERROR: ScreenPlay file is NOT FOUND, or is NOT READABLE")
func get_line(_n = 0)->String:
	var nline = currentLine + _n
	if nline >= currentConversation.size(): #if index is over total dialogline array size
		#end conversation
		print("end conversation g")
		return ""
	else :
		var line = currentConversation[nline]
		return line.strip_edges()
func strip_command_box(line:String)->String:
	var lineMatch = commandBoxRegex.search(line)
	return lineMatch.get_string("Dialogline")
func play_next_dialog():
	if currentLine >= currentConversation.size()-1: #if the conversation is over, returns
		print("end conversation")
		return
	currentLine += 1
	print(currentLine)
	while read_line_boxA_condition(get_line()) == false:
		currentLine += 1
		print(currentLine)
	var dialogLine = strip_command_box(get_line()) #cache line b4 doing choice button check
	#if the first cmd box exist and condition is false, return
	if read_line_boxA_condition(dialogLine) == false: return
	if choicesRegex.search(dialogLine) == null: # don't update the text if it is a choice
		read_dialog(dialogLine)
		
	while choicesRegex.search(strip_command_box(get_line())) != null: # while currentline is a choice, loops
		create_choice_button(get_line()) #ceate button
		var nextline = get_line(1)
		if choicesRegex.search(strip_command_box(nextline)) == null: #if next line is not a choice, break the loop
			break
		currentLine += 1
		
func read_line_boxA_condition(line:String)-> bool:
	var cmdBoxes = commandBoxRegex.search(line)
	if cmdBoxes.get_string("BoxA").is_empty(): return true
	else: #boxa is found
		var boxA = cmdBoxes.get_string("BoxA")
		var content = boxA.trim_prefix("(").trim_suffix(")")
		var condition = Command_Listener.read_condition(content)
		return condition
	
func create_choice_button(line):
	#if the first cmd box exist and condition is false, return
	var boxAcondition = read_line_boxA_condition(line)
	var lineMatch: RegExMatch = commandBoxRegex.search(line) #commandBoxRegex won't return null
	var choiceText = lineMatch.get_string("Dialogline")
	var getInstruction = func()->String:
		if lineMatch.get_string("BoxA").is_empty(): return ""
		var boxA = lineMatch.get_string("BoxA")
		if buttonInstructRegex.search(boxA) == null: return ""
		var construct = buttonInstructRegex.search(boxA)
		var Instruction = construct.get_string("Instruction")
		return Instruction
	var buttonCommands = func():
		if !lineMatch.get_string("BoxB").is_empty():
			var boxBcontent = lineMatch.get_string("BoxB").trim_prefix("(").trim_suffix(")")#get the content of the box
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
	
func read_dialog(dialogLine):
	var tone = toneRegex.search(dialogLine)
	var name_ = nameRegex.search(dialogLine)
	if name_ != null:
		name_ = name_.strings[0]
		var split = dialogLine.split(":", true, 2)
		var col = characterNames[split[0]] if characterNames.has(split[0]) else Color.WHITE
		dialogLine = "[color={c}][b]{name}[/b][/color]: {dialog}".format(
			{"c": col.to_html(), "name" : split[0], "dialog" : split[1]})
	if tone != null:
		tone = tone.strings[0]
		dialogLine = dialogLine.left(-tone.length())
	dialogBox.text = dialogLine
	print(str(currentLine) + ":" + get_line())
func end_conversation():
	pass
