class_name MyUtil
static var deltaTime:float:
	get: return Engine.get_main_loop().root.get_process_delta_time()
	
static func apply_bbcode(_text: String, _BBTag:String, _BBParam:String = "")->String:
	var result = "[{0}{2}]{1}[/{0}]".format([_BBTag, _text, _BBParam])
	return result

##NOTE Resource type hint is wack, if you need a filter use obj.get_script 
static func get_resources_from_dir(_dirPath : String) -> Array[Resource]:
	var resources : Array[Resource] = []
	var dir = DirAccess.open(_dirPath)
	if dir != null: #if directiory is valid
		dir.list_dir_begin()
		var fileName = dir.get_next() #get next file
		while not fileName.is_empty():
			var filePath = _dirPath+"/"+fileName
			if ResourceLoader.exists(filePath): #if it is a resource
				var res = ResourceLoader.load(filePath)
				print(res)
				resources.append(res)
			fileName = dir.get_next()
	return resources
	
static func random_range_vector2(min : float, max : float) -> Vector2:
	var rf = func()->float: return randf_range(min, max)
	return Vector2(rf.call(),rf.call())
static func random_range_vector3(min : float, max : float) -> Vector3:
	var rf = func()->float: return randf_range(min, max)
	return Vector3(rf.call(),rf.call(),rf.call())


#static func perlin_shake2D(input:Node2D, duration:float, strength:float, speed:float):
	#var origin:Vector2 = Vector2.ZERO
	#var noise = FastNoiseLite.new()
	#noise.noise_type = FastNoiseLite.TYPE_PERLIN
	#noise.frequency = 0.05
	#noise.offset = random_range_vector3(0,500)
	#var offset : Vector2 = Vector2(noise.offset.x, noise.offset.y)
	#noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	#var noisef = func(v:Vector2)->float: return noise.get_noise_2dv(noise.offset)
	#var timeElapsed:float= 0
#
	#while timeElapsed < duration:
		#var weight = timeElapsed/duration
		#timeElapsed += deltaTime
		#noise.offset.y += speed * deltaTime
		#input.position = input.position + origin.lerp(origin+(offset * strength), weight)
	#pass 
