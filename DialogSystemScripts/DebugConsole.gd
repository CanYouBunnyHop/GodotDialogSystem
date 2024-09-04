class_name DebugConsole extends CanvasLayer
var edit : LineEdit
var label : RichTextLabel
func _input(event: InputEvent) -> void:
	if event.is_action_released("OpenDebugConsole"):
		self.visible = not self.visible
		edit.clear()
		edit.grab_focus()
func _ready() -> void:
	edit = LineEdit.new()
	edit.top_level = true
	edit.set_anchor(SIDE_RIGHT, 1)
	edit.offset_left = 15
	edit.offset_top = 15
	edit.offset_right = -15
	#construct label
	label = RichTextLabel.new()
	label.top_level = true
	label.scroll_active = true
	label.scroll_following = true
	label.set_anchor(SIDE_RIGHT, 1)
	label.offset_left = 15
	label.offset_top = 46
	label.offset_right = -15
	label.offset_bottom = 210
	label.bbcode_enabled = true
	self.add_child(edit)
	self.add_child(label)
	self.visible = false
	edit.text_submitted.connect(enter_text_input)
func enter_text_input(input:String):
	if input.begins_with("/"): 
		CmdListener.handle_input(input.trim_prefix("/"))
	else: debug_log("User: "+input)
	edit.clear()
func debug_warn(input:String):
	var warn = "[color=orange]"+"WARNING: "+input+"[/color]"
	push_warning(input)
	print_rich(warn)
	label.append_text(warn)
	label.newline()
func debug_error(input:String):
	var err = "[color=red]"+"ERROR: "+input+"[/color]"
	push_error(input)
	print_rich(err)
	label.append_text(err)
	label.newline()
func debug_log(input : String):
	print(input)
	label.add_text(input)
	label.newline()
