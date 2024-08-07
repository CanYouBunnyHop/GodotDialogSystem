extends Node

var currentLine = 0
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
var sceneRegex = RegEx.new() #^--(?<SceneName>.+)--$

var varDict = {}
var lockScene : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	nameRegex.compile("^\\w+:")
	toneRegex.compile("\\s\\/\\w+$")
	ignoreRegex.compile("^\\s*#")
	choicesRegex.compile("^\\s*>")
	commandBoxRegex.compile(r'(?:^(?<BoxA>\(.*?\))|)(?<Line>.*(?=\()|.*)(?<BoxB>(?&BoxA)$|)')
	sceneRegex.compile(r'--(?<SceneName>.+)--$')
	
	read_conversationFile(file)
	print("Array size = {size}".format({"size": currentConversation.size()}))
	start_conversation()
func _process(_delta):
	if Input.is_action_just_pressed("Interact") and !lockScene:
		play_next_dialog()
func read_conversationFile(filename : String):
	#if file.file_exists(file) && file.is_file_readable():
		var t = FileAccess.open(filename, FileAccess.READ)
		while !t.eof_reached():
			var line = t.get_line() + "\n" 
			var comment = ignoreRegex.search(line);
			#strips white spaces from left or comment has a match
			if line.strip_edges(true, false).is_empty() or comment != null:
				continue
			currentConversation.append(line)
func get_line(_n = 0):
	var nline = currentLine + _n
	var line = ""
	if nline >= currentConversation.size(): #if index is over array size
		#end conversation
		print("end conversation g")
	else :
		line = currentConversation[nline]
	return line.strip_edges()
func start_conversation():
	currentLine = 0
	read_dialog(currentConversation[currentLine])
func play_next_dialog():
	if currentLine >= currentConversation.size()-1: #if the conversation is over, returns
		#end conversation
		print("end conversation")
		return
	currentLine += 1
	if get_line().is_empty():
		return
	var dialogLine = get_line() # cache the dialog line b4 reading further
	if choicesRegex.search(dialogLine) == null: # don't update the text if it is a choice
		read_dialog(dialogLine)
	while choicesRegex.search(get_line()) != null: # while currentline is a choice, loops
		create_choice_button(get_line()) #ceate button
		if choicesRegex.search(get_line(1)) == null: #if next line is not a choice, break the loop
			break
		currentLine += 1
func read_command_box(line:String)-> RegExMatch:
	var cmdBox : RegExMatch = commandBoxRegex.search(line)
	var content = cmdBox.get_string("BoxA").trim_prefix("(").trim_suffix(")")
	boxA_condition(content)
	return cmdBox
	
func boxA_condition(condition:String)-> bool:
	var c = Command_Listener.conditionRegex.search(condition)
	
	return false
	
func create_choice_button(line):
	lockScene = true
	var butt = Button.new()
	var butttext = line
	#var cmdBox = commandBoxRegex.search(butttext)
	if read_command_box(line).strip_edges().is_empty():
		var box = read_command_box(line) #get box
		butttext = line.left(-box.length()-1) #delete box from line
		var content = box.get_string("Content")#get the content of the box
		butt.pressed.connect(func(): Command_Listener.handle_input(content)) #connect cmds to button
	#default functions for button
	butt.pressed.connect(func(): choice_button_pressed_default(butt, butttext))
	butt.text = butttext
	buttonContainer.add_child(butt)
	#print(str(currentLine)+"button created: "+ butttext)
func choice_button_pressed_default(butt : Button, chosenText = ""):
	for b in buttonContainer.get_children():
		b.queue_free()
		lockScene = false
		dialogBox.text = chosenText

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
