class_name DialogSystem extends CanvasLayer

var currentLine :int = -1
var flagDict : Dictionary = {"beginning": 0}
var currentConversation : Array[String] = []

signal signal_start_convo
signal signal_jump(flag:String)

#NOTE WARNING workaround to get a static signal without using a manager clss
static var singleton :DialogSystem: 
	get: return singleton if singleton != null else new()
signal _cmdQ
static var signal_dequeue_cmd := Signal(singleton._cmdQ)
signal _setActive(b:bool)
static var signal_all_set_active := Signal(singleton._setActive)

##[color=orange][b]WARNING[/b][/color]: do not use spaces and special characters other than "_"
@export var dialogSystemID : String = ""
@export_file("*.txt") var file
@export var speechBox : SpeechBox:
	get: return speechBox if speechBox != null else $"Speech Box"
#@export var buttonContainer : Container
#@export var dialogLabel : RichTextLabel
#@export var dialogPortrait : Sprite2D
#@export var settings : DialogSystemSettings
#region Regular Expressions and Other Keywords
#var commandCaptureRegex = RegEx.new()
#var dialogCaptureRegex = RegEx.new()
static var flagRegex : RegEx:
	get: 
		if flagRegex != null: return flagRegex
		flagRegex = RegEx.new()
		flagRegex.compile(r'^--(?<Flag>\s*\w+\s*)--')
		return flagRegex
#var bbtagRegex = RegEx.new()
#var stampRegex = RegEx.new()
#const INSTRUCT = {BUTTON_HIDE = "hide:", BUTTON_DISABLE = "disable:"}
#const buttonInstructions = [INSTRUCT.BUTTON_HIDE, INSTRUCT.BUTTON_DISABLE]
#endregion
var isActive : bool = false
#var readTween : Tween
#var lockDialogBox : bool = false #NOTE when locked, dialog won't be updated, used for button prompt
var timer:SceneTreeTimer
var interactReady:bool = true
func get_system_info()->String:
	return "DialogSystemID:{0}, readableLines = {1}\ncurrentLineNumber = {2}".format([dialogSystemID, currentConversation.size(), currentLine])
func _ready():
	#NOTE Adding self to globaldata dialog system dict
	if dialogSystemID.is_empty() or dialogSystemID == null:
		var newID : String = str(get_instance_id()) #29360129301
		dialogSystemID = newID
		CmdListener.debug_warn("Dialog System ID is not found, Instance ID is used instead %s"%[newID])
	GlobalData.dialogSystemDict[dialogSystemID] = self #add self to global system dict
	#commandCaptureRegex.compile(r'^(?<Button>>\s*)?(?:\((?<BoxA>[^\(\)]*)\))?(?<Line>.*?)\s*(?:\((?!.*\()(?<BoxB>[^\(\)]*)\))?$')
	#dialogCaptureRegex.compile(r'(?:^(?:(?<Name>.*):|)(?:(?<Dialog>.*?)))(\[(?!.*\[)(?<BBTag>.*)\]|)$')
	#flagRegex.compile(r'^--(?<Flag>\s*\w+\s*)--')
	#bbtagRegex.compile(r'^(?<Tag>\w+)(?<Param>( |=|).*)')
	#stampRegex.compile(r'\*(?<Speed>(?:[0-9]*[.])?[0-9]+)?(?:D(?<Delay>([0-9]*[.])?[0-9]+))\*|\*(?<Speed2>(?&Speed))\*')
	read_conversationFile(file)
	
	var begin = func():
		currentLine = -1
		play_next_dialog()
	signal_start_convo.connect(begin)
	signal_jump.connect(play_next_dialog) #this signal requires flag as argument
	signal_all_set_active.connect(func(b): isActive = b)
	
	CmdListener.debug_log(get_system_info())
	
	#GlobalData.currentDialogSystem = self #TESTING
	
