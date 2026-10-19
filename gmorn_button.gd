@tool
extends BaseButton

## 釦の土台。4つの状態（通常・指乗せ/焦点・押下・押せない）を `modulate` で表し、
## 色は `ProjectSettings` から、決定音は組（group）から取る。

## `preload` で指さない。gmorn_beat を取っていない状態で解析に失敗し、この台本ごと
## 読めなくなる（釦が全部壊れる）。実行時に読み、無ければ拍動しないだけにする。
const BEAT_SCALE_PATH := "res://addons/gmorn_beat/gmorn_beat_scale.gd"

const SETTINGS := preload("gmorn_button_settings.gd")

## `null` なら何も描かない（見えない釦）。
@export var background_style: StyleBox
@export var play_submit_sound := true
## 既定は無効。画面のすべてが揺れると、どれが押せるのか分からなくなる。
@export var beat_scale_enabled := false
## 背景の上に置く透明釦などを、共通のハイライト色は残したまま無反応にする用途。
@export var highlight_tint_enabled := true

static var _beat_scale: GDScript
static var _settings: RefCounted

## 焦点でも色を変えるか。作品側が入力手段で切り替える（手元機・鍵盤なら要るが、
## 起動時に焦点を置く作りだとマウス操作では誰も触っていない釦に色が付く）。
## 指乗せの色はこの切り替えと無関係に出る。
static var focus_tint_enabled := true

var hovered := false
var pressed_state := false
var previous_target_color := Color(-1.0, -1.0, -1.0, -1.0)
var beat_scale: Vector2 = Vector2.ONE

static func _scale_helper() -> GDScript:
	if _beat_scale == null and ResourceLoader.exists(BEAT_SCALE_PATH):
		_beat_scale = load(BEAT_SCALE_PATH) as GDScript
	return _beat_scale

## 設定は1回だけ読む。釦は何十個も並ぶので、釦ごとに読むと置くだけで遅くなる。
static func settings() -> RefCounted:
	if _settings == null:
		_settings = SETTINGS.new()
		_settings.load_from_environment()
	return _settings

## 色を実行中に変えたときに呼ぶ。
static func reload_settings() -> void:
	_settings = null

## 画面のすべての釦に一度に効く。塗り直しは各釦の毎こまの `_update_tint()` が拾う。
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
	var current_scale: Vector2
	if beat_scale is Vector2:
		current_scale = beat_scale
	else:
		current_scale = Vector2.ONE
		beat_scale = current_scale
	beat_scale = helper.lerp_back(current_scale, delta)
	scale = beat_scale

## 拍を配る側（gmorn_beat）から呼ばれる。
func pulse() -> void:
	var helper := _scale_helper()
	if helper == null:
		return
	beat_scale = helper.adjusted_aim(size)
	scale = beat_scale

## 左上を軸にすると、膨らむたびに右下へずれて見える。
func _update_pivot() -> void:
	pivot_offset = size / 2.0

func _update_tint(_immediate: bool) -> void:
	var config := settings()
	var target_color: Color = config.normal_color
	if disabled:
		target_color = config.disabled_highlighted_color \
			if highlight_tint_enabled and (hovered or (has_focus() and focus_tint_enabled)) \
			else config.disabled_color
	elif pressed_state:
		target_color = config.pressed_color
	elif highlight_tint_enabled and (hovered or (has_focus() and focus_tint_enabled)):
		target_color = config.highlighted_color
	# 同じ色なら書かない。毎こま `modulate` へ書くと、そのたびに描き直しが走る。
	if target_color == previous_target_color:
		return
	previous_target_color = target_color
	modulate = target_color

func _set_hovered(value: bool) -> void:
	hovered = value
	_update_tint(false)

func _set_pressed(value: bool) -> void:
	if value and not pressed_state and not disabled and play_submit_sound:
		if not Engine.is_editor_hint() and DisplayServer.get_name() != "headless":
			var player := get_tree().get_first_node_in_group(settings().submit_audio_group) as AudioStreamPlayer
			if player != null:
				var resolver: Variant = player.get_meta("morn_source_volume_resolver", Callable())
				if resolver is Callable and (resolver as Callable).is_valid():
					player.volume_db = (resolver as Callable).call(player.stream)
				player.play()
	pressed_state = value
	_update_tint(false)
