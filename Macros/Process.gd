@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["prc", "process", "proc"]

static func get_reminder(line_data: MagicMacrosLineData) -> String:
	return apply_macro(line_data)

static func is_macro_alias(arg: String) -> bool:
	return arg in ALIASES


static func apply_macro(_line_data: MagicMacrosLineData) -> String:
	var s: String = ""
	s += "func _process(delta: float) -> void:"
	s += "\n"
	s += "    pass"

	return s