#NOTE Input Handling moved to global data
func _unhandled_input(_event: InputEvent) -> void:
	var startCoolDown = func(duration : float):
		interactReady = false
		timer = get_tree().create_timer(duration, true, false, true)
		timer.timeout.connect(func(): interactReady = true)
	if Input.is_action_just_pressed("Interact") and interactReady:
		interacted()
		#cooldown prevent accidental skipping when spamming Interact
		startCoolDown.call(0.1)
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
				flagDict[flagName] = currentConversation.size()
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
func interacted(): #TODO RENAME
	if not isActive: return
	if signal_dequeue_cmd.get_connections().size() > 0:
		signal_dequeue_cmd.emit() #emit commands queued up in this signal
		return
	#if still reading, stop reading, show full text instead
	if speechBox.readTween and speechBox.readTween.is_running():
		speechBox.readTween.kill()
		speechBox.dialogLabel.visible_ratio = 1
		return
	if speechBox.lockBox: return #if choices appeared, next dialog won't be updated
	play_next_dialog()
func play_next_dialog(_flagName : String = ""):
	if _flagName != "": #if flag exist, go to flag
		currentLine = flagDict[_flagName] - 1
	#if the conversation is over, returns
	if currentLine >= currentConversation.size()-1: 
		CmdListener.debug_log("end conversation")
		return
	var snapshot : LineCapture#Dictionary
	#var boxA : String
	#var boxB : String
	#var isChoice : bool = false
	#var boxAcondition : bool = false
	#var full : String
	while currentLine <= currentConversation.size():
		currentLine += 1
		snapshot = LineCapture.new(get_line())#capture_line(get_line())
		#isChoice = snapshot.isChoice#snapshot["isChoice"]
		#boxA = snapshot.boxA#snapshot["boxA"]
		#boxB = snapshot.boxB#snapshot["boxB"]
		#full = snapshot.full#snapshot["full"]
		#boxAcondition = snapshot.boxACon#snapshot["boxACon"]#read_boxA_condition(boxA)
		#if not a choice, and boxA is true, handle boxB input if line is empty, continue to next line
		if snapshot.isChoice: break #break if it's a choice, 
		if not snapshot.boxACon: continue #if box a is not true, continue
		CmdListener.handle_input(snapshot.boxB)#if not a choice, boxa is true and full is empty
		if not snapshot.full.is_empty(): break #if the "not choice" is not an empty dialog line, break
	print(str(currentLine) + ":" + get_line()) #TEST
	if snapshot.boxACon and not snapshot.isChoice and not snapshot.full.is_empty():
		speechBox.display_dialogline(snapshot.dialog, snapshot.name, snapshot.bbtag)
		#display_dialogline(snapshot["dialog"], snapshot["name"], snapshot["bbtag"])
	#display buttons, while currentline is a choice, loops
	while LineCapture.new(get_line()).isChoice:#capture_line(get_line())["isChoice"]:
		#probably not needed, but just in case 
		if currentLine > currentConversation.size(): break
		speechBox.create_choice_button(get_line()) #create button 
		var nextline = get_line(1)
		#if next line is not a choice, break the loop
		if not LineCapture.new(nextline).isChoice: break#capture_line(nextline)["isChoice"]: break
		currentLine += 1
		print(str(currentLine) + ":" + get_line()) #TEST
#returns true when empty
#func read_boxA_condition(boxA:String)-> bool:
	#if boxA.strip_edges().is_empty(): return true
	#var condition = CmdListener.read_condition(boxA)
	#return condition
