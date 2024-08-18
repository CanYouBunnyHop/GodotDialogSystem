class_name CharacterBaseResource extends Resource
@export var name_ : String
@export_category("Portrait")
@export var atlas : AtlasTexture
@export_category("Text Settings")
@export var nameFontSettings : FontSettingsResource = preload("res://DialogSystemScripts/Base Resources/defaultFontSetting.tres")
@export var toneList : Array[ToneBaseResource]
var toneDict : Dictionary
