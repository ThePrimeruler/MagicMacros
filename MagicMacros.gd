@tool
class_name MagicMacros
extends EditorPlugin
## MagicMacros - Godot Addon for enhanced autocomplete and code snippets
##
## This addon integrates with the Script Editor in Godot.
## It will scan the currently edited line for a pattern that fits one of the loaded macros, and when it finds a match highlight the line in green.
## Pressing tab will execute the macro on the contents of the line.

## dir where macros are pulled from
const MACROS_DIR: String = "res://addons/MagicMacros/Macros/"
## if true, a reminder popup will apear when autocompleting
const USE_REMINDER: bool = true

## the color contant for line color changing
const THEME_COLOR_CONSTANT: String = "current_line_color"
## Color with which to highlight a valid macro with
const THEME_COLOR_VALID: Color = Color(0.0, 1.0, 0.0, 0.15)
## regex patterns used for argument detection. See LineData
const PASCAL_CASE_REGEX_PATTERN: String = '^[A-Z][a-zA-Z0-9]*$'
## regex patterns used for argument detection. See LineData
const SNAKE_CASE_REGEX_PATTERN: String = '^[a-z_][a-z0-9_]*$'

## regex used for argument detection. See LineData
var pascal_case_regex: RegEx
## regex used for argument detection. See LineData
var snake_case_regex: RegEx

# This is a bit silly. But since the list of macros is dynamic and not constant
# This is the only "reasonable" way of reliably getting the method name to call() in LineData
## internal
var macros_alias_func: String = MagicMacrosMacro.is_macro_alias.get_method()
## internal
var macros_apply_func: String = MagicMacrosMacro.apply_macro.get_method()
## internal
var macros_reminder_func: String = MagicMacrosMacro.get_reminder.get_method()

## List of Macro Script resources found in [constant MagicMacros.MACROS_DIR]
## Macros are not instanced, but statically called
var macros: Array[Script] = []



## internal: see [MagicMacrosInputCatcher]
var _input_catcher: MagicMacrosInputCatcher

## internal: popup field for reminding the user of the macro
var _reminder_label: RichTextLabel

## While the ScriptEditor is always present, it will instance one CodeEditor per open script
## This mess is part of making sure that we only interact with the currently visible script editor
var _current_editor: ScriptEditorBase:
	set(value):
		if value == _current_editor:
			return

		var base: TextEdit

		if is_instance_valid(_current_editor):
			base = _current_editor.get_base_editor()
			if base:
				base.text_changed.disconnect(_on_text_changed)
				base.caret_changed.disconnect(_on_caret_changed)

		_current_editor = value

		if _current_editor:
			base = _current_editor.get_base_editor()
			if base:
				base.text_changed.connect(_on_text_changed)
				base.caret_changed.connect(_on_caret_changed)

## LineData for the currently highlight line in the CodeEditor
var _current_line_data: MagicMacrosLineData:
	set(value):
		_current_line_data = value
		_update_line_color()
		_update_reminder_label()

func _ready() -> void:
	# HACK: Fixes macros not loading? Unconfirmed
	await get_tree().process_frame

	_load_macros()

	EditorInterface.get_script_editor().editor_script_changed.connect(_on_script_changed)

	_input_catcher = MagicMacrosInputCatcher.new()
	_input_catcher.tab_pressed.connect(_on_tab_pressed)

	_current_editor = EditorInterface.get_script_editor().get_current_editor()

	pascal_case_regex = RegEx.new()
	pascal_case_regex.compile(PASCAL_CASE_REGEX_PATTERN)
	snake_case_regex = RegEx.new()
	snake_case_regex.compile(SNAKE_CASE_REGEX_PATTERN)

	print("MagicMacros: %s macros enabled" % macros.size())



func _exit_tree() -> void:
	if _current_editor:
		var base: TextEdit = _current_editor.get_base_editor()
		base.remove_theme_color_override(THEME_COLOR_CONSTANT)

	if _input_catcher:
		_input_catcher.queue_free()

	if _reminder_label:
		_reminder_label.queue_free()

	print("MagicMacros: Disabled")


