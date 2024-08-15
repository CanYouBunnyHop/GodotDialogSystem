@tool
class_name Dialog_System_Settings extends Node
#const chResScript = Character_Resource
@export_category("Global Data Loader")
@export_group("Character Resource")
@export_dir var chResDirPath = "res://DialogSystemScripts/Character Resources"
@export var chResources : Array[Resource]:
	get: return chResources
	set(value):
		if value is Array[Resource]:
			chResources = value 
		else:
			print("Parsing Invalid Resources")
@export_group("Text Placeholders")
#@export_file("*.csv") var formatCSVPath
@export var formatdict: Dictionary
@export_group("Override Dialog Settings")
var useOverrideNameColor
var testDict : Dictionary
const TREE = {
	
}
func _get_property_list():
	var properties = []
	properties.append_array([
	{
		name = "useOverrideNameColor",
		usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_CHECKABLE,
		type = TYPE_COLOR,
	},
	])
	return properties
func _get(property):
	if property == "useOverrideNameColor":
		return useOverrideNameColor
func _set(property, value):
	if property == "useOverrideNameColor":
		useOverrideNameColor = value
		return true
	return false
	
func _ready():
	print("Ready")
	chResources = get_resources_from_dir(chResDirPath)
	Global_Data.characterDataDict = make_character_resource_dict()
func get_resources_from_dir(_dirPath : String) -> Array[Resource]:
	var resources : Array[Resource] = []
	var dir = DirAccess.open(_dirPath)
	if dir != null: #if directiory is valid
		dir.list_dir_begin()
		var fileName = dir.get_next() #get next file
		while not fileName.is_empty():
			var filePath = _dirPath+"/"+fileName
			if ResourceLoader.exists(filePath):
				var res = ResourceLoader.load(filePath)
				print(res)
				resources.append(res)
			fileName = dir.get_next()
	return resources
func make_character_resource_dict() -> Dictionary:
	var dict : Dictionary = {}
	for ch in chResources:
		if(ch.get("name_")== null):
			push_warning("Character name property is not found, you may have unrelated files in this directory")
			continue
		var key = ch.name_
		if key == "":
			push_error(ch.get_rid(), ", character name is not found")
			continue
		dict[key] = ch
	return dict
#func read_csv(path : String):
	#var f = FileAccess.open(path, FileAccess.READ)
	#if FileAccess.file_exists(path):
		#while !f.eof_reached():
			#var s = f.get_csv_line(";")
			#print(s)
