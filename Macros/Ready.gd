@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["rdy", "ready"]

static func get_reminder(line_data: MagicMacrosLineData) -> String:
	return apply_macro(line_data)

static func is_macro_alias(arg: String) -> bool:
	return arg in ALIASES


static func apply_macro(line_data: MagicMacrosLineData) -> String:
	var s: String = ""
	s += "func _ready() -> void:"
	s += "\n"
	s += line_data.s_in + "pass"

	return s
