class_name SpeechBox extends Panel
@export var dialogLabel : DialogLabel #TODO TBD exception for null reference
@export var dialogPortrait : Sprite2D
@export var buttonContainer : Container
@export var settings : SpeechBoxSettings
@export var audio : AudioStreamPlayer 
var readTween : Tween
var lockBox : bool = false
const EXFLOAT : String = r'[0-9]*[.])?[0-9]+'
static var bbtagRegex :RegEx = RegEx.new():
	get:
		if not bbtagRegex.is_valid(): bbtagRegex.compile(r'^(?<Tag>\w+)(?<Param>( |=|).*)')
		return bbtagRegex
static var stampRegex :RegEx = RegEx.new():
	get:
		if not stampRegex.is_valid(): stampRegex.compile(r'\*(?<Speed>(?:{f})?(?:D(?<Delay>({f}))\*|\*(?<Speed2>(?&Speed))\*'.format({"f":EXFLOAT}))
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
	var captures = LineCapture.new(_line)#commandBoxRegex won't return null
	var choiceText:String = ">"+captures.full
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
	if captures.boxACon == false:
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
		if slices.size() > 1: stampSections.back().section = slices[1]#after loop, insert last section
	return stampSections
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
func display_dialogline(dialogLine: String, _name:String = "", _bbtag:String = ""):
	var gChData = DSManager.characterDataDict
	var bbname:String = apply_font_setting(_name, settings.defaultNameSettings)	
	if gChData.has(_name):
		var curCharacterData : CharacterBaseResource = gChData[_name]
		bbname= apply_font_setting(bbname, curCharacterData.nameFontSettings)
	if !_name.is_empty(): bbname = MyUtil.apply_bbcode(bbname+":","b")#suffix with ":" and bold
	#NOTE format after applyBB, so if data returned a duplicate name, dont apply same bb color
	#example: {player_name} = "John" is not the same "John" in predefined name
	var realBBName = bbname.format(DSManager.data)
	var realDialogLine = dialogLine.format(DSManager.data)
	var stmpSectDat:Array[StampSectionData]= get_stamp_section_datas(realDialogLine)
	var lineSections:PackedStringArray = [] 
	for stmp in stmpSectDat: lineSections.append(stmp.section)
	#join line sections after removing stamps
	realDialogLine = "".join(lineSections)
	var realBBDialogLine = realDialogLine
	if not _bbtag.is_empty():
		var bbtagChain = _bbtag.split(",")
		for bb in bbtagChain:
			var bbt = bbtagRegex.search(bb.strip_edges())
			var tag = bbt.get_string("Tag")
			var param = bbt.get_string("Param")
			realBBDialogLine = MyUtil.apply_bbcode(realDialogLine, tag, param)
	var fullLine = realBBName + realBBDialogLine
	dialogLabel.text = fullLine
	#get length of real name here again, so bbcode won't be included
	var realNameLength = MyUtil.strip_bbcode(realBBName).length() 
	var startPosition = realNameLength
	read_animation(startPosition, stmpSectDat)
