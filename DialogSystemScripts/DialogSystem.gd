class_name DialogSystem extends CanvasLayer
#
# CanvasLayer.follow_viewport_enabled = true, means it wont follow camera
# CanvasLayer.follow_viewport_enabled = false, means it is overlay for camera

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
@export_file("*.txt") var filePath:String
@export var speechBox : SpeechBox: #TODO This may return error if speech box is not found
	get: return speechBox if speechBox != null else $"Speech Box"
static var flagRegex : RegEx:
	get: 
		if flagRegex != null: return flagRegex
		flagRegex = RegEx.new()
		flagRegex.compile(r'^--(?<Flag>\s*\w+\s*)--')
		return flagRegex
var isActive : bool = false
#var readTween : Tween
#var lockDialogBox : bool = false #NOTE when locked, dialog won't be updated, used for button prompt
var timer:SceneTreeTimer
var interactReady:bool = true
func get_system_info()->String:
	return "DialogSystemID:{0}, readableLines = {1}\ncurrentLineNumber = {2}".format([dialogSystemID, currentConversation.size(), currentLine])
func _ready():
	#NOTE Try adding self to globaldata dialog system dict using defined ID or Instance ID
	if dialogSystemID.is_empty() or dialogSystemID == null:
		dialogSystemID = str(get_instance_id())
		Console.debug_warn("Dialog System ID is not found, Instance ID is used instead %s"%[dialogSystemID])
	GlobalData.dialogSystemDict[dialogSystemID] = self
	read_conversationFile(filePath)
	var begin = func():
		currentLine = -1
		play_next_dialog()
	signal_start_convo.connect(begin)
	signal_jump.connect(play_next_dialog) #this signal requires flag as argument
	signal_all_set_active.connect(func(b): isActive = b)
	
	Console.debug_log(get_system_info())
	
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
func read_conversationFile(_filePath : String):
	var f = FileAccess.open(_filePath, FileAccess.READ)
	#return if file is not found
	if not FileAccess.file_exists(_filePath):
		Console.debug_error("txt file is NOT FOUND\nPath: %s"%[_filePath])
		return
	# f.eof_reached() Returns true if the file cursor read past the end of the file.
	while not f.eof_reached():
		var line = f.get_line().strip_edges(true, false) #strips white spaces from left
		var isComment = line.begins_with("#")
		#don't read further if it's empty or comment
		if line.is_empty() or isComment: continue 
		var flag = flagRegex.search(line)
		if flag != null: 
			var flagName = flag.get_string("Flag").strip_edges()
			flagDict[flagName] = currentConversation.size()
			continue
		currentConversation.append(line)
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
		Console.debug_log("end conversation")
		return
	var snapshot : LineCapture
	while currentLine <= currentConversation.size():
		currentLine += 1
		snapshot = LineCapture.new(get_line())
		#if not a choice, and boxA is true, handle boxB input if line is empty, continue to next line
		if snapshot.isChoice: break #break if it's a choice, 
		if not snapshot.boxACon: continue #if box a is not true, continue
		CmdListener.handle_input(snapshot.boxB)#if not a choice, boxa is true and full is empty
		if not snapshot.full.is_empty(): break #if the "not choice" is not an empty dialog line, break
	print(str(currentLine) + ":" + get_line()) #TEST
	if snapshot.boxACon and not snapshot.isChoice and not snapshot.full.is_empty():
		speechBox.display_dialogline(snapshot.dialog, snapshot.name, snapshot.bbtag)
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
#func end_conversation():
	#pass
