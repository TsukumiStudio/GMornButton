@tool
extends BaseButton

## 押せる場所すべての土台になる釦。
##
## 釦に要るものは、どの作品でもだいたい同じである。指を乗せたら色が変わる、
## 押したら音が鳴る、押せないときは沈む。これを釦ごとに書くと、必ずどこか
## 一つだけ抜ける。抜けた場所は「なんとなく反応が薄い」としか気付けない。
##
## ここでは4つの状態（通常・指乗せ/焦点・押下・押せない）を `modulate` の色で
## 表す。色は `ProjectSettings` から取るので、作品ごとに1か所で決められる。
##
## 音は木の中の組（group）から探す。鳴らす側を指し示さないので、音を持たない
## 場面でもそのまま置ける。
##
## 拍動は `addons/gmorn_beat` があれば効く。無ければ拍動しないだけで、釦としては
## 動く。`preload` で指さないのはそのためである（下の注記を参照）。
##
## 使い方は README.md を参照。

## 拍動の計算は `addons/gmorn_beat`（別の部品）にある。
##
## `preload` で指すと、その部品を取っていない状態では解析に失敗し、この台本ごと
## 読めなくなる。釦は画面のどこにでもあるので、そうなると何も押せない。実際に、
## 書き出しの手順が submodule を取っておらず、配ったものだけ釦が軒並み壊れていた。
##
## 実行時に読む。無ければ拍動しないだけで、釦としては動く。
const BEAT_SCALE_PATH := "res://addons/gmorn_beat/gmorn_beat_scale.gd"

const SETTINGS := preload("gmorn_button_settings.gd")

## 背景の描き方。`null` なら何も描かない（見えない釦になる）。
@export var background_style: StyleBox
## 指を乗せたときに音を鳴らすか。
@export var play_cursor_sound := true
## 押したときに音を鳴らすか。
@export var play_submit_sound := true
## 拍で拍動するか。
##
## 既定は無効。画面のすべてが揺れると、どれが押せるのか分からなくなる。
## 揺らしたい釦にだけ付ける。
@export var beat_scale_enabled := false

static var _beat_scale: GDScript
static var _settings: RefCounted

## 焦点（`has_focus()`）でも色を変えるか。**作品ごとに切りたい。**
##
## 焦点の色は、手元機や鍵盤で選んでいる人には要る（どこを選んでいるか分からないと
## 押せない）。一方で、起動した時点で最初の釦へ焦点を置く作りだと、**誰も触って
## いないのに1つだけ色が付いている**画面になる。マウスで遊ぶ人には、押してもいない
## 釦が選ばれているように見える。
##
## そこで、出すかどうかを外から切れるようにする。既定は出す（今までどおり）。
## 切り替えるのは作品の側で、たとえば「最後に触ったのが手元機か鍵盤なら出す、
## マウスなら出さない」と決められる。指を乗せたときの色は、この切り替えとは
## 無関係に出る。
static var focus_tint_enabled := true

var hovered := false
var pressed_state := false
var previous_target_color := Color(-1.0, -1.0, -1.0, -1.0)
var beat_scale := Vector2.ONE

static func _scale_helper() -> GDScript:
	if _beat_scale == null and ResourceLoader.exists(BEAT_SCALE_PATH):
		_beat_scale = load(BEAT_SCALE_PATH) as GDScript
	return _beat_scale

## 設定は釦ごとではなく1回だけ読む。釦は画面に何十個も並ぶので、
## そのたびに読むと置くだけで遅くなる。
static func settings() -> RefCounted:
	if _settings == null:
		_settings = SETTINGS.new()
		_settings.load_from_environment()
	return _settings

## 設定を読み直させる。色を実行中に変えたときに使う。
static func reload_settings() -> void:
	_settings = null

## 焦点の色を出すかどうかを切り替える。**画面のすべての釦に一度に効く。**
##
## 塗り直しは各釦の毎こまの更新（`_update_tint()`）が拾うので、ここでは値を
## 置くだけでよい。
static func set_focus_tint_enabled(value: bool) -> void:
	focus_tint_enabled = value

func _ready() -> void:
	var helper := _scale_helper()
	if beat_scale_enabled and helper != null:
		add_to_group(helper.GROUP)
		_update_pivot()
		resized.connect(_update_pivot)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	button_down.connect(_set_pressed.bind(true))
	button_up.connect(_set_pressed.bind(false))
	# 焦点でも色を変える。鍵盤や手元機で選んでいるとき、指を乗せていなくても
	# どこを選んでいるか分からないと押せない。
	focus_entered.connect(_update_tint.bind(false))
	focus_exited.connect(_update_tint.bind(false))
	_update_tint(true)
	queue_redraw()

func _draw() -> void:
	if background_style != null:
		draw_style_box(background_style, Rect2(Vector2.ZERO, size))

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _process(delta: float) -> void:
	_update_tint(false)
	if beat_scale.is_equal_approx(Vector2.ONE):
		return
	var helper := _scale_helper()
	if helper == null:
		return
	beat_scale = helper.lerp_back(beat_scale, delta)
	scale = beat_scale

## 1拍ぶん拍動する。拍を配る側から呼ばれる。
func pulse() -> void:
	var helper := _scale_helper()
	if helper == null:
		return
	beat_scale = helper.adjusted_aim(size)
	scale = beat_scale

## 拍動は中心から膨らませる。左上を軸にすると、膨らむたびに右下へずれて見える。
func _update_pivot() -> void:
	pivot_offset = size / 2.0

func _update_tint(_immediate: bool) -> void:
	var config := settings()
	var target_color: Color = config.normal_color
	if disabled:
		target_color = config.disabled_highlighted_color \
			if hovered or (has_focus() and focus_tint_enabled) \
			else config.disabled_color
	elif pressed_state:
		target_color = config.pressed_color
	elif hovered or (has_focus() and focus_tint_enabled):
		target_color = config.highlighted_color
	# 同じ色なら触らない。毎こま `modulate` へ書くと、そのたびに描き直しが走る。
	if target_color == previous_target_color:
		return
	previous_target_color = target_color
	modulate = target_color

func _set_hovered(value: bool) -> void:
	# 乗った瞬間だけ鳴らす。乗っている間ずっと鳴らすと耳障りになる。
	if value and not hovered and not disabled and play_cursor_sound:
		_play_ui_sound(settings().cursor_audio_group)
	hovered = value
	_update_tint(false)

func _set_pressed(value: bool) -> void:
	if value and not pressed_state and not disabled and play_submit_sound:
		_play_ui_sound(settings().submit_audio_group)
	pressed_state = value
	_update_tint(false)

## 鳴らす相手は組から探す。指し示す形にすると、釦を置くたびに繋ぎ直しが要る。
## 相手が居ない場面（音を持たない画面）でもそのまま置ける。
func _play_ui_sound(group_name: StringName) -> void:
	if Engine.is_editor_hint() or DisplayServer.get_name() == "headless":
		return
	var player := get_tree().get_first_node_in_group(group_name) as AudioStreamPlayer
	if player != null:
		player.play()