#func capture_line(_line:String = get_line())-> Dictionary:
	#var no_group_return_empty = func(rmatch : RegExMatch, group : String)-> String:
		#if rmatch.names.has(group): return rmatch.get_string(group)
		#else: return ""
	#var cmdMatch = commandCaptureRegex.search(_line)
	#var isChoice = !no_group_return_empty.call(cmdMatch,"Button").is_empty()
	#var boxA = no_group_return_empty.call(cmdMatch, "BoxA").strip_edges()
	#var boxB = no_group_return_empty.call(cmdMatch, "BoxB").strip_edges()
	#var boxACon = (func():
		#if boxA.is_empty(): return true
		##NOTE instructions are used when condition are false
		##we return here so command listener won't debug errors 
		#if buttonInstructions.any(func(i): return i == boxA): return false 
		#var condition = CmdListener.read_condition(boxA)
		#return condition).call()
	#var line = no_group_return_empty.call(cmdMatch,"Line") #line is in-between cmdbox
	#
	#var	dialogLine = dialogCaptureRegex.search(line)
	#var full = dialogLine.get_string()
	#var name_ = no_group_return_empty.call(dialogLine,"Name")
	#var	dialog = no_group_return_empty.call(dialogLine,"Dialog")
	#var bbtag =  no_group_return_empty.call(dialogLine,"BBTag")
	#return { #TODO custom class or struct
	#"isChoice":isChoice,
	#"boxA":boxA, 
	#"boxB":boxB,
	#"boxACon":boxACon, 
	#"full":full,
	#"name":name_,
	#"dialog":dialog, 
	#"bbtag":bbtag, 
	#}
#func create_choice_button(_line : String):
	##if the first cmd box exist and condition is false, return
	#var captures = LineCapture.new(_line)#capture_line(_line) #commandBoxRegex won't return null
	##var boxA:String = captures["boxA"]
	##var boxAcondition:bool = captures["boxACon"]
	##var boxB:String = captures["boxB"]
	#var choiceText:String = ">"+captures.full#captures["full"]
	#var getInstruction = func()->String:
		#if captures.boxA.is_empty(): return ""
		#var finalInstruction = ""
		#for instruction in LineCapture.buttonInstructions:#buttonInstructions:
			#if captures.boxA.ends_with(instruction): finalInstruction = instruction
		#return finalInstruction
	#var buttonCommands = func(): #functions for buttons to connect to
		##universal behavior, unlock box, delete button
		#for b in speechBox.buttonContainer.get_children(): 
			#b.queue_free()
			#lockDialogBox = false
		#speechBox.dialogLabel.text = choiceText
		##if !captures.boxB.is_empty(): #TODO we want this to be delayed for one line
			##connect the box b commands to a queue, execute queue when next line is played
		#signal_cmdQ.connect(func():CmdListener.handle_input(captures.boxB), CONNECT_ONE_SHOT)
			##CmdListener.handle_input(boxB) #connect cmds to button
	#lockDialogBox = true
	#var constructInstruction = getInstruction.call()
	#var isDisabled = false #determines if button should be disabled
	#if captures.boxACon == false:#boxAcondition == false:
		#match constructInstruction:
			#captures.INSTRUCT.BUTTON_HIDE: return
			#captures.INSTRUCT.BUTTON_DISABLE,_: isDisabled = true
	#var choiceButt : Button = Button.new()
	#choiceButt.text = choiceText
	#speechBox.buttonContainer.add_child(choiceButt)
	#choiceButt.disabled = isDisabled
	#choiceButt.pressed.connect(buttonCommands)
