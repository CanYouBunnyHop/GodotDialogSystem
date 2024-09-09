class_name SpeechBox extends Panel
@export var dialogLabel : DialogLabel
@export var dialogPortrait : Sprite2D
@export var buttonContainer : Container
@export var settings : SpeechBoxSettings
@export var audio : AudioStreamPlayer 
var readTween : Tween
var lockBox : bool = false
static var bbtagRegex :RegEx = RegEx.new():
	get:
		if not bbtagRegex.is_valid(): bbtagRegex.compile(r'^(?<Tag>\w+)(?<Param>( |=|).*)')
		return bbtagRegex
static var stampRegex :RegEx = RegEx.new():
	get:
		if not stampRegex.is_valid(): stampRegex.compile(r'\*(?<Speed>(?:[0-9]*[.])?[0-9]+)?(?:D(?<Delay>([0-9]*[.])?[0-9]+))\*|\*(?<Speed2>(?&Speed))\*')
		return stampRegex

func _ready() -> void:
	if audio == null: return
	if audio.stream == null: return
	dialogLabel.sig_visibleCharactersIncreased.connect(func():audio.play())
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


class StampSectionData: #TODO TBD change to struct
	var speed : float
	var delay : float
	var section : String
	func _init(_speed:float, _delay:float=0, _section:String="") -> void:
		self.speed = _speed
		self.delay = _delay
		self.section = _section
		pass
func get_stamp_section_datas(realDialogLine)-> Array[StampSectionData]:
	var defaultStamp : StampSectionData = StampSectionData.new(settings.readingSpeed)
	var stampSections : Array[StampSectionData] = [defaultStamp]
	#if no stamp, update defaultStamp's section to realDialogLine
	if stampRegex.search(realDialogLine) == null: stampSections.front().section = realDialogLine
	else:
		var slices : PackedStringArray
		var curDialogSlice = realDialogLine
		while stampRegex.search(curDialogSlice) != null:
			var curStamp:RegExMatch = stampRegex.search(curDialogSlice)
			var delay:float = curStamp.get_string("Delay").to_float() if curStamp.names.has("Delay") else 0.0
			var speed:float = settings.readingSpeed
			for s in ["Speed", "Speed2"]:
				if curStamp.names.has(s): speed = float(curStamp.get_string(s))
			slices = curDialogSlice.split(curStamp.get_string(),true)
			var section = slices[0]
			stampSections.append(StampSectionData.new(speed, delay, section))
			curDialogSlice = slices[1] #current slice becomes slice1
		if slices.size() > 1: 
			stampSections.back().section = slices[1]#lineSections.append(slices[1]) #after while loop, append the last slice
	return stampSections
