@tool
extends MagicMacrosMacro

const ALIASES: Array[String] = ["macros"]

static func get_reminder(line_data: MagicMacrosLineData) -> String:
    return apply_macro(line_data)


static func is_macro_alias(arg: String) -> bool:
    return arg in ALIASES


static func apply_macro(line_data: MagicMacrosLineData) -> String:
    var macros_list: Array[String] = []
    var files: PackedStringArray = DirAccess.get_files_at(line_data._plugin.MACROS_DIR)
    for file: String in files:
        if file.ends_with(".remap") or file.ends_with(".uid"):
            continue
        if not file.ends_with(".gd"):
            continue
        var file_path: String = line_data._plugin.MACROS_DIR.path_join(file)
        var script: Script = load(file_path)
        if script.has_method(line_data._plugin.macros_alias_func):
            var file_name_split:String = file_path.rsplit('/',true,1)[-1]
            var file_name = file_name_split.split('.',true,1)[0]
            var valid_aliases = 'unknown'
            if 'ALIASES' in script:
                if is_instance_of(script.ALIASES, TYPE_ARRAY):
                    valid_aliases = '|'.join(script.ALIASES)
            macros_list.append('%s : %s' % [file_name, valid_aliases])
    return '\n'.join(macros_list)
