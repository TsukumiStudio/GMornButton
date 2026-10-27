extends RefCounted

## `class_name` は付けない。エディタが一度走査するまで名前を引けず、取り込んだ
## 直後のヘッドレス実行で読み込みごと失敗する。使う側は `preload` で直に指す。
##
## 色は釦ごとに書かせず、色の組（`gmorn_button_colors.gd` の `.tres`）を指させる。
## 釦ごとに書くと、後から色を変えるときに釦を全部開いて直すことになる。

const COLORS := preload("gmorn_button_colors.gd")

## `colors` を指していない釦が使う組。`gmorn_button/default_colors` に `.tres` の道を書く。
var default_colors: Resource

var normal_color := Color.WHITE
var highlighted_color := Color(0.8, 0.8, 0.8, 1.0)
var pressed_color := Color(0.65, 0.65, 0.65, 1.0)
var disabled_color := Color(0.65, 0.65, 0.65, 1.0)
## 押せない釦でも乗せたときに反応を返す。無反応だと押せないのか壊れているのか分からない。
var disabled_highlighted_color := Color(0.5, 0.5, 0.5, 1.0)
# 上の5色は `default_colors` が無い作品向けに残している。組へ移すと色が変わる作品がある
# （押下・押せない＋指乗せを、指乗せの色から導けない値で決めているもの）。
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
	default_colors = _colors_resource(String(_setting("default_colors", "")))

## 道を書き損じたまま黙って5色へ戻ると、組を直しても色が変わらない理由が分からない。
static func _colors_resource(path: String) -> Resource:
	if path.is_empty():
		return null
	var resource: Resource = load(path) if ResourceLoader.exists(path) else null
	if resource is COLORS:
		return resource
	push_warning("gmorn_button/default_colors が色の組を指していない: %s" % path)
	return null

## 組と同じ口。`default_colors` が無いときに釦はこちらへ尋ねる。
func color_for(highlighted: bool, pressed: bool, is_disabled: bool) -> Color:
	if is_disabled:
		return disabled_highlighted_color if highlighted else disabled_color
	if pressed:
		return pressed_color
	return highlighted_color if highlighted else normal_color

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
