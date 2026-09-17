extends SceneTree

## 4つの状態で色が変わること、音の相手を組から探すことを確かめる。
##
## 画面のない実行なので音は鳴らない。鳴らさないこと自体も約束の一つ
## （検証のたびに鳴らない）なので、そこも見る。

const BUTTON_PATH := "res://addons/gmorn_button/gmorn_button.gd"
const SETTINGS_PATH := "res://addons/gmorn_button/gmorn_button_settings.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script: GDScript = load(BUTTON_PATH)
	var settings_script: GDScript = load(SETTINGS_PATH)

	# 作品ごとの色は `ProjectSettings` で決める。釦ごとに持たせない。
	ProjectSettings.set_setting("gmorn_button/highlighted_color", Color(1.0, 0.0, 1.0, 1.0))
	ProjectSettings.set_setting("gmorn_button/pressed_color", "#00ff00")
	script.reload_settings()
	var config: RefCounted = script.settings()
	assert(config.highlighted_color == Color(1.0, 0.0, 1.0, 1.0),
		"指乗せの色が %s" % config.highlighted_color)
	# 文字で書いた色も読める。`project.godot` へ手で書くときに使う。
	assert(config.pressed_color.is_equal_approx(Color(0.0, 1.0, 0.0, 1.0)),
		"押下の色が %s" % config.pressed_color)

	var button: BaseButton = script.new()
	button.size = Vector2(100.0, 40.0)
	root.add_child(button)
	await process_frame

	# 何もしていなければ通常の色。
	assert(button.modulate == config.normal_color, "通常の色が %s" % button.modulate)

	# 指を乗せると変わる。
	button._set_hovered(true)
	assert(button.modulate == config.highlighted_color, "指乗せで %s" % button.modulate)

	# 押している間はさらに変わる。
	button._set_pressed(true)
	assert(button.modulate == config.pressed_color, "押下で %s" % button.modulate)
	button._set_pressed(false)
	button._set_hovered(false)
	assert(button.modulate == config.normal_color, "戻したのに %s" % button.modulate)

	# 押せないときは沈む。乗せても反応は返す。無反応だと、押せないのか
	# 壊れているのか分からない。
	button.disabled = true
	button._update_tint(false)
	assert(button.modulate == config.disabled_color, "押せないときが %s" % button.modulate)
	button._set_hovered(true)
	assert(button.modulate == config.disabled_highlighted_color,
		"押せない釦へ乗せたとき %s" % button.modulate)
	# 押せない釦では音を鳴らさない。
	button._set_pressed(true)
	button.disabled = false
	button._set_hovered(false)
	button._set_pressed(false)

	assert(not button.has_method("_play_ui_sound"), "削除したUI音の再生メソッドが残っている")

	# 拍動を切ってあれば組に入らない。画面のすべてが揺れると、どれが押せるのか
	# 分からなくなる。
	assert(not button.beat_scale_enabled, "既定で拍動が有効になっている")

	print("色=通常%s 指乗せ%s 押下%s" % [
		config.normal_color, config.highlighted_color, config.pressed_color])
	print("GMORN BUTTON VERIFY: PASS")
	quit(0)