# TODO: Consider making this path configurable. But it's probably not worth the trouble.
## internal, loads macros from [constant MagicMacros.MACROS_DIR]
func _load_macros() -> void:
	var files: PackedStringArray = DirAccess.get_files_at(MACROS_DIR)
	for file: String in files:

		if file.ends_with(".remap") or file.ends_with(".uid"):
			continue
		if not file.ends_with(".gd"):
			continue

		var file_path: String = MACROS_DIR.path_join(file)
		var script: Script = load(file_path)
		if script.has_method(macros_alias_func):
			macros.append(script)


## internal, when the currently edited script changes.
func _on_script_changed(_script: Script) -> void:
	_current_editor = EditorInterface.get_script_editor().get_current_editor()
	_get_line_data()

## internal
func _on_text_changed() -> void:
	_get_line_data()

## internal
func _on_caret_changed() -> void:
	_get_line_data()

## internal
func _get_line_data() -> void:
	_current_line_data = null

	var base: TextEdit = _current_editor.get_base_editor()
	if not base:
		return
	var line_id: int = base.get_caret_line()
	var line_text: String = base.get_line(line_id)

	_current_line_data = MagicMacrosLineData.new(self, line_id, line_text)

## internal, updates the line color of the macro line
func _update_line_color() -> void:
	if not is_instance_valid(_current_editor):
		return

	var base: TextEdit = _current_editor.get_base_editor()
	if not base:
		return
	if not _current_line_data:
		return

	if _current_line_data.is_valid:
		base.add_theme_color_override(THEME_COLOR_CONSTANT, THEME_COLOR_VALID)

	else:
		base.remove_theme_color_override(THEME_COLOR_CONSTANT)

## internal, updates the reminder label if [constant MagicMacros.USE_REMINDER] is true
func _update_reminder_label() -> void:
	if not USE_REMINDER:
		return
	if not is_instance_valid(_current_editor):
		return
	var base: TextEdit = _current_editor.get_base_editor()
	if not base:
		return
	if not _current_line_data:
		return
	if _current_line_data.is_valid:

		# remove old _reminder_label if it exists
		if _reminder_label:
			_reminder_label.queue_free()
		var reminder_text:String = _current_line_data.reminder_text
		if not reminder_text:
			return
		# create a new one -> have to do this because _current_editor.get_base_editor() changes when you change tabs
		_reminder_label = RichTextLabel.new()
		_reminder_label.bbcode_enabled = true
		_reminder_label.text = _current_line_data.reminder_text
		_reminder_label.fit_content = true
		_reminder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_reminder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_reminder_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_reminder_label.z_index = 200
		_reminder_label.custom_minimum_size = Vector2(100,20)
		_reminder_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		base.add_child(_reminder_label)
		_reminder_label.set_position(base.get_caret_draw_pos() + Vector2(-20,-(_reminder_label.size.y+20)))
		if base.is_connected("gui_input", _on_editor_scroll):
			base.disconnect("gui_input", _on_editor_scroll)
		base.connect("gui_input", _on_editor_scroll)
	else:
		if _reminder_label:
			_reminder_label.queue_free()

## internal, removes the reminder label when you scroll
func _on_editor_scroll(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _reminder_label:
				_reminder_label.queue_free()
			var base: TextEdit = _current_editor.get_base_editor()
			base.disconnect("gui_input", _on_editor_scroll)

## internal, function called to activate macro
func _on_tab_pressed() -> void:
	var base: CodeEdit = _current_editor.get_base_editor()
	if not base:
		return
	if not base.is_visible_in_tree() and base.has_focus():
		return
	if not _current_line_data:
		return
	if not _current_line_data.is_valid:
		return

	_current_editor.get_viewport().set_input_as_handled()
	base.cancel_code_completion()

	base.set_line(_current_line_data.line_index, _current_line_data.modified_text)
	base.set_caret_column(0)
	base.set_caret_line(_current_line_data.line_index)

	base.cancel_code_completion()

## internal, used for argument detection. See LineData
func is_pascal_case(string: String) -> bool:
	return true if pascal_case_regex.search(string) else false

## internal, used for argument detection. See LineData
func is_snake_case(string: String) -> bool:
	return true if snake_case_regex.search(string) else false
