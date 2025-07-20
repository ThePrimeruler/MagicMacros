@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["vars", "vs"]

static func is_macro_alias(arg: String) -> bool:
	return arg in ALIASES

static func get_reminder(line_data: MagicMacrosLineData) -> String:
	var arg:String = line_data.macro_arg
	var identifiers: Array[String] = line_data.identifier_args.duplicate()
	var types: Array[String] = line_data.type_args.duplicate()
	var values: Array[String] = line_data.remainder_args.duplicate()
	var filled_body: String = ""
	for index: int in identifiers.size():
		var identifier: String = identifiers[index]
		var type: String = "[b][var type][/b]" if types.is_empty() else (types[index] if len(types)>index else "[b][var type]?[/b]")
		var value: String = "[b][var value][/b]" if values.is_empty() else (values[index] if len(values)>index else "[b][var value]?[/b]")
		filled_body += " %s %s %s" % [identifier, type, value]
	var empty_body = ''
	if len(identifiers) <= len(types) and len(identifiers) <= len(values):
		empty_body = ' [b][var name][/b] [b][var type][/b] [b][var value][/b]'


	var macro_body = '%s%s%s' % [arg, filled_body, empty_body]
	return ' %s\n[center]═══════[/center]\n%s' % [macro_body, apply_macro(line_data)]


static func apply_macro(line_data: MagicMacrosLineData) -> String:
	var identifiers: Array[String] = line_data.identifier_args.duplicate()
	var types: Array[String] = line_data.type_args.duplicate()
	var values: Array[String] = line_data.remainder_args.duplicate()
	var s: String = ""
	for idx: int in identifiers.size():
		var identifier: String = identifiers[idx]
		var type: String = types[min(idx, types.size() - 1)] if not types.is_empty() else "type"
		var value: String = values[min(idx, values.size() - 1)] if not values.is_empty() else "null"

		var ss: String = line_data.indent + "var %s: %s = %s" % [identifier, type, value]
		s += ss
		if not idx == identifiers.size() - 1:
			s += "\n"
	return s
