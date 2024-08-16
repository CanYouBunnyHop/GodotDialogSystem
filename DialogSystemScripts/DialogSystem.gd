class_name DialogSystem extends Node

var currentLine :int = -1
var flagDict : Dictionary = {"beginning": 0}
var currentConversation : Array[String] = []

#@export var characterNames : Dictionary = {} #for determining color names
@export_file("*.txt") var file
@export var buttonContainer : Node
@export var dialogBox : RichTextLabel
@export var dialogPortrait : Sprite2D
@export var settings : DialogSystemSettings

var commandCaptureRegex = RegEx.new()
var dialogCaptureRegex = RegEx.new()
var buttonInstructRegex = RegEx.new() #(?<Instruction>disable:)
var flagRegex = RegEx.new() #^--(?<Flag>\s*\w+\s*)--

var lockScene : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	commandCaptureRegex.compile(r'^(?:(?<Button>>\s*)|)(?:(?:\((?<BoxA>[^\(\)]*)\))|)(?<Line>[^\(]*)\s*(?:(?:\((?<BoxB>[^\(\)]*)\))|)')
	dialogCaptureRegex.compile(r'(?:(?<Name>.*):|)(?:(?<Dialog>[^\[]*))(?:\s*\[(?<BBTag>.*)]|)')
	#lineCaptureRegex.compile(r'^(?:(?<Button>>\s*)|)(?:(?:\((?<BoxA>[^\(\)]*)\))|)((?:(?<Name>\w+):|)(?:(?<Dialog>[^\/\(\[]*)))(?:\/|)(?(?<=\/)\s*(?<Tone>\w*)|)(?:\s*\[(?<BBCmd>.*)]|)\s*(?:(?:\((?<BoxB>[^\(\)]*)\))|)')
	buttonInstructRegex.compile(r'(?<Instruction>\bdisable:|\bhide:)')
	flagRegex.compile(r'^--(?<Flag>\s*\w+\s*)--')
	read_conversationFile(file)
	print("Array size = {size}".format({"size": currentConversation.size()}))
	#for testing
	Command_Listener.currentDialogSystem = self
	#start_from_beginning()
	#display_portrait("Red")
	#print("%d:%d/%d:Texture2D" % [TYPE_ARRAY, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE])
func start_from_beginning():
	currentLine = -1
	play_next_dialog()
func _process(_delta):
	if Input.is_action_just_pressed("Interact") and !lockScene:
		play_next_dialog()
func read_conversationFile(filename : String):
	var f = FileAccess.open(filename, FileAccess.READ)
	if FileAccess.file_exists(filename):
		while !f.eof_reached():
			var line = f.get_line().strip_edges(true, false) #strips white spaces from left
			var isComment = line.begins_with("#")
			if line.is_empty() or isComment:
				continue
			var flag = flagRegex.search(line)
			if flag != null: 
				var flagName = flag.get_string("Flag").strip_edges()
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
	if _flagName != "": #if flag exist, go to flag
		currentLine = flagDict[_flagName] - 1
	if currentLine >= currentConversation.size()-1: #if the conversation is over, returns
		print("end conversation")
		return
	var snapshot : Dictionary
	while true:
		currentLine += 1
		snapshot = capture_line(get_line())
		var isChoice = snapshot["isChoice"]
		var boxA = snapshot["boxA"]
		if isChoice or read_boxA_condition(boxA) == true:
			break
	snapshot = capture_line(get_line())
	if read_boxA_condition(snapshot["boxA"]) and not snapshot["isChoice"]:
		display_dialogLine(snapshot["dialog"], snapshot["name"], snapshot["bbtag"])
		#display_portrait(currentCaptures["name"], currentCaptures["tone"])
	#display buttons
	while capture_line(get_line())["isChoice"]:#lineCaptureRegex.search(get_line()).get_string("Button").is_empty(): # while currentline is a choice, loops
		create_choice_button(get_line()) #ceate button
		var nextline = get_line(1)
		if not capture_line(nextline)["isChoice"]: #if next line is not a choice, break the loop
			break
		currentLine += 1
		
