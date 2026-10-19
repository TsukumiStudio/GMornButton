extends RefCounted

## `class_name` は付けない。エディタが一度走査するまで名前を引けず、取り込んだ
## 直後のヘッドレス実行で読み込みごと失敗する。使う側は `preload` で直に指す。
##
## 色は釦ごとに持たせない。後から色を変えるときに釦を全部開いて直すことになる。

var normal_color := Color.WHITE
var highlighted_color := Color(0.8, 0.8, 0.8, 1.0)
var pressed_color := Color(0.65, 0.65, 0.65, 1.0)
var disabled_color := Color(0.65, 0.65, 0.65, 1.0)
## 押せない釦でも乗せたときに反応を返す。無反応だと押せないのか壊れているのか分からない。
var disabled_highlighted_color := Color(0.5, 0.5, 0.5, 1.0)
## 決定音の `AudioStreamPlayer` が入っている組。
var submit_audio_group := &"morn_ui_submit_audio"

const SETTING_PREFIX := "gmorn_button/"

func load_from_environment() -> void:
	normal_color = _color("normal_color", normal_color)
	highlighted_color = _color("highlighted_color", highlighted_color)
	pressed_color = _color("pressed_color", pressed_color)
	disabled_color = _color("disabled_color", disabled_color)
	disabled_highlighted_color = _color("disabled_highlighted_color", disabled_highlighted_color)
	submit_audio_group = StringName(_setting("submit_audio_group", submit_audio_group))

## `"#ff00ff"` のような文字も受ける。`project.godot` へ手で書くときに要る。
static func _color(key: String, fallback_value: Color) -> Color:
	var value: Variant = _setting(key, fallback_value)
	if value is Color:
		return value as Color
	if value is String and Color.html_is_valid(value as String):
		return Color.html(value as String)
	return fallback_value

static func _setting(key: String, fallback_value: Variant) -> Variant:
	var path := SETTING_PREFIX + key
	if not ProjectSettings.has_setting(path):
		return fallback_value
	return ProjectSettings.get_setting(path, fallback_value)
