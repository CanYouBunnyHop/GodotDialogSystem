class_name Command
extends CommandBase
signal signal_command(arg : String)
func _init(_id:String, _description:String, _format: String, callable: Callable):
	super._init(_id, _description, _format)
	signal_command.connect(callable)
func execute(arg):
	signal_command.emit(arg)
