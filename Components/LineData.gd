class_name MagicMacrosLineData
extends RefCounted
## Analyzes a provided Line to determine its contents and applicable macro.

const DEFAULT_IDENTIFIER: String = "identifier"
const DEFAULT_TYPE: String = "type"
const DEFAULT_REMAINDER: String = "none"
const NON_PASCAL_TYPES: Array[String] = ["void", "bool", "float", "int"]

## ID of the Line within its TextEditor
var line_index: int = -1
## The raw text of the line
var source_text: String = ""

## The output of the macro
var modified_text: String:
	get:
		if not is_valid:
			return source_text
		return detected_macro.call(_plugin.macros_apply_func, self)

## The output of the reminder function
var reminder_text: String:
	get:
		if not is_valid:
			return source_text
		return detected_macro.call(_plugin.macros_reminder_func, self)

## The macro applicable to this line, if any
var detected_macro: Script
## The argument with which the macro is detected.
var macro_arg: String = ""

## All the args detected within the line
var all_args: Array[String] = []

## Identifiers detected within the line
## identifiers are always snake_case, follows GDScript style guide
var identifier_args: Array[String] = []

## true if there is an identifier
var has_identifier: bool:
	get: return not identifier_args.is_empty()

## Convenience helper value for retrieving the first identifier in the line.
var identifier: String:
	get: return identifier_args[0] if has_identifier else DEFAULT_IDENTIFIER

## Types detected within the line
## Types are always PascalCase, follows GDScript style guide
var type_args: Array[String] = []

## true if there is a type section
var has_type: bool:
	get: return not type_args.is_empty()

## Convenience helper value for retrieving the first type in the line.
var type: String:
	get: return type_args[0] if has_type else DEFAULT_TYPE

## Any remaining arguments that are not identifiers or types
var remainder_args: Array[String] = []

## true if there is a remainder section
var has_remainder: bool:
	get: return not remainder_args.is_empty()

## Convenience helper value for retreiving the first remainder value.
var remainder: String:
	get: return remainder_args[0] if has_remainder else DEFAULT_REMAINDER

var is_valid: bool:
	get: return true if detected_macro else false

## Reference to the plugin script
var _plugin: MagicMacros

## Line indentation
var _indent: String = ""

## returns the line's indentation
var indent: String:
	get: return _indent

## internal, string of the system's default indentation
var _system_default_indent:String = '\t' if EditorInterface.get_editor_settings().get_setting('text_editor/behavior/indent/type') == 0 else '    '

## returns a single indentation, trying to match line's indentation type
var s_in:String:
	get: return '\t' if '\t' in _indent else ('    ' if '    ' in _indent else _system_default_indent)


func _init(plugin: MagicMacros, line_id: int, line_text: String) -> void:
	_plugin = plugin
	line_index = line_id
	source_text = line_text

	_parse_line()

## internal function
func _parse_line() -> void:
	# Count only tabs in the beginning of the line
	# and remember line indentation
	_indent = _get_indentation()

	# Replace tabs and spaces in line and get the individual arguments
	var args: PackedStringArray = source_text.replace("    ", "").replace("\t", "").split(" ", false)
	if args.is_empty():
		return

	# The first argument must be a macro argument
	# Eg. 'fn' or 'rdy'
	if _arg_is_macro(args[0]):
		macro_arg = args[0]
		args.remove_at(0)

	var all_arg: Array[String] = []
	var types: Array[String] = []
	var identifiers: Array[String] = []
	var remainders: Array[String] = []

	# Detect and sort arguments by category.
	for arg: String in args:
		all_arg.append(arg)
		if _arg_is_type(arg):
			types.append(arg)
		elif _arg_is_identifier(arg):
			identifiers.append(arg)
		else:
			remainders.append(arg)

	all_args = all_arg
	type_args = types
	identifier_args = identifiers
	remainder_args = remainders

	# Retrieve the macro
	detected_macro = _get_macro_script()

## internal function
func _get_indentation() -> String:
	var i: String = ""

	for c: String in source_text:
		if c in [" ", "\t"]:
			i += c
			continue
		break

	return i

## internal function
func _arg_is_macro(arg: String) -> bool:
	for macro: Script in _plugin.macros:
		# Will return a bool. See MagicMacroMacro for this.
		if macro.call(_plugin.macros_alias_func, arg):
			return true
	return false

## internal function
func _arg_is_type(arg: String) -> bool:
	if arg in NON_PASCAL_TYPES:
		return true

	if _plugin.is_pascal_case(arg):
		return true
	# enum var like Enum.Value
	if '.' not in arg:
		return false
	var split_args:PackedStringArray = arg.rsplit('.',true,1)
	var left_side:String = split_args[0]
	var right_side:String = split_args[-1]
	if not _plugin.is_pascal_case(right_side): # last part should be pascal case
		return false
	for sub_arg in left_side.split('.'): # loop though right side (imagine AutoLoad.some_node.Enum)
		if not (_plugin.is_snake_case(sub_arg) or _plugin.is_pascal_case(sub_arg)):
			return false
	return true


## internal function
func _arg_is_identifier(arg: String) -> bool:
	# standard case 'identifier_here'
	if _plugin.is_snake_case(arg):
		return true
	# class var like Something.variable
	if '.' not in arg:
		return false
	var split_args:PackedStringArray = arg.rsplit('.',true,1)
	var left_side:String = split_args[0]
	var right_side:String = split_args[-1]
	if not _plugin.is_snake_case(right_side): # last part should be snake case
		return false
	for sub_arg in left_side.split('.'): # loop though right side (imagine AutoLoad.some_node.value)
		if not (_plugin.is_snake_case(sub_arg) or _plugin.is_pascal_case(sub_arg)):
			return false
	return true




## internal function
func _get_macro_script() -> Script:
	for macro: Script in _plugin.macros:
		var matches: bool = macro.call(_plugin.macros_alias_func, macro_arg)
		if matches:
			return macro
	return null