func display_dialogline(dialogLine: String, _name:String = "", _bbtag:String = ""):
	var gChData = DSManager.characterDataDict
	var curCharacterData : CharacterBaseResource
	var bbname:String= _name
	if gChData.has(_name) && gChData[_name] is CharacterBaseResource:
		curCharacterData = gChData[_name]
		bbname = apply_font_setting(bbname, curCharacterData.nameFontSettings)
	else : #use default if characterBaseResource is not found
		bbname = apply_font_setting(bbname, settings.defaultNameSettings)	
	if !_name.is_empty(): bbname = MyUtil.apply_bbcode(bbname+":","b")
	#NOTE format after applyBB, so if data returned a duplicate name, dont apply same bb color
	#example: {player_name} = "John" is not the same "John" in predefined name
	var realBBName = bbname.format(DSManager.data)
	var realDialogLine = dialogLine.format(DSManager.data)
	
	var stmpSectDat : Array[StampSectionData]=get_stamp_section_datas(realDialogLine)
	
	#var defaultStamp : StampSectionData = StampSectionData.new(settings.readingSpeed)
	#var stampSections : Array[StampSectionData] = [defaultStamp]
	##if no stamp, update defaultStamp's section to realDialogLine
	#if stampRegex.search(realDialogLine) == null: stampSections.front().section = realDialogLine
	#else:
		#var slices : PackedStringArray
		#var curDialogSlice = realDialogLine
		#while stampRegex.search(curDialogSlice) != null:
			#var curStamp:RegExMatch = stampRegex.search(curDialogSlice)
			#var delay:float = curStamp.get_string("Delay").to_float() if curStamp.names.has("Delay") else 0.0
			#var speed:float = settings.readingSpeed
			#for s in ["Speed", "Speed2"]:
				#if curStamp.names.has(s): speed = float(curStamp.get_string(s))
			#slices = curDialogSlice.split(curStamp.get_string(),true)
			#var section = slices[0]
			#stampSections.append(StampSectionData.new(speed, delay, section))
			#curDialogSlice = slices[1] #current slice becomes slice1
		#if slices.size() > 1: 
			#stampSections.back().section = slices[1]#lineSections.append(slices[1]) #after while loop, append the last slice
			
	
	
	##seperate the dialog line with stamps
	#var lineSections : PackedStringArray #TBD refactor, using struct/2DArray
	#var speedList : Array[float] = [settings.readingSpeed]
	#var delayList : Array[float] = [0]
	##look for stamp and slice the line
	#if stampRegex.search(realDialogLine) == null: lineSections.append(realDialogLine)
	#else: #there there are stamp in dialogline
		#var slices : PackedStringArray 
		#var curDialogSlice = realDialogLine
		##while there is stamp in the current slice, loop splits line into 2 slices,
		##slice0 only have one section, slice1 could contain other more than one section 
		#while stampRegex.search(curDialogSlice) != null: 
			#var curStamp:RegExMatch = stampRegex.search(curDialogSlice)
			#var delay:float = curStamp.get_string("Delay").to_float() if curStamp.names.has("Delay") else 0.0
			#var speed:float = settings.readingSpeed
			#for skey in ["Speed", "Speed2"]:
				#if curStamp.names.has(skey): speed = float(curStamp.get_string(skey))
			#speedList.append(speed) #append speed
			#delayList.append(delay) #append delay
			#slices = curDialogSlice.split(curStamp.get_string(),true)
			#lineSections.append(slices[0]) #append first slice
			#curDialogSlice = slices[1] #current slice becomes slice1
		#if slices.size() > 1:lineSections.append(slices[1]) #after while loop, append the last slice
	##else: lineSections.append(realDialogLine) #if no stamps, the whole line is a section
	var lineSections:PackedStringArray = [] 
	for stmp in stmpSectDat: lineSections.append(stmp.section)
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
	
	var fullLine = realBBName + realBBDialogLine
	dialogLabel.text = fullLine
	
	
	#get length of real name here again, so bbcode won't be included
	var realName = _name.format(DSManager.data)
	var realNameLength = MyUtil.strip_bbcode(realName).length() 
	var startPosition = realNameLength+1 #plus the ":" count
	read_animation(startPosition, stmpSectDat)
	
	
	
	##TODO SEPERATE ANIMATION TO A DIFF FUNCTION
	#dialogLabel.ds_visibleCharacters = 0
	##if previous tween is running, kill it, not nessasary, but just in case
	#if readTween and readTween.is_running(): readTween.kill()
	#readTween = create_tween() #only create once, or else it will override
	#readTween.set_trans(Tween.TRANS_LINEAR)
	##get length of real name here, so bbcode won't be included
	#var realNameLength = _name.format(DSManager.data).length() 
	#var startPosition = realNameLength+1 #plus the ":" count
	#
	#for stmp in stmpSectDat:
		#var sectionLength: = stmp.section.length()
		#var speed:float = stmp.speed
		#var delay:float = stmp.delay
		#var destination:float = startPosition + sectionLength
		#var distance = abs(destination - startPosition)
		#var delta:float = 0
		#if speed != 0: delta = distance/speed
		#readTween.chain().tween_interval(delay) #this will delay the tweener below
		#readTween.chain().tween_property(dialogLabel,"ds_visibleCharacters", destination, delta).from(startPosition)
		#startPosition = destination #this destination the next start position
	
	
	
	#for i in range(0, lineSections.size()):
		#var sectionLength = lineSections[i].length()
		#var speed: float = speedList[i] #index 0 is default reading speed from settings 
		#var destination : float = startPosition + sectionLength
		#var distance = abs(destination - startPosition)
		#var delta :float = 0
		##if speed is 0, delta is 0, which should result in instant
		#if speed != 0: delta = distance/speed
		#var delay = delayList[i]
		#readTween.chain().tween_interval(delay) #this will delay the tweener below
		#readTween.chain().tween_property(dialogLabel,"ds_visibleCharacters", destination, delta).from(startPosition)
		#startPosition = destination #this destination the next start position
	#await readTween.finished #TEST
	#print("tweenElapsedTime=", readTween.get_total_elapsed_time()) #TEST

func read_animation(startPos:int, stmpSectDat:Array[StampSectionData]):
	dialogLabel.ds_visibleCharacters = 0
	#if previous tween is running, kill it, not nessasary, but just in case
	if readTween and readTween.is_running(): readTween.kill()
	readTween = create_tween() #only create once, or else it will override
	readTween.set_trans(Tween.TRANS_LINEAR)
	for stmp in stmpSectDat:
		var sectionLength: = stmp.section.length()
		var speed:float = stmp.speed
		var delay:float = stmp.delay
		var destination:float = startPos + sectionLength
		var distance = abs(destination - startPos)
		var delta:float = 0
		if speed != 0: delta = distance/speed
		readTween.chain().tween_interval(delay) #this will delay the tweener below
		readTween.chain().tween_property(dialogLabel,"ds_visibleCharacters", destination, delta).from(startPos)
		startPos = destination #this destination the next start position
