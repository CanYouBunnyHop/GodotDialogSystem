class_name DialogSystem extends Control

var currentLine :int = -1
var flagDict : Dictionary = {"beginning": 0}
var currentConversation : Array[String] = []

signal signal_start_convo
signal signal_play_next
signal signal_jump(flag:String)

@export_file("*.txt") var file
@export var buttonContainer : Node
@export var dialogBox : RichTextLabel
@export var dialogPortrait : Sprite2D
@export var settings : DialogSystemSettings

var commandCaptureRegex = RegEx.new()
var dialogCaptureRegex = RegEx.new()
var buttonInstructRegex = RegEx.new()
var flagRegex = RegEx.new()
var bbtagRegex = RegEx.new()
var stampRegex = RegEx.new()

var lockScene : bool = false
#var readTweens : Array[Tween]
var readTween : Tween
func _ready():
	commandCaptureRegex.compile(r'^(?<Button>>\s*)?(?:\((?<BoxA>[^\(\)]*)\))?(?<Line>.*?)\s*(?:\((?!.*\()(?<BoxB>[^\(\)]*)\))?$')
	dialogCaptureRegex.compile(r'(?:^(?:(?<Name>.*):|)(?:(?<Dialog>.*?)))(\[(?!.*\[)(?<BBTag>.*)\]|)$')
	buttonInstructRegex.compile(r'(?<Instruction>\bdisable:|\bhide:)')
	flagRegex.compile(r'^--(?<Flag>\s*\w+\s*)--')
	bbtagRegex.compile(r'^(?<Tag>\w+)(?<Param>( |=|).*)')
	stampRegex.compile(r'\*(?<Speed>\d+)\*')
	read_conversationFile(file)
	print("Array size = {size}".format({"size": currentConversation.size()}))
	#for testing
	var begin = func():
		currentLine = -1
		play_next_dialog()
	GlobalData.currentDialogSystem = self #for testing
	signal_start_convo.connect(begin)
	signal_play_next.connect(play_next_dialog)
	signal_jump.connect(play_next_dialog)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact"):
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

func play_next_dialog(_flagName : String = ""):
	#if readTweens.any(func(tween:Tween): return tween.is_running()):
		#for tw in readTweens: 
			#tw.kill()
	if readTween and readTween.is_running():
		readTween.kill()
		dialogBox.visible_ratio = 1
		return
	if lockScene: return #if choices appeared, next dialog won't be updated
	if _flagName != "": #if flag exist, go to flag
		currentLine = flagDict[_flagName] - 1
	if currentLine >= currentConversation.size()-1: #if the conversation is over, returns
		print("end conversation")
		return
	var snapshot : Dictionary
	var boxA : String
	var boxB : String
	var isChoice : bool = false
	var boxAcondition : bool = false
	while currentLine <= currentConversation.size():
		currentLine += 1
		snapshot = capture_line(get_line())
		isChoice = snapshot["isChoice"]
		boxA = snapshot["boxA"]
		boxB = snapshot["boxB"]
		var full : String = snapshot["full"]
		boxAcondition = read_boxA_condition(boxA)
		#if not a choice, and boxA is true, handle boxB input if line is empty, continue to next line
		if isChoice: break #break if it's a choice, 
		if not boxAcondition: continue #if box a is not true, continue
		CmdListener.handle_input(boxB)#if not a choice, boxa is true and full is empty
		if not full.is_empty(): break #if the "not choice" is not an empty dialog line, break, display line
	if boxAcondition and not isChoice:
		display_dialogline(snapshot["dialog"], snapshot["name"], snapshot["bbtag"])
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
	var condition = CmdListener.read_condition(boxA)
	return condition
	
func capture_line(_line:String = get_line())-> Dictionary:
	var regEx_return = func(rmatch : RegExMatch, group : String)-> String:
		if rmatch.get_string(group) != null:
			return rmatch.get_string(group)
		else: return ""
	var cmdMatch = commandCaptureRegex.search(_line)
	var line = regEx_return.call(cmdMatch,"Line")#cmd.get_string("Line")
	var	dialogLine = dialogCaptureRegex.search(line)
	
	const IS_CHOICE = "isChoice"
	const BOX_A = "boxA"
	
	var isChoice = !cmdMatch.get_string("Button").is_empty()
	var boxA = cmdMatch.get_string("BoxA")
	var boxB = cmdMatch.get_string("BoxB")
	var full = dialogLine.get_string()
	var name_ = regEx_return.call(dialogLine,"Name")
	var	dialog = regEx_return.call(dialogLine,"Dialog")
	var bbtag =  regEx_return.call(dialogLine,"BBTag")
	return {
	"isChoice":isChoice,
	"boxA":boxA, 
	"boxB":boxB, 
	"full":full,
	"name":name_,
	"dialog":dialog, 
	"bbtag":bbtag, 
	}
	