func read_boxA_condition(boxA:String)-> bool:
	if boxA.is_empty(): return true
	if boxA.strip_edges().is_empty(): return true
	var condition = Command_Listener.read_condition(boxA)
	return condition
	
func capture_line(_line:String = get_line())-> Dictionary:
	var regEx_return = func(rmatch : RegExMatch, group : String)-> String:
		if rmatch.get_string(group) != null:
			return rmatch.get_string(group)
		else: return ""
	var cmd = commandCaptureRegex.search(_line)
	var line = regEx_return.call(cmd, "Line")#cmd.get_string("Line")
	var	dialogLine = dialogCaptureRegex.search(line)
	
	var isChoice = !cmd.get_string("Button").is_empty()
	var boxA = cmd.get_string("BoxA")
	var boxB = cmd.get_string("BoxB")
	var name_ = regEx_return.call(dialogLine,"Name")
	var	dialog = regEx_return.call(dialogLine,"Dialog")
	var bbtag =  regEx_return.call(dialogLine,"BBTag")
	return {
	"isChoice":isChoice,
	"boxA":boxA, 
	"boxB":boxB, 
	"name": name_,
	"dialog" : dialog, 
	"bbtag":bbtag, 
	}
	
func create_choice_button(_line):
	#if the first cmd box exist and condition is false, return
	var captures = capture_line(_line) #commandBoxRegex won't return null
	var boxA = captures["boxA"]
	var boxAcondition = read_boxA_condition(boxA)
	var boxB = captures["boxB"]
	var choiceText = ">"+captures["dialog"]
	
	var getInstruction = func()->String:
		if boxA.is_empty(): return ""
		if buttonInstructRegex.search(boxA) == null: return ""
		var construct = buttonInstructRegex.search(boxA)
		var Instruction = construct.get_string("Instruction")
		return Instruction
	var buttonCommands = func():
		if !boxB.is_empty():
			Command_Listener.handle_input(boxB) #connect cmds to button
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
	
func display_dialogLine(dialogLine: String, _name:String = "", _bbtag:String = ""):
	var gChData = Global_Data.characterDataDict
	var nameCol = Color.WHITE.to_html()
	var curCharacterData : CharacterBaseResource
	if settings.useOverrideNameColor != null:
		nameCol = settings.useOverrideNameColor.to_html()
	elif gChData.has(_name) && gChData[_name] is CharacterBaseResource:
		curCharacterData = gChData[_name]
		nameCol = curCharacterData.nameColorHex
		
	var BBName = applyColor(_name, nameCol)
	var BoldBBName = apply_bbcode(BBName+":","b")
	if _bbtag != "":
		var bbtagChain = _bbtag.split(",")
		for bb in bbtagChain:
			dialogLine = apply_bbcode(dialogLine, bb.strip_edges())
	dialogBox.text = BoldBBName + dialogLine
	print(str(currentLine) + ":" + get_line())
	
#func display_portrait(_name:String = "", _tone:String = ""):
	#var gChData = Global_Data.characterDataDict
	#var chData : CharacterBaseResource
	#if gChData.has(_name):
		#dialogPortrait.visible = true
		#chData  = gChData[_name]
		#var y = chData.atlasYpos
		#var x = chData.get_tone_x_pos(_tone)
		#var coords = Vector2i(x,y)
		#var clampVec = Vector2i(dialogPortrait.hframes, dialogPortrait.vframes)
		#dialogPortrait.frame_coords = coords.clamp(Vector2i(0,0), clampVec)
	#else:
		#dialogPortrait.visible = false
	
func applyColor (_text:String, _color:String)->String:
	var beforeFormat = "%s"+_text+"%s"
	var afterFormat = beforeFormat%["[color={c}]","[/color]"]
	var result = afterFormat.format({"c":_color})
	return result

func apply_bbcode(_text: String, _BBTag:String)->String:
	var result = "[{0}]{1}[/{0}]".format([_BBTag, _text])
	return result
func end_conversation():
	pass
