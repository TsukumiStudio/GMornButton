@tool
extends EditorPlugin

## 自動読み込みには登録しない。釦は場面ごとに置くものなので「ノードを追加」に出す。

const TYPE_NAME := "GMornButton"

func _script_path() -> String:
	return get_script().resource_path.get_base_dir().path_join("gmorn_button.gd")

func _enter_tree() -> void:
	_register_settings()
	add_custom_type(TYPE_NAME, "BaseButton", load(_script_path()), null)

func _exit_tree() -> void:
	remove_custom_type(TYPE_NAME)

## 既定値を登録しないと「プロジェクト設定」で全項目に戻す印が付き、どれを変えたか
## 分からない。値は読む側の既定値と同じにする。読む側はこの登録が無くても動く。
func _register_settings() -> void:
	for row in [
		["normal_color", Color.WHITE, TYPE_COLOR, PROPERTY_HINT_NONE, ""],
		["highlighted_color", Color(0.8, 0.8, 0.8, 1.0), TYPE_COLOR, PROPERTY_HINT_NONE, ""],
		["pressed_color", Color(0.65, 0.65, 0.65, 1.0), TYPE_COLOR, PROPERTY_HINT_NONE, ""],
		["disabled_color", Color(0.65, 0.65, 0.65, 1.0), TYPE_COLOR, PROPERTY_HINT_NONE, ""],
		["disabled_highlighted_color", Color(0.5, 0.5, 0.5, 1.0), TYPE_COLOR, PROPERTY_HINT_NONE, ""],
		["submit_audio_group", "morn_ui_submit_audio", TYPE_STRING, PROPERTY_HINT_NONE, ""],
	]:
		var key: String = "gmorn_button/" + String(row[0])
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, row[1])
		ProjectSettings.set_initial_value(key, row[1])
		ProjectSettings.add_property_info({
			"name": key, "type": row[2], "hint": row[3], "hint_string": row[4],
		})
		ProjectSettings.set_as_basic(key, true)
