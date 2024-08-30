@tool
extends RichTextEffect
class_name RichTextBoom

var bbcode = "boom"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	return true
