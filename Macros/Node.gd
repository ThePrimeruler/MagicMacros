@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["node"]

static func get_sum_remanders(line_data: MagicMacrosLineData) -> String:
	var remainder_sum:String = ''
	if line_data.has_remainder:
		remainder_sum += ' '.join(line_data.remainder_args)
	if len(line_data.type_args) > 1:
		var type_args:Array[String] = line_data.type_args.duplicate()
		type_args.pop_front()
		remainder_sum += ' '.join(type_args)
	if len(line_data.identifier_args) > 1:
		var identifier_args:Array[String] = line_data.identifier_args.duplicate()
		identifier_args.pop_front()
		remainder_sum += ' '.join(identifier_args)
	return remainder_sum



static func get_reminder(line_data: MagicMacrosLineData) -> String:
	var arg:String = line_data.macro_arg
	var identifier:String = '[b][node name][/b]' if not line_data.has_identifier else line_data.identifier
	var type:String = '[b][node type][/b]' if not line_data.has_type else line_data.type
	var remainder_sum:String = get_sum_remanders(line_data)
	var remainder:String = '[b][node identifier][/b]' if not remainder_sum else remainder_sum
	var macro_body = '%s %s %s %s' % [arg, identifier, type, remainder]
	return ' %s\n[center]═══════[/center]\n%s' % [macro_body, apply_macro(line_data)]

static func is_macro_alias(arg: String) -> bool:
	return arg in ALIASES


static func apply_macro(line_data: MagicMacrosLineData) -> String:
	var s: String = "@onready var %s: %s = %s" % [line_data.identifier, line_data.type, line_data.remainder]
	return s
