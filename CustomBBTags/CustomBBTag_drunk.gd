@tool
extends RichTextEffect
class_name RichTextDrunk

var bbcode = "drunk"
static var noise : FastNoiseLite :
	get:
		if noise != null: return noise
		var n:FastNoiseLite = FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_PERLIN
		n.frequency = 0.05
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
		return n
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var spacing = char_fx.env.get("space", 15)
	var speed = char_fx.env.get("speed", 25)
	var strength = char_fx.env.get("strength", 3)
	
	var relNoiseX = (char_fx.relative_index * spacing)
	var relNoiseY = char_fx.elapsed_time * speed
	var XnoisePos:Vector2 = Vector2(relNoiseX, relNoiseY)
	var YnoisePos:Vector2 = Vector2(relNoiseX, -relNoiseY)
	var offset:Vector2 = Vector2(noise.get_noise_2dv(XnoisePos), noise.get_noise_2dv(YnoisePos))
	char_fx.offset = char_fx.offset + offset * strength
	return true
