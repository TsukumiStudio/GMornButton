extends SceneTree

## 4つの状態で色が変わること、色を色の組（釦ごと → 作品の既定 → `ProjectSettings` の5色）
## から取ることを保証する。

const BUTTON_PATH := "res://addons/gmorn_button/gmorn_button.gd"
const SETTINGS_PATH := "res://addons/gmorn_button/gmorn_button_settings.gd"
const COLORS_PATH := "res://addons/gmorn_button/gmorn_button_colors.gd"
const DEFAULT_COLORS_PATH := "user://verify_default_colors.tres"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script: GDScript = load(BUTTON_PATH)
	var colors_script: GDScript = load(COLORS_PATH)

	# 色は `ProjectSettings` から読む。
	ProjectSettings.set_setting("gmorn_button/highlighted_color", Color(1.0, 0.0, 1.0, 1.0))
	ProjectSettings.set_setting("gmorn_button/pressed_color", "#00ff00")
	script.reload_settings()
	var config: RefCounted = script.settings()
	assert(config.highlighted_color == Color(1.0, 0.0, 1.0, 1.0),
		"指乗せの色が %s" % config.highlighted_color)
	# 文字で書いた色も読める。
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

	# 押せないときは沈み、乗せても反応は返す。
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

	# 釦に組を指せば、その組の色になる。押下は焦点と同じ色。
	var preset: Resource = colors_script.new()
	preset.normal_color = Color(0.9, 0.9, 1.0, 1.0)
	preset.focused_color = Color(1.0, 0.2, 0.8, 1.0)
	preset.disabled_tint = Color(0.5, 0.5, 0.5, 1.0)
	button.colors = preset
	button._update_tint(false)
	assert(button.modulate == preset.normal_color, "組の通常の色が出ない: %s" % button.modulate)
	button._set_hovered(true)
	assert(button.modulate == preset.focused_color, "組の焦点の色が出ない: %s" % button.modulate)
	button._set_hovered(false)
	button._set_pressed(true)
	assert(button.modulate == preset.focused_color, "組の押下が焦点の色にならない: %s" % button.modulate)
	button._set_pressed(false)
	# 押せないときは差分を掛ける。焦点の有無は押せなくても見分けられる。
	button.disabled = true
	button._update_tint(false)
	var dim: Color = button.modulate
	assert(dim == preset.normal_color * preset.disabled_tint, "押せない色が通常×差分でない: %s" % dim)
	button._set_hovered(true)
	var dim_focus: Color = button.modulate
	assert(dim_focus == preset.focused_color * preset.disabled_tint,
		"押せない＋焦点が焦点×差分でない: %s" % dim_focus)
	assert(dim != dim_focus, "押せない釦で焦点の有無が見分けられない")
	button._set_hovered(false)
	button.disabled = false

	# 組でないものを指したときは既定の色へ戻る（壊れて真っ黒などにならない）。
	button.colors = Resource.new()
	button._update_tint(false)
	assert(button.modulate == config.normal_color, "組でないものを指して色が崩れた: %s" % button.modulate)

	# `colors` が `null` の釦は作品の既定の組を使う。
	var defaults: Resource = colors_script.new()
	defaults.focused_color = Color(0.0, 0.5, 1.0, 1.0)
	assert(ResourceSaver.save(defaults, DEFAULT_COLORS_PATH) == OK, "既定の組を保存できない")
	ProjectSettings.set_setting("gmorn_button/default_colors", DEFAULT_COLORS_PATH)
	script.reload_settings()
	button.colors = null
	button._set_hovered(true)
	assert(button.modulate == defaults.focused_color, "既定の組が効かない: %s" % button.modulate)
	button._set_hovered(false)
	# 釦でない部品も同じ口から同じ色を引ける。
	assert(script.tint_color(null, true, false, true) == defaults.focused_color * defaults.disabled_tint,
		"tint_color が既定の組を使わない")
	assert(script.tint_color(preset, false, false, false) == preset.normal_color,
		"tint_color が指した組を使わない")
	ProjectSettings.set_setting("gmorn_button/default_colors", "")
	script.reload_settings()

	# 拍動は既定で無効。
	assert(not button.beat_scale_enabled, "既定で拍動が有効になっている")

	print("色=通常%s 指乗せ%s 押下%s" % [
		config.normal_color, config.highlighted_color, config.pressed_color])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DEFAULT_COLORS_PATH))
	print("GMORN BUTTON VERIFY: PASS")
	quit(0)
