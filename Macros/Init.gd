@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["init"]

static func get_reminder(line_data: MagicMacrosLineData) -> String:
    return apply_macro(line_data)

static func is_macro_alias(arg: String) -> bool:
    return arg in ALIASES


static func apply_macro(line_data: MagicMacrosLineData) -> String:
    var s: String = ""
    s += "func _init() -> void:"
    s += "\n"
    s += line_data.single_indent + "pass"

    return s
