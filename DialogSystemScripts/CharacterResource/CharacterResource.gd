class_name Character_Resource extends Resource

#@export var name : String
@export var texture : AtlasTexture
@export var color : Color = Color.WHITE : 
	get: return color.to_html()
@export var toneDict : Dictionary
@export var frameCoordSize : Vector2i = Vector2i(1,1)

func get_tone_dict():
	pass