#func display_dialogline(dialogLine: String, _name:String = "", _bbtag:String = ""):
	#var gChData = GlobalData.characterDataDict
	#var curCharacterData : CharacterBaseResource
	#var bbname:String= _name
	#if !_name.is_empty():
		#if gChData.has(_name) && gChData[_name] is CharacterBaseResource:
			#curCharacterData = gChData[_name]
			#bbname = apply_font_setting(bbname, curCharacterData.nameFontSettings)
		#else : #use default if characterBaseResource is not found
			#bbname = apply_font_setting(bbname, speechBox.settings.defaultNameSettings)
		#bbname = apply_bbcode(bbname+":","b")
	##NOTE format after applyBB, so if data returned a duplicate name, dont apply same bb color
	##example: {player_name} = "John" is not the same "John" in predefined name
	#var realBBName = bbname.format(GlobalData.data) 
	#var realDialogLine = dialogLine.format(GlobalData.data)
	##seperate the dialog line with stamps
	#var lineSections : PackedStringArray #TBD refactor, using struct/2DArray
	#var speedList : Array[float] = [speechBox.settings.readingSpeed]
	#var delayList : Array[float] = [0]
	#
	#if stampRegex.search(realDialogLine) != null: #there there are stamp in dialogline
		#var slices : PackedStringArray 
		#var curDialogSlice = realDialogLine
		##while there is stamp in the current slice, loop splits line into 2 slices,
		##slice0 only have one section, slice1 could contain other more than one section 
		#while stampRegex.search(curDialogSlice) != null: 
			#var curStamp:RegExMatch = stampRegex.search(curDialogSlice)
			#var delay:float = curStamp.get_string("Delay").to_float() if curStamp.names.has("Delay") else 0
			#var speed:float = speechBox.settings.readingSpeed
			#for skey in ["Speed", "Speed2"]:
				#if curStamp.names.has(skey): speed = float(curStamp.get_string(skey))
			#speedList.append(speed) #append speed
			#delayList.append(delay) #append delay
			#slices = curDialogSlice.split(curStamp.get_string(),true)
			#lineSections.append(slices[0]) #append first slice
			#curDialogSlice = slices[1] #current slice becomes slice1
		#if slices.size() > 1: #after while loop, append the last slice
			#lineSections.append(slices[1]) 
	#else: lineSections.append(realDialogLine) #if no stamps, the whole line is a section
	##join line sections after removing stamps
	#realDialogLine = "".join(lineSections)
	#var realBBDialogLine = realDialogLine
	#if _bbtag != "":
		#var bbtagChain = _bbtag.split(",")
		#for bb in bbtagChain:
			#var bbt = bbtagRegex.search(bb.strip_edges())
			#var tag = bbt.get_string("Tag")
			#var param = bbt.get_string("Param")
			#realBBDialogLine = apply_bbcode(realDialogLine, tag, param)
	#speechBox.dialogLabel.visible_characters = 0
	#var fullLine = realBBName + realBBDialogLine
	#speechBox.dialogLabel.text = fullLine
	##if previous tween is running, kill it, not nessasary, but just in case
	#if readTween and readTween.is_running(): readTween.kill()
	#readTween = create_tween() #only create once, or else it will override
	#readTween.set_trans(Tween.TRANS_LINEAR)
	##get length of real name here, so bbcode won't be included
	#var realNameLength = _name.format(GlobalData.data).length() 
	#var startPosition = realNameLength+1 #plus the ":" count
	#for i in range(0, lineSections.size()):
		#var sectionLength = lineSections[i].length()
		#var speed: float = speedList[i] #index 0 is default reading speed from settings 
		#var destination : float = startPosition + sectionLength
		#var distance = abs(destination - startPosition)
		#var delta :float = 0
		##if speed is 0, delta is 0, which should result in instant
		#if speed != 0: delta = destination/speed
		#var delay = delayList[i]
		#await readTween.chain().tween_interval(delay) #this will delay the tweener below
		#readTween.chain().tween_property(speechBox.dialogLabel,"visible_characters", destination, delta).from(startPosition)
		#startPosition = destination #this destination the next start position
#func apply_font_setting(_text: String, _fontSetting: FontSettingsResource)->String:
	#var result = _text
	#result = apply_bbcode(result,"color" ,"="+_fontSetting.color.to_html())
	#result = apply_bbcode(result,"outline_color" ,"="+_fontSetting.outlineColor.to_html())
	#result = apply_bbcode(result,"outline_size" ,"="+str(_fontSetting.outlineSize))
	#return result
#TODO move this to Util
#func apply_bbcode(_text: String, _BBTag:String, _BBParam:String = "")->String:
	#var result = "[{0}{2}]{1}[/{0}]".format([_BBTag, _text, _BBParam])
	#return result
#func end_conversation():
	#pass
