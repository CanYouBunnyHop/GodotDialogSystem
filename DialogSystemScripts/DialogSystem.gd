class_name DialogSystem extends CanvasLayer
#
# CanvasLayer.follow_viewport_enabled = true, means it wont follow camera
# CanvasLayer.follow_viewport_enabled = false, means it is overlay for camera

var currentLineIndex :int = -1 :
	set(value): currentLineIndex = clampi(value,-1, currentConversation.size()-1)
var flagDict : Dictionary = {"beginning": 0}
var currentConversation : Array[String] = []
#TODO Signal Connections: Ensure signals are properly disconnected 
#if the dialog system is removed or replaced, 
#to avoid potential memory leaks or unintended behavior.
signal sig_start_convo
signal sig_focus

##[color=orange][b]WARNING[/b][/color]: do not use spaces and special characters other than "_"
@export var dialogSystemID : String = ""
@export_file("*.txt") var filePath:String

#TODO This may return error if speech box is not found
#NOTE not using static speech box, sometimes speechbox can have different settings
@export var speechBox : SpeechBox : 
	get: return speechBox if speechBox != null else $"Speech Box"
static var flagRegex : RegEx = RegEx.new():
	get: 
		if not flagRegex.is_valid(): flagRegex.compile(r'^--(?<Flag>\s*\w+\s*)--')
		return flagRegex
var lastDisplayableLine : LineCapture

func is_conversation_over()->bool: return currentLineIndex >= currentConversation.size()-1
func get_system_info()->String:
	return "DialogSystemID:{0}, readableLines = {1}\ncurrentLineIndex = {2}".format([dialogSystemID, currentConversation.size(), currentLineIndex])
func _ready():
	#NOTE Try adding self to dialog system dict using defined ID or Instance ID
	if dialogSystemID.is_empty() or dialogSystemID == null:
		dialogSystemID = str(get_instance_id())
		Console.debug_warn("Dialog System ID is not found, Instance ID is used instead %s"%[dialogSystemID])
	DSManager.dialogSystemDict[dialogSystemID] = self
	
	#Connect Signals
	var begin = func():
		currentLineIndex = -1
		play_dialog()
	sig_start_convo.connect(begin)
	DSManager.sig_all_vis.connect(func(b): visible = b)
	sig_focus.connect(func(): 
		DSManager.sig_all_vis.emit(false) # every dialog systme is not visible
		visible = true # but self visible is true
	)
	Console.debug_log(get_system_info())
	read_conversationFile(filePath)	
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
	var nline = currentLineIndex + _n
	if nline >= currentConversation.size(): return ""
	else: return currentConversation[nline].strip_edges()
func interact_exit_early()-> bool:
	#if still reading, stop reading, show full text instead
	if speechBox.readTween and speechBox.readTween.is_running():
		speechBox.readTween.kill()
		speechBox.dialogLabel.visible_ratio = 1
		return true
	if DSManager.sig_interact_blocker.get_connections().size() > 0:
		DSManager.sig_interact_blocker.emit()
		return true
	if speechBox.lockBox: return true #if choices appeared, next dialog won't be updated
	return false
func interact_play():
	if interact_exit_early() == false: play_dialog()
func interact_play_next():
	if interact_exit_early() == false: play_next_dialog()
func play_dialog():
	#currentDisplayedLine is null, means the system has never been interacted, 
	if lastDisplayableLine == null:
		play_next_dialog()
		return
	if lastDisplayableLine.is_displayable(): #TESTING double check if it is displayble
		speechBox.display_dialogline(lastDisplayableLine.dialog, lastDisplayableLine.name, lastDisplayableLine.bbtag)
	#TESTING
	else: Console.debug_error("lastDisplayableLine, is not a displayble")
func play_next_dialog(_flagName : String = ""):
	#if flag exist, go to flag
	if _flagName != "": currentLineIndex = flagDict[_flagName] - 1 #minus one here because while loop adds one first
	#if the conversation is over, returns
	if is_conversation_over() == true: 
		Console.debug_log("end conversation")
		end_conversation()
		return
	var snapshot:LineCapture
	#while conversation is not over	
	while is_conversation_over() == false:
		currentLineIndex += 1
		snapshot = LineCapture.new(get_line())
		if snapshot.isChoice: break #break if it's a choice
		#if boxACon is false, continue to next line
		if snapshot.boxACon == false: continue
		#if not a choice, boxa is true and full is empty
		CmdListener.handle_input(snapshot.boxB)
		#if dialog is not empty \ if boxACon == false or isChoice or full.is_empty():
		if not snapshot.full.is_empty():
			lastDisplayableLine = snapshot
			break
		#if dialog is empty and blocker size > 0
		elif DSManager.sig_interact_blocker.get_connections().size() > 0:
			DSManager.sig_interact_blocker.emit()
			return #WARNING RETURNING HERE MAY BREAK SOME FUTURE IMPLEMENTATION 
	print(str(currentLineIndex) + ":" + get_line()) #TEST
	if snapshot.is_displayable(): play_dialog()
	#display buttons, while currentline is a choice, loops
	while LineCapture.new(get_line()).isChoice:
		#probably not needed, but just in case 
		if currentLineIndex > currentConversation.size(): break
		speechBox.create_choice_button(get_line()) #create button 
		var nextline = get_line(1)
		#if next line is not a choice, break the loop
		if not LineCapture.new(nextline).isChoice: break
		currentLineIndex += 1
		print(str(currentLineIndex) + ":" + get_line()) #TEST
func end_conversation():
	visible = false
	if DSManager.focusedSystem == self: DSManager.focusedSystem = null
