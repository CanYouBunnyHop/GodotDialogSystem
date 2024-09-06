class_name SpeechBox extends Panel
@export var dialogLabel : RichTextLabel
@export var dialogPortrait : Sprite2D
@export var buttonContainer : Container
@export var settings : SpeechBoxSettings
var readTween : Tween
var lockBox : bool = false
static var bbtagRegex :RegEx:
	get:
		if bbtagRegex != null: return bbtagRegex
		bbtagRegex = RegEx.new()
		bbtagRegex.compile(r'^(?<Tag>\w+)(?<Param>( |=|).*)')
		return bbtagRegex
static var stampRegex :RegEx:
	get:
		if stampRegex != null: return stampRegex
		stampRegex = RegEx.new()
		stampRegex.compile(r'\*(?<Speed>(?:[0-9]*[.])?[0-9]+)?(?:D(?<Delay>([0-9]*[.])?[0-9]+))\*|\*(?<Speed2>(?&Speed))\*')
		return stampRegex
func apply_font_setting(_text: String, _fontSetting: FontSettingsResource)->String:
	var result = _text
	result = MyUtil.apply_bbcode(result,"color" ,"="+_fontSetting.color.to_html())
	result = MyUtil.apply_bbcode(result,"outline_color" ,"="+_fontSetting.outlineColor.to_html())
	result = MyUtil.apply_bbcode(result,"outline_size" ,"="+str(_fontSetting.outlineSize))
	return result
func create_choice_button(_line : String):
	#if the first cmd box exist and condition is false, return
	var captures = LineCapture.new(_line)#capture_line(_line) #commandBoxRegex won't return null
	#var boxA:String = captures["boxA"]
	#var boxAcondition:bool = captures["boxACon"]
	#var boxB:String = captures["boxB"]
	var choiceText:String = ">"+captures.full#captures["full"]
	var getInstruction = func()->String:
		if captures.boxA.is_empty(): return ""
		var finalInstruction = ""
		for instruction in LineCapture.BUTTON_INSTRUCTIONS:#buttonInstructions:
			if captures.boxA.ends_with(instruction): finalInstruction = instruction
		return finalInstruction
	var buttonCommands = func(): #functions for buttons to connect to
		#universal behavior, unlock box, delete button
		for b in buttonContainer.get_children(): 
			b.queue_free()
			lockBox = false
		dialogLabel.text = choiceText #choice check
		#NOTE "jump:" command will skip the choice check, 
		#because the cmd will execute immediately after 
		#connect the box b commands to a signal, emit it when interacted
		#NOTE DONT WANT TO BLOCK HERE DUE TO NOT ALL COMMANDS WILL JUMP POSITION 
		#DSManager.sig_interact_blocker.connect(func():CmdListener.handle_input(captures.boxB), CONNECT_ONE_SHOT)
		CmdListener.handle_input(captures.boxB) #connect cmds to button
	lockBox = true
	var constructInstruction = getInstruction.call()
	var isDisabled = false #determines if button should be disabled
	if captures.boxACon == false:#boxAcondition == false:
		match constructInstruction:
			captures.INSTRUCT.BUTTON_HIDE: return
			captures.INSTRUCT.BUTTON_DISABLE,_: isDisabled = true
	var choiceButt : Button = Button.new()
	choiceButt.text = choiceText
	buttonContainer.add_child(choiceButt)
	choiceButt.disabled = isDisabled
	choiceButt.pressed.connect(buttonCommands)
	pass
func display_dialogline(dialogLine: String, _name:String = "", _bbtag:String = ""):
	var gChData = DSManager.characterDataDict
	var curCharacterData : CharacterBaseResource
	var bbname:String= _name
	if !_name.is_empty():
		if gChData.has(_name) && gChData[_name] is CharacterBaseResource:
			curCharacterData = gChData[_name]
			bbname = apply_font_setting(bbname, curCharacterData.nameFontSettings)
		else : #use default if characterBaseResource is not found
			bbname = apply_font_setting(bbname, settings.defaultNameSettings)
		bbname = MyUtil.apply_bbcode(bbname+":","b")
	#NOTE format after applyBB, so if data returned a duplicate name, dont apply same bb color
	#example: {player_name} = "John" is not the same "John" in predefined name
	var realBBName = bbname.format(DSManager.data)
	var realDialogLine = dialogLine.format(DSManager.data)
	#seperate the dialog line with stamps
	var lineSections : PackedStringArray #TBD refactor, using struct/2DArray
	var speedList : Array[float] = [settings.readingSpeed]
	var delayList : Array[float] = [0]
	
	if stampRegex.search(realDialogLine) != null: #there there are stamp in dialogline
		var slices : PackedStringArray 
		var curDialogSlice = realDialogLine
		#while there is stamp in the current slice, loop splits line into 2 slices,
		#slice0 only have one section, slice1 could contain other more than one section 
		while stampRegex.search(curDialogSlice) != null: 
			var curStamp:RegExMatch = stampRegex.search(curDialogSlice)
			var delay:float = curStamp.get_string("Delay").to_float() if curStamp.names.has("Delay") else 0.0
			var speed:float = settings.readingSpeed
			for skey in ["Speed", "Speed2"]:
				if curStamp.names.has(skey): speed = float(curStamp.get_string(skey))
			speedList.append(speed) #append speed
			delayList.append(delay) #append delay
			slices = curDialogSlice.split(curStamp.get_string(),true)
			lineSections.append(slices[0]) #append first slice
			curDialogSlice = slices[1] #current slice becomes slice1
		if slices.size() > 1: #after while loop, append the last slice
			lineSections.append(slices[1]) 
	else: lineSections.append(realDialogLine) #if no stamps, the whole line is a section
	#join line sections after removing stamps
	realDialogLine = "".join(lineSections)
	var realBBDialogLine = realDialogLine
	if _bbtag != "":
		var bbtagChain = _bbtag.split(",")
		for bb in bbtagChain:
			var bbt = bbtagRegex.search(bb.strip_edges())
			var tag = bbt.get_string("Tag")
			var param = bbt.get_string("Param")
			realBBDialogLine = MyUtil.apply_bbcode(realDialogLine, tag, param)
	dialogLabel.visible_characters = 0
	var fullLine = realBBName + realBBDialogLine
	dialogLabel.text = fullLine
	#if previous tween is running, kill it, not nessasary, but just in case
	if readTween and readTween.is_running(): readTween.kill()
	readTween = create_tween() #only create once, or else it will override
	readTween.set_trans(Tween.TRANS_LINEAR)
	#readTweenStarted.emit() #TBD
	#get length of real name here, so bbcode won't be included
	var realNameLength = _name.format(DSManager.data).length() 
	var startPosition = realNameLength+1 #plus the ":" count
	for i in range(0, lineSections.size()):
		var sectionLength = lineSections[i].length()
		var speed: float = speedList[i] #index 0 is default reading speed from settings 
		var destination : float = startPosition + sectionLength
		var distance = abs(destination - startPosition)
		var delta :float = 0
		#if speed is 0, delta is 0, which should result in instant
		if speed != 0: delta = distance/speed
		var delay = delayList[i]
		readTween.chain().tween_interval(delay) #this will delay the tweener below
		readTween.chain().tween_property(dialogLabel,"visible_characters", destination, delta).from(startPosition)
		startPosition = destination #this destination the next start position
	
	await readTween.finished #TEST
	print(readTween.get_total_elapsed_time()) #TEST
