@tool
extends RichTextEffect
class_name RichTextReadSpeed

var bbcode = "rs"
func _process_custom_fx(char_fx: CharFXTransform)->bool:
	var readSpeed = char_fx.env.get("speed", 1) # char per second
	var delay = char_fx.env.get("delay", 0)
	
	#var distanceTravelled = 0
	#var previousSpeed = 1
	#var timeTook = distanceTravelled/previousSpeed
	
	var distance = char_fx.range.x
	
	var snapshotTime = 0
	#ratio 1
	#ratio 0/50
	#ratio 1/50
	if ((char_fx.elapsed_time-delay) * readSpeed) < char_fx.range.x:
		char_fx.visible = false 
	else:
		char_fx.visible = true
		
	#if (char_fx.elapsed_time-delay) == char_fx.range.x:
		#snapshotTime = char_fx.elapsed_time
	
	#var startIndex = char_fx.env.get("start_index", 0)
	#var previousReadSpeed = char_fx.env.get("previous_speed", 1)
#
	#if readSpeed <= 0: return false
	#var delay = previousReadSpeed * startIndex
	#var newElapsed_time = char_fx.elapsed_time - delay
	#if (char_fx.elapsed_time * readSpeed) < char_fx.range.x: char_fx.visible = false
	#else: char_fx.visible = true
	return true
