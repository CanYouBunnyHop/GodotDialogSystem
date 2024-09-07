#@tool
class_name SpeechBoxSettings extends Node
#const chResScript = Character_Resource
@export var speechBox : SpeechBox:
	get: return speechBox if speechBox != null else $"Speech Box"
@export_category("Global Data Loader")
@export_group("Character Resource") #TODO move this to a dedicated loader using directory
#@export_dir var chResDirPath = "res://DialogSystemScripts/Character Resources"
@export var chResources : Array[CharacterBaseResource]
@export var chResDict : Dictionary
@export_category("Dialog Settings")
@export var	readingSpeed : float = 20
@export var formatdict: Dictionary
#@export_file("*.csv") var formatCSVPath
@export_group("Name Font Settings")
@export var defaultNameSettings : FontSettingsResource = preload("res://DialogSystemScripts/Base Resources/DefaultFontSetting.tres")
@export_group("Font Settings")
@export var defaultFontSettings : FontSettingsResource = preload("res://DialogSystemScripts/Base Resources/DefaultFontSetting.tres")
@export var shadowColor : Color = Color.BLACK
@export var shadowOffset : Vector2i = Vector2i(0, 0)
#@export var default
#@export_group("Override Dialog Settings")
#var useOverrideNameColor:
	#get: return useOverrideNameColor
	#set(val): 
		#useOverrideNameColor = val
		#notify_property_list_changed()
func _ready() -> void:
	#if dialogBox == null: dialogBox = get_node("Panel/RichTextLabel")
	if defaultFontSettings == null : defaultFontSettings = FontSettingsResource.new()
	if defaultNameSettings == null : defaultNameSettings = FontSettingsResource.new()
	speechBox.dialogLabel.add_theme_color_override("default_color", defaultFontSettings.color)
	speechBox.dialogLabel.add_theme_color_override("font_outline_color", defaultFontSettings.outlineColor)
	speechBox.dialogLabel.add_theme_constant_override("outline_size", defaultFontSettings.outlineSize)
	speechBox.dialogLabel.add_theme_color_override("font_shadow_color", shadowColor)
	speechBox.dialogLabel.add_theme_constant_override("shadow_offset_y", shadowOffset.y)
	speechBox.dialogLabel.add_theme_constant_override("shadow_offset_x", shadowOffset.x)
	#DSManager.characterDataDict = make_character_resource_dict()
#func _get_property_list():
	#var properties:Array[Dictionary] = []
	#properties.append_array([
	#{
		#name = "useOverrideNameColor",
		#usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_CHECKABLE,
		#type = TYPE_COLOR,
	#},
	#])
	#return properties
#func _get(property):
	#if property == "useOverrideNameColor":
		#return useOverrideNameColor
#func _set(property, value)->bool:
	#if property == "useOverrideNameColor":
		#useOverrideNameColor = value
		#return true
	#return false


	
#func make_character_resource_dict() -> Dictionary:
	#var dict : Dictionary = {}
	#for ch in chResources:
		#if(ch.get("name_")== null):
			#push_warning("Character name property is not found, you may have unrelated files in this directory")
			#continue
		#var key = ch.name_
		#if key == "":
			#push_error(ch.get_rid(), ", character name is not found")
			#continue
		#dict[key] = ch
	#return dict
#func read_csv(path : String):
	#var f = FileAccess.open(path, FileAccess.READ)
	#if FileAccess.file_exists(path):
		#while !f.eof_reached():
			#var s = f.get_csv_line(";")
			#print(s)
