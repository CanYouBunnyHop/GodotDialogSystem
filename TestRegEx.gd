extends Control

var lineCaptureRegex = RegEx.new()
func _ready() -> void:
	lineCaptureRegex.compile(r'^(?:(?<Button>>\s*)|)(?:(?:\((?<BoxA>[^\(\)]*)\))|)((?:(?<Name>\w+):|)(?:(?<Dialog>[^\/\(\[]*)))(?:\/|)(?(?<=\/)\s*(?<Tone>\w*)|)(?:\s*\[(?<BBCmd>.*)]|)\s*(?:(?:\((?<BoxB>[^\(\)]*)\))|)')
	printRegex("Red: My color is red ()")
	printRegex(">()Red: My color is red/s[shake, b]()")
	printRegex("()Red: My color is red/s[shake]()")
	printRegex("Red: My color is red [shake]()")
	printRegex("My color is red ()")
	printRegex("My color is red[b]")
	printRegex("My color is red/s")
	printRegex(">My color is red [shake, b]")
func printRegex(input : String):
	var result : RegExMatch = lineCaptureRegex.search(input)
	print(result.strings)
