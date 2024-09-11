class_name MyUtil
static var deltaTime:float:
	get: return Engine.get_main_loop().root.get_process_delta_time()
static var bbregex:RegEx = RegEx.new():
	get:
		if not bbregex.is_valid(): bbregex.compile(r'\[.+?\]')
		return bbregex
		
static func strip_bbcode(_text:String) -> String:
	return bbregex.sub(_text, "", true)
		
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
