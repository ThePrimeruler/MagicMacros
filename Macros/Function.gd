@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["fn", "fnc"]


static func get_sum_remanders(line_data: MagicMacrosLineData) -> String:
	var remainder_sum:String = ''
	if line_data.has_remainder:
		remainder_sum += ' '.join(line_data.remainder_args)
	var type_args:Array[String] = line_data.type_args.duplicate()
	var identifier_args:Array[String] = line_data.identifier_args.duplicate()
	var func_args:Array[String] = []
	var index:int = 0
	while len(line_data.identifier_args) > index and len(line_data.type_args) > index:
		index += 1
		type_args.pop_front()
		identifier_args.pop_front()
	type_args.pop_front()
	identifier_args.pop_front()
	remainder_sum += ' '.join(type_args)
	remainder_sum += ' '.join(identifier_args)
	return remainder_sum


static func get_reminder(line_data: MagicMacrosLineData) -> String:
	var arg:String = line_data.macro_arg
	var identifier:String = '[b][function name][/b]' if not line_data.has_identifier else line_data.identifier
	var type:String = '[b][return type][/b]' if not line_data.has_type else line_data.type
	var remainder_sum:String = get_sum_remanders(line_data)
	var remainder:String = '' if not remainder_sum else '[color=#ff1111]'+remainder_sum+'[color=#ffffff]?'

	var func_args:Array[String] = []
	var index:int = 1
	while len(line_data.identifier_args) > index and len(line_data.type_args) > index:
		func_args.append('%s: %s'%[line_data.identifier_args[index],line_data.type_args[index]])
		index += 1
	var filled_args: String = ' '+' '.join(func_args) if func_args else ''

	var empty_arg_name: String =  line_data.identifier_args[index] if len(line_data.identifier_args) > index else '[b][func arg name]?[/b]'
	var empty_arg_type: String =  line_data.type_args[index] if len(line_data.type_args) > index else '[b][func arg type]?[/b]'


	var empty_args: String = ' %s %s'%[empty_arg_name,empty_arg_type] if line_data.has_identifier and line_data.has_type else ''


	var macro_body = '%s %s %s%s%s %s' % [arg, identifier, type, filled_args, empty_args, remainder]
	return ' %s\n[center]═══════[/center]\n%s' % [macro_body, apply_macro(line_data)]


static func is_macro_alias(arg: String) -> bool:
	return arg in ALIASES


static func apply_macro(line_data: MagicMacrosLineData) -> String:

	var func_args:Array[String] = []
	var index:int = 1
	while len(line_data.identifier_args) > index and len(line_data.type_args) > index:
		func_args.append('%s: %s'%[line_data.identifier_args[index],line_data.type_args[index]])
		index += 1

	var s: String = ""
	s += line_data.indent + "func %s(%s) -> %s:\n" % [line_data.identifier, ', '.join(func_args), line_data.type]
	s += line_data.indent + line_data.single_indent + "pass"
	return s
