extends Control
#const dict = {ONE = "ass", TWO = 2}
#var reg = RegEx.new()
#var dict = {
	#ONE = func(stuff): print(stuff),
#}
#@onready var interactCooldown = get_tree().create_timer(5, true, false, true)
@export var no : Noise
@export var sprite : Sprite2D
#@onready var array : Array = []
#var n := -1
#var t : bool = (func()->bool: return n >= array.size()-1).call()
func _ready() -> void:
	#MyUtil.perlin_shake2D(sprite, 3, 5, 5 )
	#await interactCooldown.timeout
	#print("Timeout")
#region Tween testing Region
	#conver time taken to speed
	#var xpos = [800, 900, 400]
	#var speeds = [200, 50, 400]
	#var delay = [3,5,2]
	#var tween = create_tween()
	#tween.set_trans(Tween.TRANS_LINEAR)
	##turn time into a fixed speed
	#var distance
	#var startPos = $Sprite2D.position.x
	#for i in range(0, xpos.size()):
		#var finalx = xpos[i]
		#var speed = speeds[i]
		#if i != 0: startPos = xpos[i-1]
		#distance = abs(finalx - startPos)#800-200=600, 900-200=700, 
		#tween.tween_property($Sprite2D,"position:x", finalx, distance/speed).from(startPos)
		#await tween.tween_interval(delay[i])
	#await tween.finished
	#print(tween.get_total_elapsed_time())
#endregion
	#var ar = [5,1,2,3,4,5] 
	#var n : Expression = Expression.new()
	#var err:Error = n.parse("a + o + b",["a","o","b",])#n.parse("{0}{1}{2}".format([2,"+=",1]))
	#if err != OK:
		#print("NOT OK", err)
	#else: print("OK", err)
	#
	#var nres = n.execute(["butt","hole","ass"])
	#if not n.has_execute_failed():
		#print(nres)
	#else:
		#print(n.get_error_text())
	#var s = "a     b".split(" ")
	#print(s)
	
	#dict.ONE.call("i can say anything i want", 0)
	#(func(): print("called")).call()
	#var arr = [[[1,2,3]],[[3,2,1]]]
	#for x in arr:
		#print(x)
		#for y in x:
			#print(y)
			#for z in y:
				#print(z)
	#make = (arg) => "".join(["a","b"])
	pass
func make_arr(arg):
	pass
#func dict2 ()-> Dictionary:
	#return {datass = "ass", TWO = "dude"}