func create_choice_button(_line):
	#if the first cmd box exist and condition is false, return
	var captures = capture_line(_line) #commandBoxRegex won't return null
	var boxA = captures["boxA"]
	var boxAcondition = read_boxA_condition(boxA)
	var boxB = captures["boxB"]
	var choiceText = ">"+captures["full"]
	
	var getInstruction = func()->String:
		if boxA.is_empty(): return ""
		if buttonInstructRegex.search(boxA) == null: return ""
		var construct = buttonInstructRegex.search(boxA)
		var Instruction = construct.get_string("Instruction")
		return Instruction
	var buttonCommands = func():
		for b in buttonContainer.get_children():
			b.queue_free()
			lockScene = false
		dialogBox.text = choiceText
		if !boxB.is_empty():
			CmdListener.handle_input(boxB) #connect cmds to button
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
	choiceButt.pressed.connect(buttonCommands)
	
func display_dialogline(dialogLine: String, _name:String = "", _bbtag:String = ""):
	var gChData = GlobalData.characterDataDict
	var curCharacterData : CharacterBaseResource
	var realName = _name.format(GlobalData.data)
	var bbname = realName
	if !realName.is_empty():
		if gChData.has(realName) && gChData[realName] is CharacterBaseResource:
			curCharacterData = gChData[realName]
			bbname = apply_font_setting(bbname, curCharacterData.nameFontSettings)
		else : #use default if characterBaseResource is not found
			bbname = apply_font_setting(bbname, settings.defaultNameSettings)
		bbname = apply_bbcode(bbname+":","b")
	
	#var textWithStamp : String = _name+":"+dialogLine #without bbcode
	#var stamps : Array[RegExMatch] = stampRegex.search_all(textWithStamp) #find stamps
	#var realStartPositions : Array[int] = []
	#if stamps != null:
		#var counter = 0
		#for stmp in stamps:
			#var startPos = stmp.get_start()
			#var count = stmp.get_string().length()
			#counter += (startPos-count)
			#realStartPositions.append(counter)
			#var textNoStamp = textWithStamp.erase(startPos, count)
			#dialogLine = textNoStamp.trim_prefix(_name+":")
	
	var realDialogLine = dialogLine.format(GlobalData.data)
	#seperate the dialog line with stamps
	var lineSections : PackedStringArray
	var stampList : Array[int]
	var curDialogSlice = realDialogLine
	var slices : PackedStringArray
	
	if stampRegex.search(realDialogLine) != null: #start loop if there there are stamp in dialogline
		while stampRegex.search(curDialogSlice) != null:#this loop splits line into sections
			var stamp = stampRegex.search(curDialogSlice)
			stampList.append(int(stamp.get_string("Speed"))) #append speed in the stamp
			slices = curDialogSlice.split(stamp.get_string(),true)
			lineSections.append(slices[0]) #append first slice
			curDialogSlice = slices[1]
		if slices.size() > 1: #after while loop, append the last slice
			lineSections.append(slices[1]) 
	else: lineSections.append(realDialogLine)
	#join line sections
	realDialogLine = "".join(lineSections)
	
	var bbDialogLine = realDialogLine
	if _bbtag != "":
		var bbtagChain = _bbtag.split(",")
		for bb in bbtagChain:
			var bbt = bbtagRegex.search(bb.strip_edges())
			var tag = bbt.get_string("Tag")
			var param = bbt.get_string("Param")
			bbDialogLine = apply_bbcode(realDialogLine, tag, param)
	
	dialogBox.visible_characters = 0
	var fullLine = (bbname+bbDialogLine)
	dialogBox.text = fullLine
	
	#if readTweens.any(func(tween:Tween): return tween.is_running()):
		#for tw in readTweens: 
			#tw.kill()
	#if previous tween is running, kill it, not nessasary, but just in case
	if readTween and readTween.is_running(): readTween.kill()
	readTween = create_tween() #only create once, or else it will override
	readTween.set_trans(Tween.TRANS_LINEAR)
	var startPosition = realName.length()+1 #plus the ":" count
	for i in range(0, lineSections.size()):
		var sectionLength = lineSections[i].length()
		var speed:float = settings.readingSpeed
		if i != 0:
			speed = stampList[i-1]
		var destination : float = startPosition + sectionLength
		var distance = abs(destination - startPosition)
		var delta = destination/speed
		#tween property
		readTween.chain().tween_property(dialogBox,"visible_characters", destination, delta).from(startPosition)
		startPosition = destination #this destination the next start position 
		
		#readTween.tween_property(dialogBox,"visible_ratio")
		
	#if stamps:
		#for s in stamps:
			#var newTween = create_tween()
			#newTween.set_trans(Tween.TRANS_LINEAR)
			#var speed = s.get_string("Speed")
			#newTween.set_speed_scale(int(speed))
			#readTweens.append(newTween)
	#var readTween = create_tween()
	#var realEnd = dialogBox.get_total_character_count() if !realStartPositions else realStartPositions[0]
	#readTween.set_trans(Tween.TRANS_LINEAR)
	#readTween.set_speed_scale(settings.readingSpeed)
	#readTween.tween_property(dialogBox,"visible_characters", realEnd, 1).from(_name.length() + 1)
	#await !readTween.is_running()
	#
	#if stamps != null:		
		#for i in range(0, stamps.size()):
			#var newTween = create_tween()
			#newTween.set_trans(Tween.TRANS_LINEAR)
			#var speed = stamps[i].get_string("Speed")
			#newTween.set_speed_scale(int(speed))
			#var start = realStartPositions[i]
			#var end =  dialogBox.get_total_character_count() if i+1 > realStartPositions.size()-1 else realStartPositions[i+1]
			
			#var totalLength = 0
			#for c in range(0, stamps.size()-i):
				#totalLength += stamps[i].get_start()
			#var length = dialogBox.get_total_character_count() if (i+1)>(stamps.size()-1) else stamps[i+1].get_start()-totalLength
			
			#newTween.tween_property(dialogBox,"visible_characters", end, 1).from(start)
			#await newTween.loop_finished
			
			#readTweens.append(newTween)
			#pass
	#else:
		#var newTween = create_tween()
		#newTween.set_trans(Tween.TRANS_LINEAR)
		#newTween.set_speed_scale(settings.readingSpeed)
		#var length = dialogBox.get_total_character_count()
		#newTween.tween_property(dialogBox,"visible_characters", length, 1).from(_name.length()+1)
		#readTweens.append(newTween)
		
	#readTween = create_tween()
	#readTween.set_trans(Tween.TRANS_LINEAR)
	#readTween.set_speed_scale(settings.readingSpeed)
	#readTween.tween_property(dialogBox,"visible_characters", length, 1).from(_name.length() + 1)
	print(str(currentLine) + ":" + get_line())
	
#func format_dialogline(formatArray : Array[String]):
	#var dialogline = dialogBox.get_parsed_text()
	#var newLine = dialogline.format(formatArray)
	#dialogBox.text = newLine
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

	
#func apply_color (_text:String, _color:String)->String:
	#var beforeFormat = "%s"+_text+"%s"
	#var afterFormat = beforeFormat%["[color={c}]","[/color]"]
	#var result = afterFormat.format({"c":_color})
	#return result
func apply_font_setting(_text: String, _fontSetting: FontSettingsResource)->String:
	var result = _text
	result = apply_bbcode(result,"color" ,"="+_fontSetting.color.to_html())
	result = apply_bbcode(result,"outline_color" ,"="+_fontSetting.outlineColor.to_html())
	result = apply_bbcode(result,"outline_size" ,"="+str(_fontSetting.outlineSize))
	return result
func apply_bbcode(_text: String, _BBTag:String, _BBParam:String = "")->String:
	var result = "[{0}{2}]{1}[/{0}]".format([_BBTag, _text, _BBParam])
	return result
	
func end_conversation():
	pass
