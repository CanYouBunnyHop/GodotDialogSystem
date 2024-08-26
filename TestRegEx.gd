extends Control
#const dict = {ONE = 1, TWO = 2}
#var reg = RegEx.new()
func _ready() -> void:
	#conver time taken to speed
	var xpos = [800, 900, 400]
	var speeds = [200, 50, 400]
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	#turn time into a fixed speed
	#var distance = 1800
	#var speed = 1000
	#var time = 1800/1000
	var distance
	var startPos = $Sprite2D.position.x
	for i in range(0, xpos.size()):
		var finalx = xpos[i]
		var speed = speeds[i]
		if i != 0: startPos = xpos[i-1]
		distance = abs(finalx - startPos)#800-200=600, 900-200=700, 
		tween.tween_property($Sprite2D,"position:x", finalx, distance/speed).from(startPos)
	#await tween.finished
	#print(tween.get_total_elapsed_time())
	for i in range(0,0):
		print("s")
	pass
#func dict2 ()-> Dictionary:
	#return {datass = "ass", TWO = "dude"}
