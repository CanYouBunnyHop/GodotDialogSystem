class_name DialogLabel extends RichTextLabel
signal sig_visibleCharactersIncreased
var ds_visibleCharacters :int:
	get: return visible_characters
	set(value):
		if value > visible_characters: sig_visibleCharactersIncreased.emit()
		visible_characters = value
