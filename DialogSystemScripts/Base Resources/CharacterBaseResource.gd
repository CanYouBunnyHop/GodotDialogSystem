class_name CharacterBaseResource extends Resource
@export var name_ : String
@export_category("Portrait")
@export var atlas : AtlasTexture
@export_category("Text Settings")
@export var nameColor : Color = Color.WHITE
var nameColorHex : String:
	get: return nameColor.to_html()
@export var toneList : Array[ToneBaseResource]
var toneDict : Dictionary
