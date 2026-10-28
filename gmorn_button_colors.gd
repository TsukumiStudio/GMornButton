@tool
extends Resource

## 釦の色の組。`.tres` に保存して、釦の `colors` へ割り当てる。
##
## `class_name` は付けない（`gmorn_button_settings.gd` と同じ理由）。使う側は
## `preload` で直に指す。

## 焦点が無く、押せるとき。
@export var normal_color := Color.WHITE
## 焦点がある・指が乗っている・押しているとき。
@export var focused_color := Color.WHITE
## 押せないときに上の2色へ掛ける。置き換えにしないのは、押せない釦でも焦点の
## 有無が見分けられるようにするため（パッドで押せない釦に焦点が来ると、色が
## 変わらなければ焦点を見失う）。
@export var disabled_tint := Color(0.65, 0.65, 0.65, 1.0)

func color_for(highlighted: bool, pressed: bool, is_disabled: bool) -> Color:
	var color := focused_color if highlighted or pressed else normal_color
	return color * disabled_tint if is_disabled else color
