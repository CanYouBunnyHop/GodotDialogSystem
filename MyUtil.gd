class_name MyUtil
static func apply_bbcode(_text: String, _BBTag:String, _BBParam:String = "")->String:
	var result = "[{0}{2}]{1}[/{0}]".format([_BBTag, _text, _BBParam])
	return result
