@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["tw", "tween"]

static func get_reminder(line_data: MagicMacrosLineData) -> String:
    return apply_macro(line_data)

static func is_macro_alias(arg: String) -> bool:
    return arg in ALIASES


static func apply_macro(line_data: MagicMacrosLineData) -> String:
    var s: String = line_data.indent + "var tween: Tween = create_tween()"
    return s
