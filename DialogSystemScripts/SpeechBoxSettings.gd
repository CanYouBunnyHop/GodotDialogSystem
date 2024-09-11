class_name SpeechBoxSettings extends Node #TODO MOVE TO EVERYTING TO SPEECHBOX 
@export var speechBox : SpeechBox:
	get: return speechBox if speechBox != null else $"Speech Box"
@export_category("Dialog Settings")
@export var	readingSpeed : float = 20
@export_group("Name Font Settings")
@export var defaultNameSettings : FontSettingsResource = preload("res://DialogSystemScripts/Base Resources/DefaultFontSetting.tres")
@export_group("Font Settings")
@export var defaultFontSettings : FontSettingsResource = preload("res://DialogSystemScripts/Base Resources/DefaultFontSetting.tres")
@export var shadowColor : Color = Color.BLACK
@export var shadowOffset : Vector2i = Vector2i(0, 0)

func _ready() -> void:
	if defaultFontSettings == null : defaultFontSettings = FontSettingsResource.new()
	if defaultNameSettings == null : defaultNameSettings = FontSettingsResource.new()
	speechBox.dialogLabel.add_theme_color_override("default_color", defaultFontSettings.color)
	speechBox.dialogLabel.add_theme_color_override("font_outline_color", defaultFontSettings.outlineColor)
	speechBox.dialogLabel.add_theme_constant_override("outline_size", defaultFontSettings.outlineSize)
	speechBox.dialogLabel.add_theme_color_override("font_shadow_color", shadowColor)
	speechBox.dialogLabel.add_theme_constant_override("shadow_offset_y", shadowOffset.y)
	speechBox.dialogLabel.add_theme_constant_override("shadow_offset_x", shadowOffset.x)
