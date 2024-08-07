class_name CommandBase
##Commad Idendification
var ID : String
##Explains Command functionality
var description : String
##How to format Command
var format : String
func _init(_id:String, _description:String, _format:String):
	ID = _id
	description = _description
	format = _format
	
