class_name Character_Resource extends Resource
@export var name_ : String
@export_group("Portrait")
@export var atlasYpos : int = 0
@export_group("Text Settings")
@export var nameColor : Color = Color.WHITE
var nameColorHex : String:
	get: return nameColor.to_html()
@export var toneList : Array[String] = ["default"]
func get_tone_x_pos(_input : String = ""):
	return toneList.find(_input)
