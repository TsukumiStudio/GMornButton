extends RefCounted

## GMornButton の設定。
##
## `class_name` は付けない。付けるとエディタが一度走査するまで名前を引けず、
## 取り込んだ直後にヘッドレスで走らせると読み込みごと失敗する。使う側は
## `preload` で直に指す。
##
## 色は釦ごとではなく作品ごとに決める。釦ごとに持たせると、後から色を変える
## ときに置いてある釦を全部開いて直すことになる。

## 何もしていないときの色。
var normal_color := Color.WHITE
## 指を乗せている、または焦点が当たっているときの色。
##
## 既定は少し暗くするだけにしてある。作品の色は `ProjectSettings` で決める。
var highlighted_color := Color(0.8, 0.8, 0.8, 1.0)
## 押している間の色。
var pressed_color := Color(0.65, 0.65, 0.65, 1.0)
## 押せないときの色。
var disabled_color := Color(0.65, 0.65, 0.65, 1.0)
## 押せない釦に指を乗せたときの色。
##
## 押せないことを伝えるために、乗せたときも反応は返す。無反応だと、
## 押せないのか壊れているのか分からない。
var disabled_highlighted_color := Color(0.5, 0.5, 0.5, 1.0)
## 押したときに鳴らす `AudioStreamPlayer` が入っている組の名前。
var submit_audio_group := &"morn_ui_submit_audio"

const SETTING_PREFIX := "gmorn_button/"

## 設定を読み込む。自分自身へ書き込むので、作ってから呼ぶ。
func load_from_environment() -> void:
	normal_color = _color("normal_color", normal_color)
	highlighted_color = _color("highlighted_color", highlighted_color)
	pressed_color = _color("pressed_color", pressed_color)
	disabled_color = _color("disabled_color", disabled_color)
	disabled_highlighted_color = _color("disabled_highlighted_color", disabled_highlighted_color)
	submit_audio_group = StringName(_setting("submit_audio_group", submit_audio_group))

## 色は `Color` でも `"#ff00ff"` のような文字でも受ける。`project.godot` へ
## 手で書くときは文字のほうが書きやすい。
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
