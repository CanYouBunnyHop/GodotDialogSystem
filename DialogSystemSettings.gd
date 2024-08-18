@tool
class_name DialogSystemSettings extends Node
#const chResScript = Character_Resource
@export var dialogBox : RichTextLabel
@export_category("Global Data Loader")
@export_group("Character Resource")
#@export_dir var chResDirPath = "res://DialogSystemScripts/Character Resources"
@export var chResources : Array[CharacterBaseResource]
@export var chResDict : Dictionary
@export_category("Dialog Settings")
@export_exp_easing var	readingSpeed : float = 5
@export var formatdict: Dictionary
#@export_file("*.csv") var formatCSVPath
@export_group("Name Font Settings")
@export var defaultNameSettings : FontSettingsResource = preload("res://DialogSystemScripts/Base Resources/defaultFontSetting.tres")
@export_group("Font Settings")
@export var defaultFontSettings : FontSettingsResource = preload("res://DialogSystemScripts/Base Resources/defaultFontSetting.tres")

#@export var default
@export_group("Override Dialog Settings")
var useOverrideNameColor
func _ready() -> void:
	if dialogBox == null: dialogBox = get_node("Panel/RichTextLabel")
	if defaultFontSettings == null : defaultFontSettings = FontSettingsResource.new()
	if defaultNameSettings == null : defaultNameSettings = FontSettingsResource.new()
	dialogBox.add_theme_color_override("default_color", defaultFontSettings.color)
	dialogBox.add_theme_color_override("font_outline_color", defaultFontSettings.outlineColor)
	dialogBox.add_theme_color_override("font_shadow_color", defaultFontSettings.shadowColor)
	dialogBox.add_theme_constant_override("outline_size", defaultFontSettings.outlineSize)
	dialogBox.add_theme_constant_override("shadow_offset_y", defaultFontSettings.shadowOffset.y)
	dialogBox.add_theme_constant_override("shadow_offset_x", defaultFontSettings.shadowOffset.x)
	GlobalData.characterDataDict = make_character_resource_dict()
func _get_property_list():
	var properties = []
	properties.append_array([
	{
		name = "useOverrideNameColor",
		usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_CHECKABLE,
		type = TYPE_COLOR,
	},
	#{
		#name = "testVar",
		#usage = PROPERTY_USAGE_DEFAULT,
		#type = TYPE_ARRAY,
		#hint = PROPERTY_HINT_TYPE_STRING,
		#hint_string = "%d:" % [TYPE_DICTIONARY]
	#}
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
